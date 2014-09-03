// Slowpoke Bitcoin Miner for CPU Mining
// (c) Kristian Klomsten Skordal 2014 <kristian.skordal@wafflemail.net>

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <gmp.h>
#include <math.h>
#include <pthread.h>

#include "miner.h"
#include "utils.h"

static pthread_mutex_t new_work_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t new_work_ready = PTHREAD_COND_INITIALIZER;
static pthread_barrier_t new_work_barrier;

static pthread_mutex_t extranonce2_mutex = PTHREAD_MUTEX_INITIALIZER;
static uint32_t extranonce2;

static bool workers_running = true;
static bool work_valid = false;

static pthread_t * worker_threads;
static int num_worker_threads;

static char * worker_job_id, * worker_prevhash, * worker_coinb1, * worker_coinb2;
static char * worker_ntime, * worker_extranonce1, * worker_version, * worker_nbits;
static char ** worker_merkle_branch;
static int worker_merkle_branch_length, worker_difficulty;
static int worker_job = 0;

static void miner_create_coinbase_hash(const char * coinb1, const char * coinb2,
	const char * extranonce1, const char * extranonce2, uint8_t * hash);
static void miner_create_header_hash(const char * version, const char * prevhash, const char * merkle_root,
	const char * ntime, const char * nbits, char * nonce, uint8_t * hash);

static void miner_finalize(void);
static void * worker_thread_function(void * arg);

bool miner_initialize(int threads)
{
	num_worker_threads = threads;
	worker_threads = malloc(sizeof(pthread_t) * num_worker_threads);

	if(pthread_barrier_init(&new_work_barrier, NULL, num_worker_threads + 1) != 0)
	{
		fprintf(stderr, "[ERROR] Could not initialize POSIX threads barrier!\n");
		return false;
	}

	for(int i = 0; i < num_worker_threads; ++i)
	{
		intptr_t worker_id = i;
		int status = pthread_create(worker_threads + i, NULL, worker_thread_function, (void *) worker_id);
		if(status != 0)
		{
			fprintf(stderr, "[ERROR] Could not start worker thread %d\n", i);
			return false;
		}
	}

	atexit(miner_finalize);
	return true;
}

void miner_stop(void)
{
	work_valid = false;
	pthread_barrier_wait(&new_work_barrier);
	workers_running = false;
}

