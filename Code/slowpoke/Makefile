# Slowpoke Bitcoin Miner for CPU Mining
# (c) Kristian Klomsten Skordal 2014 <kristian.skordal@wafflemail.net>
.PHONY: all check-config clean

OBJECTS := main.o miner.o stratum.o utils.o

# Build flags:
CFLAGS += -O2 -g -Wall -std=gnu11 $(shell pkg-config --cflags jansson openssl)
LDFLAGS += -Wall -lpthread -lgmp $(shell pkg-config --libs jansson openssl) -lm

all: check-config $(OBJECTS)
	$(CC) $(LDFLAGS) -o slowpoke $(OBJECTS)

check-config:
	@pkg-config --exists jansson || echo "Please install the Jansson JSON library."
	@pkg-config --exists openssl || echo "Please install the OpenSSL library (used for hashing)."

clean:
	-$(RM) slowpoke $(OBJECTS)

# Manual dependency tracking due to few object files:
main.o: main.c miner.h stratum.h test_vectors.h
miner.o: miner.c miner.h stratum.h utils.h
stratum.o: stratum.c stratum.h miner.h
utils.o: utils.c utils.h

