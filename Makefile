# TODO: Remove need for building shared libraries for Implib.so when using static libraries, rlImGui already does not use one. Not really possible now, I guess just make sure static libraries work with Implib.so
# TODO: Rewrite extract_lib based on zip.c from llamafile
# TODO: Support c vararg functions, use macro functions?
# TODO: Support Windows building?
# TODO: Allow using a windows console if desired
# TODO: Support aarch64 for Linux and MacOS
# TODO: Support FreeBSD and NetBSD
# TODO: Ensure Musl Libc works
# TODO: Replace dlopen with custom ipc for x86-64 OpenBSD and MacOS?

x86_64COSMOCC ?= x86_64-unknown-cosmo-cc
x86_64COSMOC++ ?= x86_64-unknown-cosmo-c++
x86_64GLIBCCC ?= gcc
x86_64GLIBCC++ ?= g++
x86_64MINGWCC ?= x86_64-w64-mingw32-gcc
x86_64MINGWC++ ?= x86_64-w64-mingw32-g++

PYTHON ?= python3

OUTPUT ?= output/
GENERATED ?= src/generated/

COMMONDEPS = $(x86_64COSMOOUTPUT)/lib/cosmo_gui_setup.o

.PHONY: build clean

build: raylibbuild

clean:
	rm -rf $(OUTPUT)/ $(GENERATED)/

%/:
	mkdir -p $@

include raylib.mk


# Static libaries
$(x86_64COSMOOUTPUT)/lib/cosmo_gui_setup.o: src/cosmo_gui_setup.c | $(x86_64COSMOOUTPUT)/lib/
	$(x86_64COSMOCC) -mcosmo -c -o $(x86_64COSMOOUTPUT)/lib/cosmo_gui_setup.o src/cosmo_gui_setup.c -DDISABLECONSOLE


# Executables
$(x86_64GLIBCOUTPUT)/bin/ctags: | $(x86_64GLIBCOUTPUT)/bin/
	cd third_party/ctags && ./autogen.sh && ./configure --prefix $(PWD)/$(x86_64GLIBCOUTPUT)/
	$(MAKE) -C third_party/ctags install
