// Slowpoke Bitcoin Miner for CPU Mining
// (c) Kristian Klomsten Skordal 2014 <kristian.skordal@wafflemail.net>

#include <stdio.h>
#include <stdlib.h>

#include "miner.h"
#include "stratum.h"
#include "test_vectors.h"
#include "utils.h"

static void print_usage(void);

int main(int argc, char * argv[])
{
	if(argc != 6)
	{
		print_usage();
		return 1;
	}

	if(!miner_initialize(atoi(argv[5])))
		return 1;

	if(!stratum_connect(argv[1], argv[2], argv[3], argv[4]))
		return 1;

	stratum_run();
	miner_stop();

/*
	const char * test_merkle_branch[] =
	{
		TEST_MERKLE1,
		TEST_MERKLE2,
		TEST_MERKLE3,
		TEST_MERKLE4,
		TEST_MERKLE5,
		TEST_MERKLE6
	};
	miner_add_job(TEST_JOBID, TEST_PREVHASH, TEST_COINBASE1, TEST_COINBASE2,
		test_merkle_branch, 6, TEST_VERSION, TEST_BITS, TEST_TIME, TEST_EXTRANONCE1,
		TEST_DIFFICULTY, true);
*/
/*
	miner_add_job(NULL, "7dcf1304b04e79024066cd9481aa464e2fe17966e19edf6f33970e1fe0b60277",
		"01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff270362f401062f503253482f049b8f175308",
		"0d2f7374726174756d506f6f6c2f000000000100868591052100001976a91431482118f1d7504daf1c001cbfaf91ad580d176d88ac00000000",
		NULL, 0, "00000002", "1b44dfdb", "53178f9f", "f8002c90", 0, true);
*/
/*
	const char * test = "abc";
	printf("%x %x %x\n", test[0], test[1], test[2]);

	const char * test_data = "616263";
*/
/*
	uint8_t * hash = utils_sha256((uint8_t *) "abc", 3);

	char * temp;
	utils_encode_hex(hash, 32, &temp);
	printf("%s\n", temp);
*/
	return 0;
}

static void print_usage(void)
{
	printf("Usage:\n");
	printf("\tslowpoke <hostname> <port> <username> <password> <number of threads>\n");
}

