# TODO: Use pointers instead of structs for wrapper returns
# TODO: Prevent first_person_maze.com from rebuilding despite not dependency changes
# TODO: Remove need for building shared libraries for Implib.so when using static libraries, rlImGui already does not use one
# TODO: Move raylib into cosmo exec with only glfw in wrapper libraries
# TODO: Support Windows building?
# TODO: Allow using a windows console if desired
# TODO: Support aarch64 for Linux and MacOS
# TODO: Support FreeBSD and NetBSD
# TODO: Ensure Musl Libc works
# TODO: Replace dlopen with custom ipc for x86-64 OpenBSD and MacOS?
# TODO: Support using imgui on its own

# Building rlImGui is a bit of a pain currently as it is meant to be above ImGui and raylib
# chmod u+x third_party/rlImGui/premake5
# (cd third_party/rlImGui && ln -s ../imgui imgui && ln -s ../raylib raylib)

x86_64COSMOAR ?= x86_64-unknown-cosmo-ar
x86_64COSMOCC ?= x86_64-unknown-cosmo-cc
x86_64COSMOC++ ?= x86_64-unknown-cosmo-c++
x86_64GLIBCCC ?= gcc
x86_64GLIBCC++ ?= g++
x86_64MINGWCC ?= x86_64-w64-mingw32-gcc
x86_64MINGWC++ ?= x86_64-w64-mingw32-g++

PYTHON ?= python3

OUTPUT ?= output/
GENERATED ?= src/generated/

IMGUI = third_party/imgui/
RAYLIB = third_party/raylib/
RAYGUI = third_party/raygui/
RAYGAMES = third_party/raylib-games/
RLIMGUI = third_party/rlImGui/
x86_64COSMOOUTPUT = $(OUTPUT)/x86_64-unknown-cosmo/
x86_64GLIBCOUTPUT = $(OUTPUT)/x86_64-unknown-linux-gnu/
x86_64MINGWOUTPUT = $(OUTPUT)/x86_64-pc-windows-gnu/
LIBRAYLIBGEN = $(GENERATED)/libraylib/
LIBRAYLIBWRAPPERGEN = $(GENERATED)/libraylib_wrapper/
LIBRLIMGUIGEN = $(GENERATED)/librlImGui/
LIBRLIMGUIWRAPPERGEN = $(GENERATED)/librlImGui_wrapper/

RAYLIBDEPS = $(x86_64COSMOOUTPUT)/include/raylib.h $(x86_64COSMOOUTPUT)/lib/libraylib_wrapper.a $(x86_64GLIBCOUTPUT)/lib/libraylib_wrapper.so $(x86_64MINGWOUTPUT)/lib/libraylib_wrapper.dll
RAYLIBCOSMO = -I$(x86_64COSMOOUTPUT)/include/ -L$(x86_64COSMOOUTPUT)/lib/ -lraylib_wrapper
RLIMGUIDEPS = $(x86_64COSMOOUTPUT)/include/imconfig.h $(x86_64COSMOOUTPUT)/include/imgui.h $(x86_64COSMOOUTPUT)/include/rlImGui.h $(x86_64COSMOOUTPUT)/lib/librlImGui_wrapper.a $(x86_64GLIBCOUTPUT)/lib/librlImGui_wrapper.so $(x86_64MINGWOUTPUT)/lib/librlImGui_wrapper.dll
RLIMGUICOSMO = -I$(x86_64COSMOOUTPUT)/include/ -L$(x86_64COSMOOUTPUT)/lib/ -lrlImGui_wrapper

RAYLIBZIP = zip -jq $@ $(x86_64GLIBCOUTPUT)/lib/libraylib_wrapper.so $(x86_64MINGWOUTPUT)/lib/libraylib_wrapper.dll
RLIMGUIZIP = zip -jq $@ $(x86_64GLIBCOUTPUT)/lib/librlImGui_wrapper.so $(x86_64MINGWOUTPUT)/lib/librlImGui_wrapper.dll

