// Slowpoke Bitcoin Miner for CPU Mining
// (c) Kristian Klomsten Skordal 2014 <kristian.skordal@wafflemail.net>

#ifndef STRATUM_H
#define STRATUM_H

#include <stdbool.h>
#include <stdint.h>

#include "miner.h"

// Connects to a stratum server:
bool stratum_connect(const char * host, const char * port, const char * username, const char * password);
// Runs the stratum client:
void stratum_run(void);

// Submits a result to the server:
void stratum_submit(const char * job_id, const char * extranonce2, const char * ntime, const char * nonce);

#endif

