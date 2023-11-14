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

$(PREFIX)/bin/native/client: src/client.c src/ipc.c $(CLIENTSERVERINCLUDES) $(PREFIX)/include/raylib.h $(PREFIX)/lib/native/libraylib.a | $(PREFIX)/bin/native/
	$(CC) -o $@ $(filter %.c,$^) -D CLIENT -I$(PREFIX)/include/ -L$(PREFIX)/lib/native/ -lraylib -lm


$(PREFIX)/include/raylib.h: third_party/raylib/src/raylib.h | $(PREFIX)/include/
	cp --update $< $@

$(PREFIX)/lib/native/libraylib.a: | $(PREFIX)/lib/native/
	$(MAKE) -C third_party/raylib/src/ PLATFORM=PLATFORM_DESKTOP RAYLIB_RELEASE_PATH=../../../output/lib/native/
