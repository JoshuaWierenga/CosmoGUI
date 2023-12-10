# TODO: Use pointers instead of structs for wrapper returns
# TODO: Pack wrapper libraries into zipos
# TODO: Prevent first_person_maze.com from rebuilding despite not dependency changes
# TODO: Move raylib into cosmo exec with only glfw in wrapper libraries
# TODO: Support Windows building?
# TODO: Allow using a windows console if desired
# TODO: Support aarch64 for Linux and MacOS
# TODO: Support FreeBSD and NetBSD
# TODO: Ensure Musl Libc works
# TODO: Replace dlopen with custom ipc for x86-64 OpenBSD and MacOS?

# For Linux, libraylib_wrapper.so from $(x86_64GLIBCOUTPUT)/bin/ can either be in the same folder
# as the com file or in folder that is in LD_LIBRARY_PATH.
# For Windows, libraylib_wrapper.dll from $(x86_64MINGWOUTPUT)/lib/ needs to be in the same folder.

x86_64COSMOCC ?= x86_64-unknown-cosmo-cc
x86_64GLIBCCC ?= gcc
x86_64MINGWCC ?= x86_64-w64-mingw32-gcc

PYTHON ?= python3

OUTPUT ?= output/
GENERATED ?= src/generated/

RAYLIB = third_party/raylib/
RAYGUI = third_party/raygui/
RAYGAMES = third_party/raylib-games/
x86_64COSMOOUTPUT = $(OUTPUT)/x86_64-unknown-cosmo/
x86_64GLIBCOUTPUT = $(OUTPUT)/x86_64-unknown-linux-gnu/
x86_64MINGWOUTPUT = $(OUTPUT)/x86_64-pc-windows-gnu/
LIBRAYLIBGEN = $(GENERATED)/libraylib/
LIBRAYLIBWRAPPERGEN = $(GENERATED)/libraylib_wrapper/

RAYLIBCOSMOCC = $(x86_64COSMOCC) -mcosmo src/cosmo_gui_setup.c -I$(x86_64COSMOOUTPUT)/include/ $(LIBRAYLIBGEN)/libraylib.so.cosmowrapper.c $(LIBRAYLIBWRAPPERGEN)/libraylib_wrapper.so.init.c $(LIBRAYLIBWRAPPERGEN)/libraylib_wrapper.so.tramp.S -DDISABLECONSOLE
RAYLIBDEPS = src/cosmo_gui_setup.c $(x86_64COSMOOUTPUT)/include/raylib.h $(LIBRAYLIBGEN)/libraylib.so.cosmowrapper.c $(LIBRAYLIBWRAPPERGEN)/libraylib_wrapper.so.init.c $(LIBRAYLIBWRAPPERGEN)/libraylib_wrapper.so.tramp.S

.PHONY: build clean

build: $(x86_64GLIBCOUTPUT)/lib/libraylib_wrapper.so $(x86_64MINGWOUTPUT)/lib/libraylib_wrapper.dll $(x86_64COSMOOUTPUT)/bin/shapes_basic_shapes.com $(x86_64COSMOOUTPUT)/bin/core_3d_camera_split_screen.com $(x86_64COSMOOUTPUT)/bin/controls_test_suite.com $(x86_64COSMOOUTPUT)/bin/snake.com $(x86_64COSMOOUTPUT)/bin/first_person_maze.com

clean:
	rm -rf $(OUTPUT)/ $(GENERATED)/

%/:
	mkdir -p $@


# Headers
$(x86_64COSMOOUTPUT)/include/raylib.h: | $(x86_64COSMOOUTPUT)/include/
	cp --update $(RAYLIB)/src/raylib.h $@

$(GENERATED)/raylib.h: $(x86_64COSMOOUTPUT)/include/raylib.h | $(GENERATED)/
	$(x86_64GLIBCCC) -E -o $@ $<


# Generated files
$(LIBRAYLIBGEN)/libraylib.so.cosmowrapper.c $(LIBRAYLIBGEN)/libraylib.so.headerwrapper.h $(LIBRAYLIBGEN)/libraylib.so.nativewrapper.c &: $(x86_64GLIBCOUTPUT)/lib/libraylib.so $(x86_64GLIBCOUTPUT)/bin/ctags $(GENERATED)/raylib.h | $(LIBRAYLIBGEN)/
	$(PYTHON) third_party/Implib.so/implib-gen.py $< -o $(LIBRAYLIBGEN)/ --ctags $(x86_64GLIBCOUTPUT)/bin/ctags --input-headers $(GENERATED)/raylib.h --windows-library libraylib_wrapper.dll
	rm $(LIBRAYLIBGEN)/libraylib.so.init.c $(LIBRAYLIBGEN)/libraylib.so.tramp.S

$(LIBRAYLIBWRAPPERGEN)/libraylib_wrapper.so.init.c $(LIBRAYLIBWRAPPERGEN)/libraylib_wrapper.so.tramp.S &: $(x86_64GLIBCOUTPUT)/lib/libraylib_wrapper_temp.so | $(LIBRAYLIBWRAPPERGEN)/
	$(PYTHON) third_party/Implib.so/implib-gen.py $< -o $(LIBRAYLIBWRAPPERGEN)/ --dlopen-callback cosmo_dlopen_wrapper --dlsym-callback cosmo_dlsym
	mv --update $(LIBRAYLIBWRAPPERGEN)/libraylib_wrapper_temp.so.tramp.S $(LIBRAYLIBWRAPPERGEN)/libraylib_wrapper.so.tramp.S
	sed 's/libraylib_wrapper_temp\.so/libraylib_wrapper.so/' $(LIBRAYLIBWRAPPERGEN)/libraylib_wrapper_temp.so.init.c > $(LIBRAYLIBWRAPPERGEN)/libraylib_wrapper.so.init.c
	rm $(LIBRAYLIBWRAPPERGEN)/libraylib_wrapper_temp.so.init.c