.PHONY: build clean

build: $(x86_64COSMOOUTPUT)/bin/shapes_basic_shapes.com $(x86_64COSMOOUTPUT)/bin/core_3d_camera_split_screen.com $(x86_64COSMOOUTPUT)/bin/controls_test_suite.com $(x86_64COSMOOUTPUT)/bin/snake.com $(x86_64COSMOOUTPUT)/bin/first_person_maze.com $(x86_64COSMOOUTPUT)/bin/rlimgui_simple.com

clean:
	rm -rf $(OUTPUT)/ $(GENERATED)/

%/:
	mkdir -p $@


# Headers
$(x86_64COSMOOUTPUT)/include/ray%.h: | $(x86_64COSMOOUTPUT)/include/
	cp --update $(RAYLIB)/src/$(notdir $@) $@

$(GENERATED)/raylib.h: $(x86_64COSMOOUTPUT)/include/raylib.h | $(GENERATED)/
	$(x86_64GLIBCCC) -E -o $@ $<

$(x86_64COSMOOUTPUT)/include/im%.h: | $(x86_64COSMOOUTPUT)/include/
	cp --update $(IMGUI)/$(notdir $@) $@

$(GENERATED)/imgui.h: $(x86_64COSMOOUTPUT)/include/imgui.h | $(GENERATED)/
	$(x86_64GLIBCCC) -E -o $@ $<

$(x86_64COSMOOUTPUT)/include/rl%.h: | $(x86_64COSMOOUTPUT)/include/
	cp --update $(RLIMGUI)/$(notdir $@) $@

$(x86_64COSMOOUTPUT)/include/extras/IconsFontAwesome6.h: | $(x86_64COSMOOUTPUT)/include/extras/
	cp --update $(RLIMGUI)/extras/IconsFontAwesome6.h $@

# Generated files
$(LIBRAYLIBGEN)/libraylib.so.cosmowrapper.c $(LIBRAYLIBGEN)/libraylib.so.headerwrapper.h $(LIBRAYLIBGEN)/libraylib.so.nativewrapper.c &: $(x86_64GLIBCOUTPUT)/lib/libraylib.so $(x86_64GLIBCOUTPUT)/bin/ctags $(GENERATED)/raylib.h | $(LIBRAYLIBGEN)/
	$(PYTHON) third_party/Implib.so/implib-gen.py $< -o $(LIBRAYLIBGEN)/ --ctags $(x86_64GLIBCOUTPUT)/bin/ctags --input-headers $(GENERATED)/raylib.h
	rm $(LIBRAYLIBGEN)/libraylib.so.init.c $(LIBRAYLIBGEN)/libraylib.so.tramp.S

$(LIBRAYLIBWRAPPERGEN)/libraylib_wrapper.so.init.c $(LIBRAYLIBWRAPPERGEN)/libraylib_wrapper.so.tramp.S &: $(x86_64GLIBCOUTPUT)/lib/libraylib_wrapper_temp.so | $(LIBRAYLIBWRAPPERGEN)/
	$(PYTHON) third_party/Implib.so/implib-gen.py $< -o $(LIBRAYLIBWRAPPERGEN)/ --dlopen-callback cosmo_dlopen_wrapper --dlsym-callback cosmo_dlsym --library-load-name libraylib_wrapper.so
	mv --update $(LIBRAYLIBWRAPPERGEN)/libraylib_wrapper_temp.so.tramp.S $(LIBRAYLIBWRAPPERGEN)/libraylib_wrapper.so.tramp.S
	mv --update $(LIBRAYLIBWRAPPERGEN)/libraylib_wrapper_temp.so.init.c $(LIBRAYLIBWRAPPERGEN)/libraylib_wrapper.so.init.c

