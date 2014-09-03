// Slowpoke Bitcoin Miner for CPU Mining
// (c) Kristian Klomsten Skordal 2014 <kristian.skordal@wafflemail.net>

#ifndef UTILS_H
#define UTILS_H

#include <stdint.h>

/**
 * Converts a hexadecimal string to the opposite endianness, with wordsize 32.
 */
void utils_hexstring_swap_endian(char * hex_string, int length);

/**
 * Decodes the null-terminated string of hexadecimal characters into binary.
 * @param hex_string null-terminated string of hexadecimal characters.
 * @param binary location to store the pointer to the decoded data. This must be
 *               freed after use.
 * @param binary_length if not NULL, length of the binary array.
 */
void utils_decode_hex(const char * hex_string, uint8_t * binary);

/**
 * Encodes a binary value as a string of hexadecimal characters.
 * @param binary array of binary values to encode.
 * @param binary_length length of the array of binary data in bytes.
 */
void utils_encode_hex(uint8_t * binary, int binary_length, char * hex_string);

/**
 * Calculates the SHA256 hash of the input data.
 * @param data input data.
 * @param data_length input data length.
 * @return a newly allocated array with the hash data.
 */
void utils_sha256(uint8_t * data, int data_length, uint8_t hash[32]);

/**
 * Calculates the double SHA256 hash of the input data.
 */
void utils_doublesha256(uint8_t * data, int data_length, uint8_t hash[32]);

#endif

