// Slowpoke Bitcoin Miner for CPU Mining
// (c) Kristian Klomsten Skordal 2014 <kristian.skordal@wafflemail.net>

#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>

#include <sys/socket.h>
#include <sys/types.h>

#include <jansson.h>
#include <pthread.h>

#include "stratum.h"
#include "utils.h"

char * extranonce1;
int extranonce2_length;
int difficulty;

static int server_socket;
static bool control_thread_running = true;
static char * worker_name;
static int next_id = 3;

static pthread_t control_thread;
static pthread_mutex_t submission_mutex = PTHREAD_MUTEX_INITIALIZER;

static bool stratum_subscribe(void);
static bool stratum_authenticate(const char * username, const char * password);
static void stratum_disconnect(void);

static void * control_thread_function(void * arg);

bool stratum_connect(const char * host, const char * port, const char * username, const char * password)
{
	int status;
	bool retval = true;
	struct addrinfo address_hints;
	struct addrinfo * server_address = NULL;

	memset(&address_hints, 0, sizeof(struct addrinfo));
	address_hints.ai_family = AF_UNSPEC;
	address_hints.ai_socktype = SOCK_STREAM;

	printf("[INFO] Resolving %s... ", host);
	status = getaddrinfo(host, port, &address_hints, &server_address);
	if(status != 0)
	{
		fprintf(stderr, "[ERROR] Could not resolve address for host %s:%s: %s\n", host, port,
			gai_strerror(status));
		retval = false;
		goto _return;
	}

	char * address[INET6_ADDRSTRLEN];
	memset(address, 0, INET6_ADDRSTRLEN);

	// Just grab the first address from the list of possible addresses:
	if(server_address->ai_family == AF_INET)
	{
		struct sockaddr_in * address_info = (struct sockaddr_in *) server_address->ai_addr;
		char address[INET_ADDRSTRLEN];

		inet_ntop(server_address->ai_family, &address_info->sin_addr, address, INET_ADDRSTRLEN);
		printf("%s\n", address);
	} else { // In case the DNS record lists the IPv6 address first:
		struct sockaddr_in6 * address_info = (struct sockaddr_in6 *) server_address->ai_addr;
		char address[INET6_ADDRSTRLEN];

		inet_ntop(server_address->ai_family, &address_info->sin6_addr, address, INET6_ADDRSTRLEN);
		printf("%s\n", address);
	}

	printf("[INFO] Connecting to server... ");
	server_socket = socket(server_address->ai_family, server_address->ai_socktype,
		server_address->ai_protocol);
	if(server_socket == -1)
	{
		int error = errno;
		fprintf(stderr, "[ERROR] Could not create socket: %s\n", strerror(error));
		retval = false;
		goto _return;
	}

	if(connect(server_socket, server_address->ai_addr, server_address->ai_addrlen) == -1)
	{
		int error = errno;
		fprintf(stderr, "[ERROR] Could not connect to host: %s\n", strerror(error));
		retval = false;
		goto _return;
	}
	printf("ok\n");

	if(pthread_create(&control_thread, NULL, control_thread_function, NULL) != 0)
	{
		fprintf(stderr, "[ERROR] Could not start control thread!\n");
		retval = false;
		goto _return;
	}
	usleep(100);

	worker_name = strdup(username);

	atexit(stratum_disconnect);

	if(!stratum_subscribe())
	{
		retval = false;
		goto _return;
	}

	if(!stratum_authenticate(username, password))
	{
		retval = false;
		goto _return;
	}

_return:
	if(server_address != NULL)
		freeaddrinfo(server_address);
	return retval;
}

void stratum_run(void)
{
	pthread_join(control_thread, NULL);
}

