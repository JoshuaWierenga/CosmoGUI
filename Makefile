COSMOCC ?= cosmocc
CC ?= cc

.PHONY: build clean
build: bin/server.com bin/client

clean:
	rm -rf bin/

bin:
	mkdir -p $@

bin/server.com: server.c | bin
	$(COSMOCC) -o $@ $< -D _COSMO_SOURCE_

bin/client: client.c | bin
	$(CC) -o $@ $<
