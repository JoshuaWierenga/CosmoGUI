# TODO: Prevent first_person_maze.com from rebuilding despite not dependency changes
# TODO: Move raylib into cosmo exec with only glfw/rlgl in shared libary
# TODO: Support using imgui on its own

# Building rlImGui is a bit of a pain currently as it is meant to be above ImGui and raylib
# chmod u+x third_party/rlImGui/premake5
# (cd third_party/rlImGui && ln -s ../imgui imgui && ln -s ../raylib raylib)

IMGUI = third_party/imgui/
RAYLIB = third_party/raylib/
RAYGUI = third_party/raygui/
RAYGAMES = third_party/raylib-games/
RLIMGUI = third_party/rlImGui/
x86_64COSMOOUTPUT = $(OUTPUT)/x86_64-unknown-cosmo/
x86_64GLIBCOUTPUT = $(OUTPUT)/x86_64-unknown-linux-gnu/
x86_64MINGWOUTPUT = $(OUTPUT)/x86_64-pc-windows-gnu/
LIBRAYLIBGEN = $(GENERATED)/libraylib/
LIBRLIMGUIGEN = $(GENERATED)/librlImGui/

LIBRAYLIBSRCDEP = $(LIBRAYLIBGEN)/libraylib.so.cosmowrapper.c $(LIBRAYLIBGEN)/libraylib.so.init.c $(LIBRAYLIBGEN)/libraylib.so.tramp.S
LIBRAYLIBOUTDEP = $(x86_64GLIBCOUTPUT)/lib/libraylib.so $(x86_64MINGWOUTPUT)/lib/libraylib.dll
LIBRLIMGUISRCDEP = $(LIBRLIMGUIGEN)/librlImGui.so.cosmowrapper.c $(LIBRLIMGUIGEN)/librlImGui.so.init.c $(LIBRLIMGUIGEN)/librlImGui.so.tramp.S
LIBRLIMGUIOUTDEP = $(x86_64GLIBCOUTPUT)/lib/librlImGui.so $(x86_64MINGWOUTPUT)/lib/librlImGui.dll

RAYLIBDEPS = $(x86_64COSMOOUTPUT)/include/raylib.h $(COMMONDEPS) $(LIBRAYLIBSRCDEP) $(LIBRAYLIBOUTDEP)
RAYLIBCOSMO = -I$(x86_64COSMOOUTPUT)/include/ $(COMMONDEPS) $(LIBRAYLIBSRCDEP)

RLIMGUIDEPS = $(x86_64COSMOOUTPUT)/include/imconfig.h $(x86_64COSMOOUTPUT)/include/imgui.h $(x86_64COSMOOUTPUT)/include/raylib.h $(x86_64COSMOOUTPUT)/include/rlImGui.h $(x86_64COSMOOUTPUT)/include/extras/IconsFontAwesome6.h $(COMMONDEPS) $(LIBRLIMGUISRCDEP) $(LIBRLIMGUIOUTDEP)
RLIMGUICOSMO = -I$(x86_64COSMOOUTPUT)/include/ $(COMMONDEPS) $(LIBRLIMGUISRCDEP)

RAYLIBZIP = zip -jq $@ $(LIBRAYLIBOUTDEP)
RLIMGUIZIP = zip -jq $@ $(LIBRLIMGUIOUTDEP)

.PHONY: raylibbuild

raylibbuild: $(x86_64COSMOOUTPUT)/bin/shapes_basic_shapes.com $(x86_64COSMOOUTPUT)/bin/core_3d_camera_split_screen.com $(x86_64COSMOOUTPUT)/bin/controls_test_suite.com $(x86_64COSMOOUTPUT)/bin/snake.com $(x86_64COSMOOUTPUT)/bin/first_person_maze.com $(x86_64COSMOOUTPUT)/bin/rlimgui_simple.com $(x86_64COSMOOUTPUT)/bin/rlimgui_editor.com


# Headers
$(x86_64COSMOOUTPUT)/include/ray%.h: | $(x86_64COSMOOUTPUT)/include/
	cp --update $(RAYLIB)/src/$(notdir $@) $@

$(x86_64COSMOOUTPUT)/include/im%.h: | $(x86_64COSMOOUTPUT)/include/
	cp --update $(IMGUI)/$(notdir $@) $@

$(x86_64COSMOOUTPUT)/include/rl%.h: | $(x86_64COSMOOUTPUT)/include/
	cp --update $(RLIMGUI)/$(notdir $@) $@