void stratum_submit(const char * job_id, const char * extranonce2, const char * ntime, const char * nonce)
{
	json_t * root = json_object();
	json_t * params = json_array();

	json_object_set_new(root, "id", json_integer(next_id++));
	json_object_set_new(root, "method", json_string("mining.subscribe"));

	json_array_append(params, json_string(worker_name));
	json_array_append(params, json_string(job_id));
	json_array_append(params, json_string(extranonce2));
	json_array_append(params, json_string(ntime));
	json_array_append(params, json_string(nonce));

	json_object_set_new(root, "params", params);

	char * raw_message = json_dumps(root, 0);
	printf("%s\n", raw_message);

	char * message = malloc(strlen(raw_message) + 2);
	sprintf(message, "%s\n", raw_message);
	free(raw_message);

	pthread_mutex_lock(&submission_mutex); // Not sure if these are neccessary, remove later
	printf("[INFO] Sending mining.submit... ");
	if(send(server_socket, message, strlen(message), 0) == -1)
	{
		int error = errno;
		fprintf(stderr, "[ERROR] Could not send mining.submit message to server: %s\n",
			strerror(error));
		goto _return;
	}
	printf("ok\n");
	pthread_mutex_unlock(&submission_mutex);

_return:
	free(message);
	json_decref(root);
}

static bool stratum_subscribe(void)
{
	bool retval = true;
	json_t * root = json_object();

	json_object_set_new(root, "id", json_integer(1));
	json_object_set_new(root, "method", json_string("mining.subscribe"));
	json_object_set_new(root, "params", json_array());

	char * raw_message = json_dumps(root, 0);
	char * message = malloc(strlen(raw_message) + 3);
	sprintf(message, "%s\n", raw_message);
	free(raw_message);

	printf("[INFO] Sending mining.subscribe... ");
	if(send(server_socket, message, strlen(message), 0) == -1)
	{
		int error = errno;
		fprintf(stderr, "[ERROR] Could not send mining.subscribe message to server: %s\n",
			strerror(error));
		retval = false;
		goto _return;
	}
	printf("ok\n");

_return:
	free(message);
	json_decref(root);
	return retval;
}

static bool stratum_authenticate(const char * username, const char * password)
{
	bool retval = true;
	json_t * root = json_object();

	json_t * auth_array = json_array();
	json_array_append_new(auth_array, json_string(username));
	json_array_append_new(auth_array, json_string(password));

	json_object_set_new(root, "id", json_integer(2));
	json_object_set_new(root, "method", json_string("mining.authorize"));
	json_object_set_new(root, "params", auth_array);

	char * raw_message = json_dumps(root, 0);
	char * message = malloc(strlen(raw_message) + 2);
	sprintf(message, "%s\n", raw_message);
	free(raw_message);

	printf("[INFO] Sending mining.authorize... ");
	if(send(server_socket, message, strlen(message), 0) == -1)
	{
		int error = errno;
		fprintf(stderr, "[ERROR] Could not send mining.authorize message to server: %s\n",
			strerror(error));
		retval = false;
		goto _return;
	}
	printf("ok\n");

_return:
	free(message);
	json_decref(root);
	return retval;
}

static void stratum_disconnect(void)
{
	int control_thread_retval = 0;

	// Stop the control thread:
	printf("[INFO] Stopping control thread... ");
	control_thread_running = false;
	pthread_cancel(control_thread);
	pthread_join(control_thread, (void **) &control_thread_retval);
	printf("ok\n");

	// Close the connection:
	shutdown(server_socket, SHUT_RDWR);
	close(server_socket);

	// Free resources:
	if(extranonce1 != NULL)
		free(extranonce1);
	if(worker_name != NULL)
		free(worker_name);
}