# Shared libaries
$(x86_64GLIBCOUTPUT)/lib/libraylib.so: | $(x86_64GLIBCOUTPUT)/lib/
	$(MAKE) -C $(RAYLIB)/src clean
	$(MAKE) -C $(RAYLIB)/src CC=$(x86_64GLIBCCC) PLATFORM=PLATFORM_DESKTOP PLATFORM_OS=LINUX RAYLIB_LIBTYPE=SHARED
	cp --update $(RAYLIB)/src/libraylib.so* $(dir $@)

$(x86_64GLIBCOUTPUT)/lib/libraylib_wrapper_temp.so: $(LIBRAYLIBGEN)/libraylib.so.nativewrapper.c $(GENERATED)/raylib.h | $(x86_64GLIBCOUTPUT)/lib/
	$(x86_64GLIBCCC) --shared -fpic -o $@ $^ -I$(GENERATED)/

$(x86_64GLIBCOUTPUT)/lib/libraylib_wrapper.so: $(LIBRAYLIBGEN)/libraylib.so.nativewrapper.c $(GENERATED)/raylib.h $(x86_64GLIBCOUTPUT)/lib/libraylib.a | $(x86_64GLIBCOUTPUT)/lib/
	$(x86_64GLIBCCC) --shared -fpic -o $@ $^ -I$(GENERATED)/ -L$(x86_64GLIBCOUTPUT)/lib/ -l:libraylib.a -lm

$(x86_64MINGWOUTPUT)/lib/libraylib_wrapper.dll: $(LIBRAYLIBGEN)/libraylib.so.nativewrapper.c $(GENERATED)/raylib.h $(x86_64MINGWOUTPUT)/lib/libraylib.a | $(x86_64MINGWOUTPUT)/lib/
	$(x86_64MINGWCC) --shared -fpic -o $@ $^ -I$(GENERATED)/ -L$(x86_64MINGWOUTPUT)/lib/ -lraylib -lgdi32 -lwinmm


# Static libaries
# These do not actually depend on each other or the shared wrapper but cannot be built at the same time
$(x86_64GLIBCOUTPUT)/lib/libraylib.a: $(x86_64GLIBCOUTPUT)/lib/libraylib.so | $(x86_64GLIBCOUTPUT)/lib/
	$(MAKE) -C $(RAYLIB)/src clean
	$(MAKE) -C $(RAYLIB)/src CC=$(x86_64GLIBCCC) PLATFORM=PLATFORM_DESKTOP PLATFORM_OS=LINUX RAYLIB_LIBTYPE=STATIC
	cp --update $(RAYLIB)/src/libraylib.a $@

$(x86_64MINGWOUTPUT)/lib/libraylib.a: $(x86_64GLIBCOUTPUT)/lib/libraylib.so $(x86_64GLIBCOUTPUT)/lib/libraylib.a | $(x86_64MINGWOUTPUT)/lib/
	$(MAKE) -C $(RAYLIB)/src clean
	$(MAKE) -C $(RAYLIB)/src CC=$(x86_64MINGWCC) PLATFORM=PLATFORM_DESKTOP PLATFORM_OS=WINDOWS RAYLIB_LIBTYPE=STATIC
	cp --update $(RAYLIB)/src/libraylib.a $@


# Executables
$(x86_64GLIBCOUTPUT)/bin/ctags: | $(x86_64GLIBCOUTPUT)/bin/
	cd third_party/ctags && ./autogen.sh && ./configure --prefix $(PWD)/$(x86_64GLIBCOUTPUT)/
	$(MAKE) -C third_party/ctags install

$(x86_64COSMOOUTPUT)/bin/shapes_basic_shapes.com: $(RAYLIB)/examples/shapes/shapes_basic_shapes.c $(RAYLIBDEPS) | $(x86_64COSMOOUTPUT)/bin/
	$(RAYLIBCOSMOCC) -o $@ $<

$(x86_64COSMOOUTPUT)/bin/core_3d_camera_split_screen.com: $(RAYLIB)/examples/core/core_3d_camera_split_screen.c $(RAYLIBDEPS) | $(x86_64COSMOOUTPUT)/bin/
	$(RAYLIBCOSMOCC) -o $@ $<

$(x86_64COSMOOUTPUT)/bin/controls_test_suite.com: $(RAYGUI)/examples/controls_test_suite/controls_test_suite.c src/raygui_fix.c $(RAYLIBDEPS) | $(x86_64COSMOOUTPUT)/bin/
	$(RAYLIBCOSMOCC) -o $@ $< $(word 2,$^)

$(x86_64COSMOOUTPUT)/bin/snake.com: $(RAYGAMES)/classics/src/snake.c $(RAYLIBDEPS) | $(x86_64COSMOOUTPUT)/bin/
	$(RAYLIBCOSMOCC) -o $@ $<

$(x86_64COSMOOUTPUT)/bin/first_person_maze.com $(x86_64COSMOOUTPUT)/bin/resources/cubicmap.png $(x86_64COSMOOUTPUT)/bin/resources/cubicmap_atlas.png &: $(RAYLIB)/examples/models/models_first_person_maze.c $(RAYLIBDEPS) | $(x86_64COSMOOUTPUT)/bin/resources/
	$(RAYLIBCOSMOCC) -o $@ $<
	cp --update $(RAYLIB)/examples/models/resources/cubicmap.png $(RAYLIB)/examples/models/resources/cubicmap_atlas.png $(x86_64COSMOOUTPUT)/bin/resources/
