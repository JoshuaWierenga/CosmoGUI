COSMOCC ?= cosmocc
LINUXCC ?= cc
WINCC ?= x86_64-w64-mingw32-gcc

LINUXAR ?= ar
WINAR ?= x86_64-w64-mingw32-ar

PREFIX ?= output

INCLUDES = src/exitcodes.h src/ipc.h $(PREFIX)/include/raylib.h
INCLUDEPATHS = -I$(PREFIX)/include/

.PHONY: build clean
build: $(PREFIX)/bin/cosmo/server.com $(PREFIX)/bin/linux/client $(PREFIX)/bin/windows/client.exe

clean:
	rm -rf $(PREFIX)

$(PREFIX)/%/:
	mkdir -p $@


$(PREFIX)/bin/cosmo/server.com: src/server.c src/ipc.c $(INCLUDES) | $(PREFIX)/bin/cosmo/
	$(COSMOCC) -o $@ $(filter %.c,$^) -D_COSMO_SOURCE_ -DSERVER $(INCLUDEPATHS)

$(PREFIX)/bin/linux/client: src/client.c src/ipc.c $(INCLUDES) $(PREFIX)/lib/linux/libraylib.a | $(PREFIX)/bin/linux/
	$(LINUXCC) -o $@ $(filter %.c,$^) -DCLIENT $(INCLUDEPATHS) -L$(PREFIX)/lib/linux/ -lraylib -lm

$(PREFIX)/bin/windows/client.exe: src/client.c src/ipc.c $(INCLUDES) $(PREFIX)/lib/windows/libraylib.a | $(PREFIX)/bin/windows/
	$(WINCC) -o $@ $(filter %.c,$^) -DCLIENT $(INCLUDEPATHS) -L$(PREFIX)/lib/windows/ -lraylib -lgdi32 -lwinmm

$(PREFIX)/include/raylib.h: third_party/raylib/src/raylib.h | $(PREFIX)/include/
	cp --update $< $@


.NOTPARALLEL: $(PREFIX)/lib/linux/libraylib.a $(PREFIX)/lib/windows/libraylib.a

$(PREFIX)/lib/linux/libraylib.a: | $(PREFIX)/lib/linux/
	$(MAKE) -C third_party/raylib/src/ clean
	$(MAKE) -C third_party/raylib/src/ CC=$(LINUXCC) AR=$(LINUXAR) PLATFORM=PLATFORM_DESKTOP PLATFORM_OS=LINUX RAYLIB_RELEASE_PATH=../../../output/lib/linux/

# Not sure why raylib doesn't use .lib for windows
$(PREFIX)/lib/windows/libraylib.a: | $(PREFIX)/lib/windows/
	$(MAKE) -C third_party/raylib/src/ clean
	$(MAKE) -C third_party/raylib/src/ CC=$(WINCC) AR=$(WINAR) PLATFORM=PLATFORM_DESKTOP PLATFORM_OS=WINDOWS RAYLIB_RELEASE_PATH=../../../output/lib/windows/