void miner_add_job(const char * job_id, const char * prevhash, const char * coinb1, const char * coinb2,
	char ** merkle_branch, int merkle_branch_length, const char * version, const char * nbits,
	const char * ntime, const char * extranonce1, int difficulty, bool clean_jobs)
{
	worker_job = 0;

	// Stop worker threads and wait for them to wait for new data:
	work_valid = false;
	pthread_barrier_wait(&new_work_barrier); // TODO: Find a better solution than barriers

	// The threads are now waiting for new work.

	pthread_mutex_lock(&new_work_mutex);
	worker_difficulty = difficulty;

	if(worker_job_id != NULL)
		free(worker_job_id);
	worker_job_id = strdup(job_id);

	if(worker_prevhash != NULL)
		free(worker_prevhash);
	worker_prevhash = strdup(prevhash);

	if(worker_coinb1 != NULL)
		free(worker_coinb1);
	worker_coinb1 = strdup(coinb1);

	if(worker_coinb2 != NULL)
		free(worker_coinb2);
	worker_coinb2 = strdup(coinb2);

	if(worker_merkle_branch != NULL)
	{
		for(int i = 0; i < worker_merkle_branch_length; ++i)
			free(worker_merkle_branch[i]);
		free(worker_merkle_branch);
	}
	worker_merkle_branch = merkle_branch; // Allocated but not freed in the server code
	worker_merkle_branch_length = merkle_branch_length;

	if(worker_version != NULL)
		free(worker_version);
	worker_version = strdup(version);

	if(worker_nbits != NULL)
		free(worker_nbits);
	worker_nbits = strdup(nbits);

	if(worker_ntime != NULL)
		free(worker_ntime);
	worker_ntime = strdup(ntime);

	if(worker_extranonce1 != NULL)
		free(worker_extranonce1);
	worker_extranonce1 = strdup(extranonce1);

	printf("[INFO] New work submitted to work threads\n");
	work_valid = true;
	pthread_cond_broadcast(&new_work_ready);
	pthread_mutex_unlock(&new_work_mutex);

/*
	uint32_t extranonce2 = 0x00000000; // This is incremented for each try
	char * extranonce2_string = malloc(9);
	sprintf(extranonce2_string, "%08x", extranonce2);
	printf("%s\n", extranonce2_string);

	uint8_t hash[64];
	miner_create_coinbase_hash(coinb1, coinb2, extranonce1, extranonce2_string, hash);

	if(merkle_branch != NULL && merkle_branch_length != 0)
	{
		// Calculate the merkle root:
		for(int i = 0; i < merkle_branch_length; ++i)
		{
			utils_decode_hex(merkle_branch[i], hash + 32);
			utils_doublesha256(hash, 64, hash);
		}
	}

	// The merkle root is now in hash[0 .. 31].
	char * merkle_root;
	utils_encode_hex(hash, 32, &merkle_root);
	printf("Merkle root %s\n", merkle_root);

	miner_create_header_hash(version, prevhash, merkle_root, ntime, nbits, 0x00000001, hash);
	char * header_hash;
	utils_encode_hex(hash, 32, &header_hash);
	printf("Header hash: %s\n", header_hash);

	mpz_t header_value;
	mpz_init_set_str(header_value, header_hash, 16);

	mpz_t target;
	mpz_init_set_str(target, "00000000ffff0000000000000000000000000000000000000000000000000000", 16);
	mpz_tdiv_q_2exp(target, target, (int) log2(difficulty));

	if(mpz_cmp(header_value, target) < 0)
	{
		printf("Valid block found!\n");
		// Valid block found.
	}

	printf("Target: %s\n", mpz_get_str(NULL, 16, target));
*/
}

static void miner_create_coinbase_hash(const char * coinb1, const char * coinb2,
	const char * extranonce1, const char * extranonce2, uint8_t * hash)
{
	char * coinbase_string = malloc(strlen(coinb1) + strlen(coinb2) +
		strlen(extranonce1) + strlen(extranonce2) + 1);
	strcpy(coinbase_string, coinb1);	// coinb1
	strcat(coinbase_string, extranonce1);	// + extranonce1
	strcat(coinbase_string, extranonce2);	// + extranonce2
	strcat(coinbase_string, coinb2);	// + coinb2

	int coinbase_binary_length = strlen(coinbase_string) / 2;
	uint8_t * coinbase_binary = malloc(coinbase_binary_length);
	utils_decode_hex(coinbase_string, coinbase_binary);

	utils_doublesha256(coinbase_binary, coinbase_binary_length, hash);

	free(coinbase_binary);
	free(coinbase_string);
}

static void miner_create_header_hash(const char * version, const char * prevhash, const char * merkle_root,
	const char * ntime, const char * nbits, char * nonce, uint8_t * hash)
{
	char * header_string = malloc(strlen(version) + strlen(prevhash) + strlen(merkle_root)
		+ strlen(ntime) + strlen(nbits) + strlen(nonce) + 1);
	strcpy(header_string, version);
	strcat(header_string, prevhash);
	strcat(header_string, merkle_root);
	strcat(header_string, ntime);
	strcat(header_string, nbits);
	strcat(header_string, nonce);

	// Swap endianness for all header fields except the merkle root,
	// done this way to prevent uneccessary copying of strings:
	utils_hexstring_swap_endian(header_string, strlen(version)); // version field
	utils_hexstring_swap_endian(header_string + strlen(version), strlen(prevhash)); // prevhash field
	utils_hexstring_swap_endian(header_string + strlen(version) + strlen(prevhash) + strlen(merkle_root),
		strlen(ntime)); // ntime field
	utils_hexstring_swap_endian(header_string + strlen(version) + strlen(prevhash) + strlen(merkle_root) + strlen(ntime),
		strlen(nbits));
	utils_hexstring_swap_endian(header_string + strlen(version) + strlen(prevhash) + strlen(merkle_root) + strlen(ntime) + strlen(nbits),
		strlen(nonce)); // nonce field

	int header_length = (strlen(version) + strlen(prevhash) + strlen(merkle_root) + strlen(ntime) + strlen(nbits) + strlen(nonce)) / 2;
	uint8_t * header_data = malloc(header_length);
	utils_decode_hex(header_string, header_data);

	utils_doublesha256(header_data, header_length, hash);

	free(header_string);
	free(header_data);
}

