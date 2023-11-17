COSMOCC ?= cosmocc
LINUXCC ?= cc
WINCC   ?= x86_64-w64-mingw32-gcc

LINUXAR ?= ar
WINAR   ?= x86_64-w64-mingw32-ar

PYTHON ?= python

PREFIX ?= output

.PHONY: build clean
build: $(PREFIX)/bin/cosmo/gui.com $(PREFIX)/lib/x86_64-unknown-linux-gnu/libraylib.so $(PREFIX)/lib/x86_64-pc-windows-gnu/raylib.dll

clean:
	rm -rf $(PREFIX) src/generated/

%/:
	mkdir -p $@


$(PREFIX)/bin/cosmo/gui.com: src/gui.c src/generated/raylib-wrapper.c $(PREFIX)/include/raylib.h | $(PREFIX)/bin/cosmo/
	$(COSMOCC) -o $@ $(filter %.c,$^) -D_COSMO_SOURCE -I$(PREFIX)/include/

$(PREFIX)/include/raylib.h: third_party/raylib/src/raylib.h | $(PREFIX)/include/
	cp --update $< $@


src/generated/raylib-wrapper.c: tools/generate-raylib-wrapper.py | src/generated/
	$(PYTHON) $<


.NOTPARALLEL: $(PREFIX)/lib/linux/libraylib.a $(PREFIX)/lib/windows/libraylib.a

$(PREFIX)/lib/x86_64-unknown-linux-gnu/libraylib.so: | $(PREFIX)/lib/x86_64-unknown-linux-gnu/
	$(MAKE) -C third_party/raylib/src/ clean
	$(MAKE) -C third_party/raylib/src/ CC=$(LINUXCC) AR=$(LINUXAR) PLATFORM=PLATFORM_DESKTOP PLATFORM_OS=LINUX RAYLIB_LIBTYPE=SHARED RAYLIB_RELEASE_PATH=../../../output/lib/x86_64-unknown-linux-gnu/

$(PREFIX)/lib/x86_64-pc-windows-gnu/raylib.dll: third_party/raylib/src/raylib.dll.rc.data.updated | $(PREFIX)/lib/x86_64-pc-windows-gnu/
	$(MAKE) -C third_party/raylib/src/ clean
	$(MAKE) -C third_party/raylib/src/ CC=$(WINCC) AR=$(WINAR) PLATFORM=PLATFORM_DESKTOP PLATFORM_OS=WINDOWS RAYLIB_LIBTYPE=SHARED RAYLIB_RELEASE_PATH=../../../output/lib/x86_64-pc-windows-gnu/

# raylib 4.5.0 ships with a 32 bit resource file, this was corrected after release
third_party/raylib/src/raylib.dll.rc.data.updated:
	wget https://github.com/raysan5/raylib/raw/19892a3c3a08a9bfa291d0d8c745ca23a27c9972/src/raylib.dll.rc.data -O third_party/raylib/src/raylib.dll.rc.data
	touch $@