$(LIBRLIMGUIGEN)/librlImGui.a.cosmowrapper.c $(LIBRLIMGUIGEN)/librlImGui.a.headerwrapper.h $(LIBRLIMGUIGEN)/librlImGui.a.nativewrapper.c &: $(x86_64GLIBCOUTPUT)/lib/librlImGui.a $(x86_64GLIBCOUTPUT)/bin/ctags $(x86_64COSMOOUTPUT)/include/imconfig.h $(GENERATED)/imgui.h $(x86_64COSMOOUTPUT)/include/extras/IconsFontAwesome6.h $(x86_64COSMOOUTPUT)/include/rlImGui.h | $(LIBRLIMGUIGEN)/
	$(PYTHON) third_party/Implib.so/implib-gen.py $< -o $(LIBRLIMGUIGEN)/ --ctags $(x86_64GLIBCOUTPUT)/bin/ctags --input-headers $(GENERATED)/imgui.h $(x86_64COSMOOUTPUT)/include/rlImGui.h
	rm $(LIBRLIMGUIGEN)/librlImGui.a.init.c $(LIBRLIMGUIGEN)/librlImGui.a.tramp.S

$(LIBRLIMGUIWRAPPERGEN)/librlImGui_wrapper.so.init.c $(LIBRLIMGUIWRAPPERGEN)/librlImGui_wrapper.so.tramp.S &: $(x86_64GLIBCOUTPUT)/lib/librlImGui_wrapper_temp.so | $(LIBRLIMGUIWRAPPERGEN)/
	$(PYTHON) third_party/Implib.so/implib-gen.py $< -o $(LIBRLIMGUIWRAPPERGEN)/ --dlopen-callback cosmo_dlopen_wrapper --dlsym-callback cosmo_dlsym --library-load-name librlImGui_wrapper.so
	mv --update $(LIBRLIMGUIWRAPPERGEN)/librlImGui_wrapper_temp.so.tramp.S $(LIBRLIMGUIWRAPPERGEN)/librlImGui_wrapper.so.tramp.S
	mv --update $(LIBRLIMGUIWRAPPERGEN)/librlImGui_wrapper_temp.so.init.c $(LIBRLIMGUIWRAPPERGEN)/librlImGui_wrapper.so.init.c

# Shared libaries
$(x86_64GLIBCOUTPUT)/lib/libraylib.so: | $(x86_64GLIBCOUTPUT)/lib/
	$(MAKE) -C $(RAYLIB)/src clean
	$(MAKE) -C $(RAYLIB)/src CC=$(x86_64GLIBCCC) PLATFORM=PLATFORM_DESKTOP PLATFORM_OS=LINUX RAYLIB_LIBTYPE=SHARED
	cp --update $(RAYLIB)/src/libraylib.so* $(dir $@)

$(x86_64GLIBCOUTPUT)/lib/libraylib_wrapper_temp.so: $(LIBRAYLIBGEN)/libraylib.so.nativewrapper.c $(x86_64COSMOOUTPUT)/include/raylib.h | $(x86_64GLIBCOUTPUT)/lib/
	$(x86_64GLIBCCC) --shared -fpic -o $@ $< -I$(x86_64COSMOOUTPUT)/include/

$(x86_64GLIBCOUTPUT)/lib/libraylib_wrapper.so: $(LIBRAYLIBGEN)/libraylib.so.nativewrapper.c $(x86_64COSMOOUTPUT)/include/raylib.h $(x86_64GLIBCOUTPUT)/lib/libraylib.a | $(x86_64GLIBCOUTPUT)/lib/
	$(x86_64GLIBCCC) --shared -fpic -o $@ $< -I$(x86_64COSMOOUTPUT)/include/ -L$(x86_64GLIBCOUTPUT)/lib/ -l:libraylib.a

$(x86_64MINGWOUTPUT)/lib/libraylib_wrapper.dll: $(LIBRAYLIBGEN)/libraylib.so.nativewrapper.c $(x86_64COSMOOUTPUT)/include/raylib.h $(x86_64MINGWOUTPUT)/lib/libraylib.a | $(x86_64MINGWOUTPUT)/lib/
	$(x86_64MINGWCC) --shared -fpic -o $@ $< -I$(x86_64COSMOOUTPUT)/include/ -L$(x86_64MINGWOUTPUT)/lib/ -lraylib -lgdi32 -lwinmm

