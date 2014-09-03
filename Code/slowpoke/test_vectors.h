// Slowpoke Bitcoin Miner for CPU Mining
// (c) Kristian Klomsten Skordal 2014 <kristian.skordal@wafflemail.net>

#ifndef TEST_VECTORS_H
#define TEST_VECTORS_H

// Some test data, so we can try to replicate some of the output they get at
// http://thedestitutedeveloper.blogspot.no/2014/03/stratum-mining-block-headers-worked.html
// (although the source describes a scrypt-based block header)

#define TEST_JOBID        "5c04"
#define TEST_PREVHASH     "da0dadb0eda4381df442bde08d23d54d7d371d5ce7af3ee716bd2a7e017eacb8"
#define TEST_COINBASE1    "01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff2a03700a08062f503253482f04953f1a5308"
#define TEST_COINBASE2    "102f776166666c65706f6f6c2e636f6d2f0000000001d07e582a010000001976a9145d8f33b0a7c94c878d572c40cbff22a49268467d88ac00000000"
#define TEST_EXTRANONCE1  "60021014"
#define TEST_VERSION      "00000002"
#define TEST_BITS         "1b10b60e"
#define TEST_TIME         "531a3f95"

#define TEST_MERKLE1      "50a4a386ab344d40d29a833b6e40ea27dab6e5a79a2f8648d3bc0d1aa65ecd3f"
#define TEST_MERKLE2      "7952ecc836fb104f41b2cb06608eeeaa6d1ca2fe4391708fb13bb10ccf8da179"
#define TEST_MERKLE3      "9400ec6453aac577fb6807f11219b4243a3e50ca6d1c727e6d05663211960c94"
#define TEST_MERKLE4      "c11a630fa9332ab51d886a47509b5cbace844316f4fc52b493359b305fd489ae"
#define TEST_MERKLE5      "85891e7c5773f234d647f1d5fca7fbcabb59b261322d16c0ae486ccf5143383d"
#define TEST_MERKLE6      "faa26bbc17f99659f64136bea29b3fc8d772b339c52707d5f2ccfe1195317f43"

#define TEST_DIFFICULTY   512

#endif