static void * control_thread_function(void * arg)
{
	void * retval = 0;

	printf("[INFO] Control thread started\n");

	int buffer_offset = 0;
	char * buffer = malloc(4096);
	buffer[4095] = 0;

	pthread_cleanup_push(free, buffer);

	while(control_thread_running)
	{
		printf("[INFO] Waiting for new commands from the server\n");
		ssize_t length = recv(server_socket, buffer + buffer_offset, 4095 - buffer_offset, 0);
		buffer[length] = 0;

		// If the message does not have a newline, receive more data:
		if(buffer[strlen(buffer) - 1] != '\n')
		{
			buffer_offset = strlen(buffer) - 1;
			continue;
		}

		// The server may send a bunch of messages in one go, so
		// separate them by their newlines:
		char * message = strtok(buffer, "\n");
		do {
			json_error_t error;
			json_t * root = json_loads(message, 0, &error);

			if(root == NULL)
			{
				fprintf(stderr, "[WARNING] Disregarding message from the server due to JSON parser error\n");
				fprintf(stderr, "[WARNING] The failed message was: %s\n", message);
			} else {
				json_t * message_id_object = json_object_get(root, "id");
				if(json_integer_value(message_id_object) == 1) // mining.subscribe
				{
					json_t * result_object = json_object_get(root, "result");

					json_t * extranonce1_object = json_array_get(result_object, 1);
					extranonce1 = strdup(json_string_value(extranonce1_object));
					printf("[INFO] Received extranonce1 value: %s\n", extranonce1);

					json_t * extranonce2_length_object = json_array_get(result_object, 2);
					extranonce2_length = json_integer_value(extranonce2_length_object);
					printf("[INFO] Length of extranonce2 set to %d\n", extranonce2_length);

					if(extranonce2_length != 4)
					{
						fprintf(stderr, "[ERROR] Extranonce2 lengths not equal to 4 is not supported!\n");
						control_thread_running = false;
						retval = (void *) 1;
						break;
					}
				} else if(json_integer_value(message_id_object) == 2) // mining.authorize
				{
					json_t * result_object = json_object_get(root, "result");
					if(json_typeof(result_object) == JSON_FALSE)
					{
						fprintf(stderr, "[ERROR] Wrong username or password specified!\n");
						control_thread_running = false;
						retval = (void *) 2;
						break;
					} else
						printf("[INFO] Authorization succeeded\n");
				} else { // Messages without an ID (or not with an ID we set):
					json_t * method_object = json_object_get(root, "method");
					if(method_object == NULL)
					{
						json_t * result = json_object_get(root, "result");
						if(result == NULL || json_typeof(result) == JSON_FALSE) // Error
						{
							json_t * error = json_object_get(root, "error");
							if(error != NULL)
							{
								printf("[WARNING] Server reports error: %s\n",
									json_string_value(json_array_get(error, 1)));
							}

							// If error is NULL at this point, something is very wrong...
							// better ignore it /:
						} else if(json_typeof(result) == JSON_TRUE)
						{
							printf("[INFO] Share accepted!\n");
						}
					} else if(!strcmp(json_string_value(method_object), "mining.set_difficulty"))
					{
						printf("[INFO] Difficulty set to %d\n", (int) json_integer_value(
							json_array_get(json_object_get(root, "params"), 0)));
						difficulty = json_integer_value(json_array_get(json_object_get(
							root, "params"), 0));
					} else if(!strcmp(json_string_value(method_object), "mining.notify"))
					{
						printf("[INFO] Received new block to mine from the server\n");

						json_t * params_object = json_object_get(root, "params");
						json_t * job_id_object = json_array_get(params_object, 0);
						json_t * prevhash_object = json_array_get(params_object, 1);
						json_t * coinb1_object = json_array_get(params_object, 2);
						json_t * coinb2_object = json_array_get(params_object, 3);
						json_t * merkle_branch_object = json_array_get(params_object, 4);
						json_t * version_object = json_array_get(params_object, 5);
						json_t * nbits_object  = json_array_get(params_object, 6);
						json_t * ntime_object = json_array_get(params_object, 7);
						json_t * clean_object = json_array_get(params_object, 8);

						char ** merkle_branch = malloc(sizeof(char *)
							* json_array_size(merkle_branch_object));
						for(int i = 0; i < json_array_size(merkle_branch_object); ++i)
						{
							//printf("Merkle branch %d: %s\n", i, json_string_value(
							//	json_array_get(merkle_branch_object, i)));
							const char * mb = json_string_value(json_array_get(
								merkle_branch_object, i));
							merkle_branch[i] = strdup(mb);
						}

						miner_add_job(
							json_string_value(job_id_object),
							json_string_value(prevhash_object),
							json_string_value(coinb1_object),
							json_string_value(coinb2_object),
							merkle_branch, 
							json_array_size(merkle_branch_object),
							json_string_value(version_object),
							json_string_value(nbits_object),
							json_string_value(ntime_object),
							extranonce1,
							difficulty,
							json_typeof(clean_object) == JSON_TRUE);
					}
				}

				json_decref(root);
			}

			message = strtok(NULL, "\n");
		} while(message != NULL);
	}

	pthread_cleanup_pop(1);
	return (void *) retval;
}