static void miner_finalize(void)
{
	workers_running = false;
	pthread_cond_broadcast(&new_work_ready);
	for(int i = 0; i < num_worker_threads; ++i)
		pthread_join(worker_threads[i], NULL);
	free(worker_threads);

	pthread_barrier_destroy(&new_work_barrier);
}

static void * worker_thread_function(void * args)
{
	int thread_num = (int) (intptr_t) args;
	uint32_t local_extranonce2;
	char extranonce2_string[9];
	char nonce_string[9];
	char merkle_root[65];
	char header_hash[65];

	printf("[INFO] Worker thread %d started!\n", thread_num);

	while(workers_running)
	{
		// Wait for valid work:
		if(!work_valid)
		{
			pthread_barrier_wait(&new_work_barrier);
			if(!workers_running) // The condition may be signaled when the threads are to exit.
				break;

			pthread_mutex_lock(&new_work_mutex);
			while(!work_valid)
				pthread_cond_wait(&new_work_ready, &new_work_mutex);
			pthread_mutex_unlock(&new_work_mutex);
			printf("[INFO] Worker thread %d going to work!\n", thread_num);
		}

		// Work data is valid, get an extranonce2 value to use:
		pthread_mutex_lock(&extranonce2_mutex);
		local_extranonce2 = extranonce2++;
		pthread_mutex_unlock(&extranonce2_mutex);

		sprintf(extranonce2_string, "%08x", local_extranonce2);

		for(uint32_t nonce = 0; nonce != 0xffffffff; ++nonce)
		{
			uint8_t hash[64];

			// If new work should be started, cancel the for loop:
			if(!work_valid || !workers_running)
				break;

			// Create a string representation of the nonce value:
			sprintf(nonce_string, "%08x", nonce);

			// Hash the coinbase transaction:
			miner_create_coinbase_hash(worker_coinb1, worker_coinb2, worker_extranonce1, extranonce2_string, hash);

			// Calculate the merkle root:
			if(worker_merkle_branch != NULL && worker_merkle_branch_length != 0)
			{
				for(int i = 0; i < worker_merkle_branch_length; ++i)
				{
					utils_decode_hex(worker_merkle_branch[i], hash + 32);
					utils_doublesha256(hash, 64, hash);
				}
			}

			// The merkle root is now in hash[0 .. 31].
			utils_encode_hex(hash, 32, merkle_root);

			miner_create_header_hash(worker_version, worker_prevhash,
				merkle_root, worker_ntime, worker_nbits, nonce_string, hash);
			utils_encode_hex(hash, 32, header_hash);
			// printf("Header hash: %s\n", header_hash);

			mpz_t header_value, target_value;
			mpz_init_set_str(header_value, header_hash, 16);
			mpz_init_set_str(target_value, "00000000ffff0000000000000000000000000000000000000000000000000000", 16);
			mpz_tdiv_q_2exp(target_value, target_value, (int) log2(worker_difficulty));

			if(mpz_cmp(header_value, target_value) < 0)
			{
				printf("[INFO] Thread %d found valid block with hash %s\n", thread_num, header_hash);
				stratum_submit(worker_job_id, extranonce2_string, worker_ntime, nonce_string);
			} else {
//				printf("[INFO] Thread %d found invalid block with hash %s!\n", thread_num, header_hash);
			}

			mpz_clear(header_value);
			mpz_clear(target_value);

		}
	}

	printf("[INFO] Worker thread %d exiting\n", thread_num);

	return 0;
}

