// Slowpoke Bitcoin Miner for CPU Mining
// (c) Kristian Klomsten Skordal 2014 <kristian.skordal@wafflemail.net>

#ifndef MINER_H
#define MINER_H

#include <stdint.h>
#include <stdbool.h>

#include "stratum.h"

/**
 * Initializes the miner.
 * @param threads number of work threads.
 */
bool miner_initialize(int threads);

/**
 * Stops the miner.
 */
void miner_stop(void);

/**
 * Adds a job to the miner. The parameters here are basically the raw string data as received from
 * the stratum server.
 * FIXME: Actually does the job for now, but in the future, this function will schedule it for distribution
 * FIXME: among work threads.
 */
void miner_add_job(const char * job_id, const char * prevhash, const char * coinb1, const char * coinb2,
	char ** merkle_branch, int merkle_branch_length, const char * version, const char * nbits,
	const char * ntime, const char * extranonce1, int difficulty, bool clean_jobs);

#endif