$(x86_64GLIBCOUTPUT)/lib/librlImGui_wrapper_temp.so: $(LIBRLIMGUIGEN)/librlImGui.a.nativewrapper.c $(x86_64COSMOOUTPUT)/include/rlImGui.h $(x86_64COSMOOUTPUT)/include/raylib.h $(x86_64GLIBCOUTPUT)/lib/libraylib_nativewrapper.o | $(x86_64GLIBCOUTPUT)/lib/
	$(x86_64GLIBCC++) --shared -fpic -o $@ $< -I$(x86_64COSMOOUTPUT)/include/ -L$(x86_64GLIBCOUTPUT)/lib/ -l:libraylib_nativewrapper.o

$(x86_64GLIBCOUTPUT)/lib/librlImGui_wrapper.so &: $(LIBRLIMGUIGEN)/librlImGui.a.nativewrapper.c $(x86_64COSMOOUTPUT)/include/rlImGui.h $(x86_64GLIBCOUTPUT)/lib/libraylib_nativewrapper.o $(x86_64GLIBCOUTPUT)/lib/libraylib.a $(x86_64GLIBCOUTPUT)/lib/librlImGui.a | $(x86_64GLIBCOUTPUT)/lib/
	$(x86_64GLIBCC++) --shared -fpic -o $@ $< -I$(x86_64COSMOOUTPUT)/include/ -L$(x86_64GLIBCOUTPUT)/lib/ -l:libraylib_nativewrapper.o -l:libraylib.a -lrlImGui

$(x86_64MINGWOUTPUT)/lib/librlImGui_wrapper.dll: $(LIBRLIMGUIGEN)/librlImGui.a.nativewrapper.c $(x86_64COSMOOUTPUT)/include/rlImGui.h $(x86_64MINGWOUTPUT)/lib/libraylib_nativewrapper.o $(x86_64MINGWOUTPUT)/lib/libraylib.a $(x86_64MINGWOUTPUT)/lib/librlImGui.a | $(x86_64MINGWOUTPUT)/lib/
	$(x86_64MINGWC++) --shared -fpic -o $@ $< -I$(x86_64COSMOOUTPUT)/include/ -L$(x86_64MINGWOUTPUT)/lib/ -l:libraylib_nativewrapper.o -lraylib -lrlImGui -lgdi32 -lwinmm


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

$(x86_64GLIBCOUTPUT)/lib/libraylib_nativewrapper.o: $(LIBRAYLIBGEN)/libraylib.so.nativewrapper.c $(x86_64COSMOOUTPUT)/include/raylib.h | $(x86_64GLIBCOUTPUT)/lib/
	$(x86_64GLIBCCC) -fpic -c -o $(x86_64GLIBCOUTPUT)/lib/libraylib_nativewrapper.o $(LIBRAYLIBGEN)/libraylib.so.nativewrapper.c -I$(x86_64COSMOOUTPUT)/include/

$(x86_64MINGWOUTPUT)/lib/libraylib_nativewrapper.o: $(LIBRAYLIBGEN)/libraylib.so.nativewrapper.c $(x86_64COSMOOUTPUT)/include/raylib.h | $(x86_64MINGWOUTPUT)/lib/
	$(x86_64MINGWCC) -fpic -c -o $(x86_64MINGWOUTPUT)/lib/libraylib_nativewrapper.o $(LIBRAYLIBGEN)/libraylib.so.nativewrapper.c -I$(x86_64COSMOOUTPUT)/include/

