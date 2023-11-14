COSMOCC ?= cosmocc
CC ?= cc
AR ?= ar

PREFIX ?= output

INCLUDES = src/exitcodes.h src/ipc.h $(PREFIX)/include/raylib.h
INCLUDEPATHS = -I$(PREFIX)/include/

.PHONY: build clean
build: $(PREFIX)/bin/cosmo/server.com $(PREFIX)/bin/native/client

clean:
	rm -rf $(PREFIX)

$(PREFIX)/%/:
	mkdir -p $@


$(PREFIX)/bin/cosmo/server.com: src/server.c src/ipc.c $(INCLUDES) | $(PREFIX)/bin/cosmo/
	$(COSMOCC) -o $@ $(filter %.c,$^) -D_COSMO_SOURCE_ -DSERVER $(INCLUDEPATHS)

$(PREFIX)/bin/native/client: src/client.c src/ipc.c $(INCLUDES) $(PREFIX)/lib/native/libraylib.a | $(PREFIX)/bin/native/
	$(CC) -o $@ $(filter %.c,$^) -DCLIENT $(INCLUDEPATHS) -L$(PREFIX)/lib/native/ -lraylib -lm


$(PREFIX)/include/raylib.h: third_party/raylib/src/raylib.h | $(PREFIX)/include/
	cp --update $< $@

$(PREFIX)/lib/native/libraylib.a: | $(PREFIX)/lib/native/
	$(MAKE) -C third_party/raylib/src/ PLATFORM=PLATFORM_DESKTOP RAYLIB_RELEASE_PATH=../../../output/lib/native/