$(x86_64COSMOOUTPUT)/include/extras/IconsFontAwesome6.h: | $(x86_64COSMOOUTPUT)/include/extras/
	cp --update $(RLIMGUI)/extras/IconsFontAwesome6.h $@


# Generated files
$(LIBRAYLIBGEN)/libraylib.so.cosmowrapper.c $(LIBRAYLIBGEN)/libraylib.so.init.c $(LIBRAYLIBGEN)/libraylib.so.cosmowrapper.h $(LIBRAYLIBGEN)/libraylib.so.tramp.S &: $(x86_64GLIBCOUTPUT)/lib/libraylib.so $(x86_64GLIBCOUTPUT)/bin/ctags $(x86_64COSMOOUTPUT)/include/raylib.h | $(LIBRAYLIBGEN)/
	$(PYTHON) third_party/Implib.so/implib-gen.py $< -o $(LIBRAYLIBGEN)/ --dlopen-callback cosmo_dlopen_wrapper --dlsym-callback cosmo_dlsym_wrapper --library-load-name libraylib.so --symbol-prefix real_ --ctags $(x86_64GLIBCOUTPUT)/bin/ctags --input-headers $(x86_64COSMOOUTPUT)/include/raylib.h

$(LIBRLIMGUIGEN)/librlImGui.so.cosmowrapper.c $(LIBRLIMGUIGEN)/librlImGui.so.init.c $(LIBRLIMGUIGEN)/librlImGui.so.cosmowrapper.h $(LIBRLIMGUIGEN)/librlImGui.so.tramp.S &: $(x86_64GLIBCOUTPUT)/lib/librlImGui.so $(x86_64GLIBCOUTPUT)/bin/ctags $(x86_64COSMOOUTPUT)/include/imgui.h $(x86_64COSMOOUTPUT)/include/raylib.h $(x86_64COSMOOUTPUT)/include/rlImGui.h | $(LIBRLIMGUIGEN)/
	$(PYTHON) third_party/Implib.so/implib-gen.py $< -o $(LIBRLIMGUIGEN)/ --dlopen-callback cosmo_dlopen_wrapper --dlsym-callback cosmo_dlsym_wrapper --symbol-prefix real_ --ctags $(x86_64GLIBCOUTPUT)/bin/ctags --input-headers $(x86_64COSMOOUTPUT)/include/imgui.h $(x86_64COSMOOUTPUT)/include/raylib.h $(x86_64COSMOOUTPUT)/include/rlImGui.h


# Shared libaries
$(x86_64GLIBCOUTPUT)/lib/libraylib.so: $(x86_64GLIBCOUTPUT)/lib/libraylib.a | $(x86_64GLIBCOUTPUT)/lib/
	$(x86_64GLIBCC++) --shared -fPIC -o $@ -Wl,--whole-archive $^ -Wl,--no-whole-archive

$(x86_64MINGWOUTPUT)/lib/libraylib.dll: $(x86_64MINGWOUTPUT)/lib/libraylib.a | $(x86_64MINGWOUTPUT)/lib/
	$(x86_64MINGWC++) --shared -fPIC -o $@ -Wl,--whole-archive $^ -Wl,--no-whole-archive -lgdi32 -lwinmm

$(x86_64GLIBCOUTPUT)/lib/librlImGui.so: $(x86_64GLIBCOUTPUT)/lib/libraylib.a $(x86_64GLIBCOUTPUT)/lib/librlImGui.a | $(x86_64GLIBCOUTPUT)/lib/
	$(x86_64GLIBCC++) --shared -fPIC -o $@ -Wl,--whole-archive $^ -Wl,--no-whole-archive

$(x86_64MINGWOUTPUT)/lib/librlImGui.dll: $(x86_64MINGWOUTPUT)/lib/libraylib.a $(x86_64MINGWOUTPUT)/lib/librlImGui.a | $(x86_64MINGWOUTPUT)/lib/
	$(x86_64MINGWC++) --shared -fPIC -o $@ -Wl,--whole-archive $^ -Wl,--no-whole-archive -lgdi32 -lwinmm


