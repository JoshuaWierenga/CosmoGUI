COSMOCC ?= x86_64-unknown-cosmo-cc
LINUXCC ?= cc
#WINCC   ?= x86_64-w64-mingw32-gcc

#COSMOAR ?= x86_64-unknown-cosmo-ar
#LINUXAR ?= ar
#WINAR   ?= x86_64-w64-mingw32-ar

PYTHON ?= python3

PREFIX ?= output

.PHONY: build clean libtestlib

build: libtestlib $(PREFIX)/x86_64-unknown-cosmo/bin/addtest.com

clean:
	rm -rf $(PREFIX)

%/:
	mkdir -p $@


# Headers
$(PREFIX)/x86_64-unknown-linux-gnu/include/testlib.h: src/testlib.h | $(PREFIX)/x86_64-unknown-linux-gnu/include/
	cp --update $< $@


# Shared libaries
$(PREFIX)/x86_64-unknown-linux-gnu/lib/libtestlib.so: src/testlib.c | $(PREFIX)/x86_64-unknown-linux-gnu/lib/
	$(LINUXCC) --shared -fpic -o $@ $< -lm


# Executables
$(PREFIX)/x86_64-unknown-cosmo/bin/addtest.com: src/addtest.c libtestlib | $(PREFIX)/x86_64-unknown-cosmo/bin/
	$(COSMOCC) -mcosmo -o $@ $(filter %.c,$^) -I$(PREFIX)/x86_64-unknown-linux-gnu/include/


libtestlib: $(PREFIX)/x86_64-unknown-linux-gnu/lib/libtestlib.so $(PREFIX)/x86_64-unknown-linux-gnu/include/testlib.h