$(x86_64GLIBCOUTPUT)/lib/librlImGui.a: | $(x86_64GLIBCOUTPUT)/lib/
	rm -rf $(RLIMGUI)/_build/
	(cd $(RLIMGUI)/ && ./premake5 gmake2)
	$(MAKE) -C $(RLIMGUI)/ rlImGui CXX=$(x86_64GLIBCC++) CPPFLAGS=-fPIC config=release_x64
	cp $(RLIMGUI)/_bin/Release/librlImGui.a $@

$(x86_64MINGWOUTPUT)/lib/librlImGui.a: $(x86_64GLIBCOUTPUT)/lib/librlImGui.a | $(x86_64MINGWOUTPUT)/lib/
	rm -rf $(RLIMGUI)/_build/
	(cd $(RLIMGUI)/ && ./premake5 gmake2)
	$(MAKE) -C $(RLIMGUI)/ rlImGui CXX=$(x86_64MINGWC++) CPPFLAGS=-fPIC config=release_x64
	cp $(RLIMGUI)/_bin/Release/librlImGui.a $@

$(x86_64COSMOOUTPUT)/lib/cosmo_gui_setup.o: src/cosmo_gui_setup.c | $(x86_64COSMOOUTPUT)/lib/
	$(x86_64COSMOCC) -mcosmo -c -o $(x86_64COSMOOUTPUT)/lib/cosmo_gui_setup.o src/cosmo_gui_setup.c -DDISABLECONSOLE

$(x86_64COSMOOUTPUT)/lib/libraylib_wrapper.o: $(LIBRAYLIBGEN)/libraylib.so.cosmowrapper.c $(x86_64COSMOOUTPUT)/include/raylib.h | $(x86_64COSMOOUTPUT)/lib/
	$(x86_64COSMOCC) -mcosmo -c -o $(x86_64COSMOOUTPUT)/lib/libraylib_wrapper.o $(LIBRAYLIBGEN)/libraylib.so.cosmowrapper.c -I$(x86_64COSMOOUTPUT)/include/

$(x86_64COSMOOUTPUT)/lib/libraylib_wrapper.a: $(LIBRAYLIBWRAPPERGEN)/libraylib_wrapper.so.init.c $(LIBRAYLIBWRAPPERGEN)/libraylib_wrapper.so.tramp.S $(x86_64COSMOOUTPUT)/lib/cosmo_gui_setup.o $(x86_64COSMOOUTPUT)/lib/libraylib_wrapper.o | $(x86_64COSMOOUTPUT)/lib/
	$(x86_64COSMOCC) -c -o $(x86_64COSMOOUTPUT)/lib/libraylib_wrapper_init.o $(LIBRAYLIBWRAPPERGEN)/libraylib_wrapper.so.init.c
	$(x86_64COSMOCC) -c -o $(x86_64COSMOOUTPUT)/lib/libraylib_wrapper_tramp.o $(LIBRAYLIBWRAPPERGEN)/libraylib_wrapper.so.tramp.S
	$(x86_64COSMOAR) rcs $@ $(x86_64COSMOOUTPUT)/lib/cosmo_gui_setup.o $(x86_64COSMOOUTPUT)/lib/libraylib*.o
	rm $(x86_64COSMOOUTPUT)/lib/libraylib_wrapper_*.o