# Static libaries
# None of these actually depend on each other but cannot be built at the same time due to building in-tree
$(x86_64GLIBCOUTPUT)/lib/libraylib.a: | $(x86_64GLIBCOUTPUT)/lib/
	$(MAKE) -C $(RAYLIB)/src clean
	$(MAKE) -C $(RAYLIB)/src CC=$(x86_64GLIBCCC) PLATFORM=PLATFORM_DESKTOP PLATFORM_OS=LINUX RAYLIB_LIBTYPE=STATIC
	cp --update $(RAYLIB)/src/libraylib.a $@

$(x86_64MINGWOUTPUT)/lib/libraylib.a: $(x86_64GLIBCOUTPUT)/lib/libraylib.a | $(x86_64MINGWOUTPUT)/lib/
	$(MAKE) -C $(RAYLIB)/src clean
	$(MAKE) -C $(RAYLIB)/src CC=$(x86_64MINGWCC) PLATFORM=PLATFORM_DESKTOP PLATFORM_OS=WINDOWS RAYLIB_LIBTYPE=STATIC
	cp --update $(RAYLIB)/src/libraylib.a $@

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


# Executables
$(x86_64COSMOOUTPUT)/bin/shapes_basic_shapes.com: $(RAYLIB)/examples/shapes/shapes_basic_shapes.c $(RAYLIBDEPS) | $(x86_64COSMOOUTPUT)/bin/
	$(x86_64COSMOCC) -o $@ $< $(RAYLIBCOSMO)
	$(RAYLIBZIP)

$(x86_64COSMOOUTPUT)/bin/core_3d_camera_split_screen.com: $(RAYLIB)/examples/core/core_3d_camera_split_screen.c $(RAYLIBDEPS) | $(x86_64COSMOOUTPUT)/bin/
	$(x86_64COSMOCC) -o $@ $< $(RAYLIBCOSMO)
	$(RAYLIBZIP)

$(x86_64COSMOOUTPUT)/bin/controls_test_suite.com: $(RAYGUI)/examples/controls_test_suite/controls_test_suite.c src/raylib_varargs_fix.c $(RAYLIBDEPS) | $(x86_64COSMOOUTPUT)/bin/
	$(x86_64COSMOCC) -o $@ $< $(word 2,$^) $(RAYLIBCOSMO)
	$(RAYLIBZIP)

$(x86_64COSMOOUTPUT)/bin/snake.com: $(RAYGAMES)/classics/src/snake.c $(RAYLIBDEPS) | $(x86_64COSMOOUTPUT)/bin/
	$(x86_64COSMOCC) -o $@ $< $(RAYLIBCOSMO)
	$(RAYLIBZIP)

$(x86_64COSMOOUTPUT)/bin/first_person_maze.com $(x86_64COSMOOUTPUT)/bin/resources/cubicmap.png $(x86_64COSMOOUTPUT)/bin/resources/cubicmap_atlas.png &: $(RAYLIB)/examples/models/models_first_person_maze.c $(RAYLIBDEPS) | $(x86_64COSMOOUTPUT)/bin/ $(x86_64COSMOOUTPUT)/bin/resources/
	$(x86_64COSMOCC) -o $@ $< $(RAYLIBCOSMO)
	$(RAYLIBZIP)
	cp --update $(RAYLIB)/examples/models/resources/cubicmap.png $(RAYLIB)/examples/models/resources/cubicmap_atlas.png $(x86_64COSMOOUTPUT)/bin/resources/

$(x86_64COSMOOUTPUT)/bin/rlimgui_simple.com: $(RLIMGUI)/examples/simple.cpp $(x86_64COSMOOUTPUT)/include/raymath.h $(RLIMGUIDEPS) | $(x86_64COSMOOUTPUT)/bin/
	$(x86_64COSMOC++) -o $@ $< $(RLIMGUICOSMO)
	$(RLIMGUIZIP)

$(x86_64COSMOOUTPUT)/bin/rlimgui_editor.com $(x86_64COSMOOUTPUT)/bin/resources/parrots.png &: $(RLIMGUI)/examples/editor.cpp src/raylib_varargs_fix.c $(x86_64COSMOOUTPUT)/include/raymath.h $(x86_64COSMOOUTPUT)/include/rlImGuiColors.h $(RLIMGUIDEPS) | $(x86_64COSMOOUTPUT)/bin/ $(x86_64COSMOOUTPUT)/bin/resources/
	$(x86_64COSMOC++) -o $@ $< $(word 2,$^) $(RLIMGUICOSMO)
	$(RLIMGUIZIP)
	cp --update $(RLIMGUI)/resources/parrots.png $(x86_64COSMOOUTPUT)/bin/resources/parrots.png
