COSMOCC ?= x86_64-unknown-cosmo-cc
LINUXCC ?= cc
#WINCC   ?= x86_64-w64-mingw32-gcc

#COSMOAR ?= x86_64-unknown-cosmo-ar
#LINUXAR ?= ar
#WINAR   ?= x86_64-w64-mingw32-ar

PYTHON ?= python3

PREFIX ?= output

.PHONY: build clean

build: $(PREFIX)/x86_64-unknown-cosmo/bin/addtest.com

clean:
	rm -rf $(PREFIX) src/generated/

%/:
	mkdir -p $@


libtestlib = $(PREFIX)/x86_64-unknown-linux-gnu/lib/libtestlib.so $(PREFIX)/x86_64-unknown-linux-gnu/include/testlib.h
#libtestlib_wrapper = $(PREFIX)/x86_64-unknown-linux-gnu/lib/libtestlib_wrapper.so $(PREFIX)/x86_64-unknown-linux-gnu/include/testlib_wrapper.h


# Headers
$(PREFIX)/x86_64-unknown-linux-gnu/include/testlib.h: src/testlib.h | $(PREFIX)/x86_64-unknown-linux-gnu/include/
	cp --update $< $@

$(PREFIX)/x86_64-unknown-linux-gnu/include/testlib_wrapper.h: src/testlib_wrapper.h | $(PREFIX)/x86_64-unknown-linux-gnu/include/
	cp --update $< $@


# Generated files
src/generated/x86_64-unknown-linux-gnu/libtestlib.so.init.c src/generated/x86_64-unknown-linux-gnu/libtestlib.so.tramp.S: third_party/Implib.so/implib-gen.py $(PREFIX)/x86_64-unknown-linux-gnu/lib/libtestlib.so | src/generated/x86_64-unknown-linux-gnu/
	$(PYTHON) $^ -o $(dir $@)

src/generated/x86_64-unknown-linux-gnu/libtestlib_wrapper.so.init.c src/generated/x86_64-unknown-linux-gnu/libtestlib_wrapper.so.tramp.S: third_party/Implib.so/implib-gen.py $(PREFIX)/x86_64-unknown-linux-gnu/lib/libtestlib_wrapper.so | src/generated/x86_64-unknown-linux-gnu/
	$(PYTHON) $^ -o $(dir $@) --dlopen-callback cosmo_dlopen_wrapper --dlsym-callback cosmo_dlsym


# Shared libaries
$(PREFIX)/x86_64-unknown-linux-gnu/lib/libtestlib.so: src/testlib.c src/testlib.h | $(PREFIX)/x86_64-unknown-linux-gnu/lib/
	$(LINUXCC) --shared -fpic -o $@ $(filter %.c,$^) -lm

# TODO Find a way to not include libtestlib setup functions
$(PREFIX)/x86_64-unknown-linux-gnu/lib/libtestlib_wrapper.so: src/testlib_wrapper_native.c $(libtestlib) src/generated/x86_64-unknown-linux-gnu/libtestlib.so.init.c src/generated/x86_64-unknown-linux-gnu/libtestlib.so.tramp.S | $(PREFIX)/x86_64-unknown-linux-gnu/lib/
	$(LINUXCC) --shared -fpic -o $@ $(filter %.c %.S,$^) -I$(PREFIX)/x86_64-unknown-linux-gnu/include/


# Executables
$(PREFIX)/x86_64-unknown-cosmo/bin/addtest.com: src/addtest.c src/dlopen_wrapper.c src/testlib_wrapper_cosmo.c src/generated/x86_64-unknown-linux-gnu/libtestlib_wrapper.so.init.c src/generated/x86_64-unknown-linux-gnu/libtestlib_wrapper.so.tramp.S $(PREFIX)/x86_64-unknown-linux-gnu/include/testlib.h $(PREFIX)/x86_64-unknown-linux-gnu/include/testlib_wrapper.h | $(PREFIX)/x86_64-unknown-cosmo/bin/
	$(COSMOCC) -mcosmo -o $@ $(filter %.c %.S,$^) -I$(PREFIX)/x86_64-unknown-linux-gnu/include/