$(x86_64COSMOOUTPUT)/lib/librlImGui_wrapper.a: $(LIBRLIMGUIGEN)/librlImGui.a.cosmowrapper.c $(LIBRLIMGUIWRAPPERGEN)/librlImGui_wrapper.so.init.c $(LIBRLIMGUIWRAPPERGEN)/librlImGui_wrapper.so.tramp.S $(x86_64COSMOOUTPUT)/include/imgui.h $(x86_64COSMOOUTPUT)/lib/cosmo_gui_setup.o $(x86_64COSMOOUTPUT)/lib/libraylib_wrapper.o | $(x86_64COSMOOUTPUT)/lib/
	$(x86_64COSMOC++) -c -o $(x86_64COSMOOUTPUT)/lib/librlImGui_wrapper.o $(LIBRLIMGUIGEN)/librlImGui.a.cosmowrapper.c -I$(x86_64COSMOOUTPUT)/include/
	$(x86_64COSMOCC) -c -o $(x86_64COSMOOUTPUT)/lib/librlImGui_wrapper_init.o $(LIBRLIMGUIWRAPPERGEN)/librlImGui_wrapper.so.init.c
	$(x86_64COSMOCC) -c -o $(x86_64COSMOOUTPUT)/lib/librlImGui_wrapper_tramp.o $(LIBRLIMGUIWRAPPERGEN)/librlImGui_wrapper.so.tramp.S
	$(x86_64COSMOAR) rcs $@ $(x86_64COSMOOUTPUT)/lib/cosmo_gui_setup.o $(x86_64COSMOOUTPUT)/lib/libraylib_wrapper.o $(x86_64COSMOOUTPUT)/lib/librlImGui*.o
	rm $(x86_64COSMOOUTPUT)/lib/librlImGui*.o


# Executables
$(x86_64GLIBCOUTPUT)/bin/ctags: | $(x86_64GLIBCOUTPUT)/bin/
	cd third_party/ctags && ./autogen.sh && ./configure --prefix $(PWD)/$(x86_64GLIBCOUTPUT)/
	$(MAKE) -C third_party/ctags install

$(x86_64COSMOOUTPUT)/bin/shapes_basic_shapes.com: $(RAYLIB)/examples/shapes/shapes_basic_shapes.c $(RAYLIBDEPS) | $(x86_64COSMOOUTPUT)/bin/
	$(x86_64COSMOCC) -o $@ $< $(RAYLIBCOSMO)
	$(RAYLIBZIP)

$(x86_64COSMOOUTPUT)/bin/core_3d_camera_split_screen.com: $(RAYLIB)/examples/core/core_3d_camera_split_screen.c $(RAYLIBDEPS) | $(x86_64COSMOOUTPUT)/bin/
	$(x86_64COSMOCC) -o $@ $< $(RAYLIBCOSMO)
	$(RAYLIBZIP)

$(x86_64COSMOOUTPUT)/bin/controls_test_suite.com: $(RAYGUI)/examples/controls_test_suite/controls_test_suite.c src/raygui_fix.c $(RAYLIBDEPS) | $(x86_64COSMOOUTPUT)/bin/
	$(x86_64COSMOCC) -o $@ $< $(word 2,$^) $(RAYLIBCOSMO)
	$(RAYLIBZIP)

$(x86_64COSMOOUTPUT)/bin/snake.com: $(RAYGAMES)/classics/src/snake.c $(RAYLIBDEPS) | $(x86_64COSMOOUTPUT)/bin/
	$(x86_64COSMOCC) -o $@ $< $(RAYLIBCOSMO)
	$(RAYLIBZIP)

$(x86_64COSMOOUTPUT)/bin/first_person_maze.com $(x86_64COSMOOUTPUT)/bin/resources/cubicmap.png $(x86_64COSMOOUTPUT)/bin/resources/cubicmap_atlas.png &: $(RAYLIB)/examples/models/models_first_person_maze.c $(RAYLIBDEPS) | $(x86_64COSMOOUTPUT)/bin/resources/
	$(x86_64COSMOCC) -o $@ $< $(RAYLIBCOSMO)
	$(RAYLIBZIP)
	cp --update $(RAYLIB)/examples/models/resources/cubicmap.png $(RAYLIB)/examples/models/resources/cubicmap_atlas.png $(x86_64COSMOOUTPUT)/bin/resources/

$(x86_64COSMOOUTPUT)/bin/rlimgui_simple.com: $(RLIMGUI)/examples/simple.cpp $(x86_64COSMOOUTPUT)/include/raymath.h $(RLIMGUIDEPS) | $(x86_64COSMOOUTPUT)/bin/
	$(x86_64COSMOC++) -o $@ $< $(RLIMGUICOSMO)
	$(RLIMGUIZIP)
