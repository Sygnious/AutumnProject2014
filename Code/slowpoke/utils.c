// Slowpoke Bitcoin Miner for CPU Mining
// (c) Kristian Klomsten Skordal 2014 <kristian.skordal@wafflemail.net>

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

// For now, cheat by using OpenSSL's SHA256 implementation:
#include <openssl/sha.h>

#include "utils.h"

static uint8_t decode_hex(char c);

void utils_hexstring_swap_endian(char * hex_string, int length)
{
	uint16_t * byte_string = (uint16_t *) hex_string;

	for(int i = 0; i < length / 2 / 2; i += 4)
	{
		uint16_t temp[4] = {
			byte_string[i], byte_string[i + 1],
			byte_string[i + 2], byte_string[i + 3]
		};

		byte_string[i] = temp[3];
		byte_string[i + 1] = temp[2];
		byte_string[i + 2] = temp[1];
		byte_string[i + 3] = temp[0];
	}
}

void utils_decode_hex(const char * hex_string, uint8_t * binary)
{
	size_t hex_length = strlen(hex_string);

	for(int i = 0; i < hex_length; i += 2)
	{
		uint8_t result = 0;
		result |= (decode_hex(hex_string[i]) << 4) | decode_hex(hex_string[i + 1]);
		binary[i / 2] = result;
	}
}

void utils_encode_hex(uint8_t * binary, int binary_length, char * hex_string)
{
//	*hex_string = malloc(binary_length * 2 + 1);

	for(int i = 0; i < binary_length; ++i)
		sprintf(hex_string + i * 2, "%02x", binary[i]);
	hex_string[binary_length * 2] = 0;
}

void utils_swap_endian(uint8_t * binary, int binary_length)
{
	for(int i = 0; i < binary_length; i+= 4)
	{
		uint8_t bytes[4];

		bytes[0] = binary[i + 0];
		bytes[1] = binary[i + 1];
		bytes[2] = binary[i + 2];
		bytes[3] = binary[i + 3];

		binary[i] = bytes[3];
		binary[i + 1] = bytes[2];
		binary[i + 2] = bytes[1];
		binary[i + 3] = bytes[0];
	}
}

void utils_sha256(uint8_t * data, int data_length, uint8_t hash[32])
{
	SHA256_CTX context;

	SHA256_Init(&context);
	SHA256_Update(&context, data, data_length);
	SHA256_Final(hash, &context);
}

void utils_doublesha256(uint8_t * data, int data_length, uint8_t hash[32])
{
	utils_sha256(data, data_length, hash);
	utils_sha256(hash, 32, hash);
}

static uint8_t decode_hex(char c)
{
	if(c >= '0' && c <= '9')
		return c - '0';
	else if(c >= 'a' && c <= 'f')
		return (c - 'a') + 0xa;
	else
		return (c - 'A') + 0xa;
}

