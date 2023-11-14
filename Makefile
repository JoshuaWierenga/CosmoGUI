COSMOCC ?= cosmocc
CC ?= cc
AR ?= ar

PREFIX ?= output

CLIENTSERVERINCLUDES = src/exitcodes.h src/ipc.h

.PHONY: build clean
build: $(PREFIX)/bin/cosmo/server.com $(PREFIX)/bin/native/client

clean:
	rm -rf $(PREFIX)

$(PREFIX)/%/:
	mkdir -p $@


$(PREFIX)/bin/cosmo/server.com: src/server.c src/ipc.c $(CLIENTSERVERINCLUDES) | $(PREFIX)/bin/cosmo/
	$(COSMOCC) -o $@ $(filter %.c,$^) -D _COSMO_SOURCE_ -D SERVER

$(PREFIX)/bin/native/client: src/client.c src/ipc.c $(CLIENTSERVERINCLUDES) $(PREFIX)/include/dummy.h $(PREFIX)/lib/native/libdummy.a | $(PREFIX)/bin/native/
	$(CC) -o $@ $(filter %.c,$^) -D CLIENT -I$(PREFIX)/include/ -L$(PREFIX)/lib/native/ -ldummy


$(PREFIX)/include/dummy.h: src/dummy/dummy.h | $(PREFIX)/include/
	cp $< $@

$(PREFIX)/lib/native/libdummy.a: src/dummy/add.c src/dummy/dummy.h | $(PREFIX)/lib/native/
	$(CC) -c -o $(PREFIX)/lib/native/libdummy.o $<
	$(AR) rcs $@ $(PREFIX)/lib/native/libdummy.o
