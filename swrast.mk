# TODO: Fix linux build needing nano-X server to be a seperate program, currently LINK_APP_INTO_SERVER causes crashes
# TODO: Add dos support
# TODO: Remove need for nx11.pc, may not be possible as my patch for mesa ensures it ends up as a requirement in gl.pc
# TODO: Prevent rebuilding nano-X twice during full rebuild even if no changes have been made
# TODO: Check if meson --reconfigure is needed. I think that meson checks for script changes on build and reconfigures are required automatically
# TODO: Modify rebuild check to check for source change since last build instead of change since patch applied
# TODO: Move rebuild checks from shell to make

.PHONY: swrastmingwbuild swrastglibcbuild swrastbuild nanoxclean swrastglibcclean swrastmingwclean swrastclean swrastdistclean
.PHONY: nanoxsetup nanoxglibc nanoxmingw mesasetup mesaglibc mesamingw gluglibc mesademossetup mesademosglibc mesademosmingw

XORGPROTO = third_party/xorgproto/
NANOX = third_party/microwindows/
MESA = third_party/mesa/
# `git rev-parse` only works if the path to the glu submodule is given without a /
GLUGIT = third_party/glu
GLU = $(GLUGIT)/
MESADEMOS = third_party/mesademos/

MESAGLIBCBUILD = $(MESA)/buildglibc/
MESAMINGWBUILD = $(MESA)/buildmingw/
GLUGLIBCBUILD = $(GLU)/buildglibc/
MESADEMOSGLIBCBUILD = $(MESADEMOS)/buildglibc/
MESADEMOSMINGWBUILD = $(MESADEMOS)/buildmingw/

XORGPROTOMINGWBUILT = $(x86_64MINGWOUTPUT)/include/GL/glxproto.h

MESONMINGWCONFIG = swrast/meson-x86_64-w64-mingw32.txt

swrastglibcbuild: mesademosglibc
swrastmingwbuild: mesademosmingw
swrastbuild: swrastglibcbuild swrastmingwbuild

nanoxclean:
	[ ! -e $(NANOX)/src ] || $(MAKE) -C $(NANOX)/src clean
	[ ! -e $(NANOX)/src ] || $(MAKE) -C $(NANOX)/src -f Makefile_nr ARCH=WIN32MINGW clean

swrastglibcclean: nanoxclean
	[ ! -e $(MESAGLIBCBUILD) ] || rm -rf $(MESAGLIBCBUILD)
	[ ! -e $(GLUGLIBCBUILD) ] || rm -rf $(GLUGLIBCBUILD)
	[ ! -e $(MESADEMOSGLIBCBUILD) ] || rm -rf $(MESADEMOSGLIBCBUILD)

swrastmingwclean: nanoxclean
	[ ! -e $(MESAMINGWBUILD) ] || rm -rf $(MESAMINGWBUILD)
	[ ! -e $(MESADEMOSMINGWBUILD) ] || rm -rf $(MESADEMOSMINGWBUILD)

swrastclean: swrastglibcclean swrastmingwclean
	rm swrast/*.built || true

swrastdistclean:
	rm swrast/*.commitid || true
	[ ! -e $(XORGPROTO)/meson.build ] || { cd $(XORGPROTO) && { git reset --hard; git clean -dfx; } }
	[ ! -e $(XORGPROTO)/meson.build ] || git submodule update $(XORGPROTO)
	[ ! -e $(NANOX)/src ] || { cd $(NANOX) && { git reset --hard; git clean -dfx; } }
	[ ! -e $(NANOX)/src ] || git submodule update $(NANOX)
	[ ! -e $(MESA)/meson.build ] || { cd $(MESA) && { git reset --hard; git clean -dfx; } }
	[ ! -e $(MESA)/meson.build ] || git submodule update $(MESA)
	[ ! -e $(GLU)/meson.build ] || { cd $(GLU) && { git reset --hard; git clean -dfx; } }
	[ ! -e $(GLU)/meson.build ] || git submodule update $(GLU)
	[ ! -e $(MESADEMOS)/meson.build ] || { cd $(MESADEMOS) && { git reset --hard; git clean -dfx; } }
	[ ! -e $(MESADEMOS)/meson.build ] || git submodule update $(MESADEMOS)


# Prevent building both nano-X targets at the same time since they build in tree
fixnanoxparallel =
ifeq ($(MAKECMDGOALS),)
fixnanoxparallel = yes
endif
ifneq ($(filter-out build swrastbuild swrastglibcbuild nanoxglibc mesaglibc gluglibc mesademosglibc,$(MAKECMDGOALS)),$(MAKECMDGOALS))
fixnanoxparallel = yes
endif


$(XORGPROTOMINGWBUILT): | $(x86_64MINGWOUTPUT)/include/GL/
	[ -e $(XORGPROTO)/meson.build ] || git submodule update --init $(XORGPROTO)
	cp $(XORGPROTO)/include/GL/*.h $(x86_64MINGWOUTPUT)/include/GL/

# The unstaged status check is from https://stackoverflow.com/a/62768943
nanoxsetup:
	[ -d $(NANOX)/src ] || git submodule update --init $(NANOX)
	cd $(NANOX);                                                      \
	if [ -z "$$(git status --porcelain=v1 2>/dev/null)" ]; then       \
	  git apply --whitespace=fix $(PWD)/swrast/microwindows.patch;    \
	  git add .;                                                      \
	  git commit -m swrastpatch >/dev/null;                           \
	  git rev-parse --verify @ > $(PWD)/swrast/microwindows.commitid; \
	  git reset --soft @~1;                                           \
	fi

nanoxglibc: | nanoxsetup $(x86_64GLIBCOUTPUT)/lib/pkgconfig/
	if [ ! -f swrast/microwindows.built ] || [ "$$(cat swrast/microwindows.built)" != "glibc" ]; then \
	  $(MAKE) -C $(NANOX)/src clean;                                                                  \
	  $(MAKE) -C $(NANOX)/src -f Makefile_nr ARCH=WIN32MINGW clean;                                   \
	fi
	if [ ! -f swrast/microwindows.built ] || [ "$$(cat swrast/microwindows.built)" != "glibc" ] ||                  \
	    [ -n "$$(cd $(NANOX) && < $(PWD)/swrast/microwindows.commitid git diff)" ] ||                               \
	    [ -n "$$(cd $(NANOX) && git ls-files --others --exclude-standard)" ]; then                                  \
	  $(MAKE) -C $(NANOX)/src;                                                                                      \
	  $(MAKE) -C $(NANOX)/src install INSTALL_PREFIX=$(PWD)/$(x86_64GLIBCOUTPUT) INSTALL_OWNER1= INSTALL_OWNER2=;   \
	  sed 's#@PREFIX@#$(PWD)/$(x86_64GLIBCOUTPUT)#' swrast/nx11.pc.in > $(x86_64GLIBCOUTPUT)/lib/pkgconfig/nx11.pc; \
	  echo glibc > swrast/microwindows.built;                                                                       \
	fi

nanoxmingw: | nanoxsetup $(if $(filter $(fixnanoxparallel),yes), nanoxglibc) $(x86_64MINGWOUTPUT)/include/ $(x86_64MINGWOUTPUT)/lib/pkgconfig/
	if [ ! -f swrast/microwindows.built ] || [ "$$(cat swrast/microwindows.built)" != "mingw" ]; then \
	  $(MAKE) -C $(NANOX)/src clean;                                                                  \
	  $(MAKE) -C $(NANOX)/src -f Makefile_nr ARCH=WIN32MINGW clean;                                   \
	fi
	if [ ! -f swrast/microwindows.built ] || [ "$$(cat swrast/microwindows.built)" != "mingw" ] ||                  \
	    [ -n "$$(cd $(NANOX) && < $(PWD)/swrast/microwindows.commitid git diff)" ] ||                               \
	    [ -n "$$(cd $(NANOX) && git ls-files --others --exclude-standard)" ]; then                                  \
	  $(MAKE) -C $(NANOX)/src -f Makefile_nr ARCH=WIN32MINGW;                                                       \
	  cp -r $(NANOX)/src/nx11/X11-local/X11/ $(x86_64MINGWOUTPUT)/include/;                                         \
	  cp $(NANOX)/src/lib/*.a $(x86_64MINGWOUTPUT)/lib/;                                                            \
	  sed 's#@PREFIX@#$(PWD)/$(x86_64MINGWOUTPUT)#' swrast/nx11.pc.in > $(x86_64MINGWOUTPUT)/lib/pkgconfig/nx11.pc; \
	  echo mingw > swrast/microwindows.built;                                                                       \
	fi

mesasetup:
	[ -e $(MESA)/meson.build ] || git submodule update --init $(MESA)
	cd $(MESA);                                                 \
	if [ -z "$$(git status --porcelain=v1 2>/dev/null)" ]; then \
	  git apply --whitespace=fix $(PWD)/swrast/mesa.patch;      \
	  git add .;                                                \
	  git commit -m swrastpatch >/dev/null;                     \
	  git rev-parse --verify @ > $(PWD)/swrast/mesa.commitid;   \
	  git reset --soft @~1;                                     \
	fi

mesaglibc: nanoxglibc mesasetup
	if [ ! -d $(MESAGLIBCBUILD) ]; then \
	  PKG_CONFIG_PATH=$(x86_64GLIBCOUTPUT)/lib/pkgconfig/ meson setup $(MESAGLIBCBUILD) $(MESA) -Ddri3=disabled -Degl=disabled -Dgallium-drivers=swrast -Dgles1=disabled -Dgles2=disabled -Dglx=nxlib -Dosmesa=false -Dplatforms=x11 -Dshared-glapi=disabled -Dvalgrind=disabled -Dvideo-codecs= -Dvulkan-drivers= -Ddefault_library=static --prefix=$(PWD)/$(x86_64GLIBCOUTPUT); \
	  meson install -C $(MESAGLIBCBUILD);                                           \
	elif [ -n "$$(cd $(MESA) && < $(PWD)/swrast/mesa.commitid git diff)" ] ||       \
	      [ -n "$$(cd $(MESA) && git ls-files --others --exclude-standard)" ]; then \
	  PKG_CONFIG_PATH=$(x86_64GLIBCOUTPUT)/lib/pkgconfig/ meson setup $(MESAGLIBCBUILD) $(MESA) -Ddri3=disabled -Degl=disabled -Dgallium-drivers=swrast -Dgles1=disabled -Dgles2=disabled -Dglx=nxlib -Dosmesa=false -Dplatforms=x11 -Dshared-glapi=disabled -Dvalgrind=disabled -Dvideo-codecs= -Dvulkan-drivers= -Ddefault_library=static --prefix=$(PWD)/$(x86_64GLIBCOUTPUT) --reconfigure; \
	  meson install -C $(MESAGLIBCBUILD); \
	fi

mesamingw: $(XORGPROTOMINGWBUILT) nanoxmingw mesasetup | $(x86_64MINGWOUTPUT)/include/GL/
	if [ ! -d $(MESAMINGWBUILD) ]; then \
	  PKG_CONFIG_PATH=$(x86_64MINGWOUTPUT)/lib/pkgconfig/ CFLAGS=-I$(PWD)/$(x86_64MINGWOUTPUT)/include meson setup $(MESAMINGWBUILD) $(MESA) -Ddri3=disabled -Degl=disabled -Dgallium-drivers=swrast -Dgles1=disabled -Dgles2=disabled -Dglx=nxlib -Dosmesa=false -Dplatforms=x11 -Dshared-glapi=disabled -Dvalgrind=disabled -Dvideo-codecs= -Dvulkan-drivers= --cross-file $(MESONMINGWCONFIG) -Ddefault_library=static --prefix=$(PWD)/$(x86_64MINGWOUTPUT); \
	  meson install -C $(MESAMINGWBUILD);                                           \
	  cp $(MESA)/include/GL/glx* $(x86_64MINGWOUTPUT)/include/GL/;                  \
	elif [ -n "$$(cd $(MESA) && < $(PWD)/swrast/mesa.commitid git diff)" ] ||       \
	      [ -n "$$(cd $(MESA) && git ls-files --others --exclude-standard)" ]; then \
	  PKG_CONFIG_PATH=$(x86_64MINGWOUTPUT)/lib/pkgconfig/ CFLAGS=-I$(PWD)/$(x86_64MINGWOUTPUT)/include meson setup $(MESAMINGWBUILD) $(MESA) -Ddri3=disabled -Degl=disabled -Dgallium-drivers=swrast -Dgles1=disabled -Dgles2=disabled -Dglx=nxlib -Dosmesa=false -Dplatforms=x11 -Dshared-glapi=disabled -Dvalgrind=disabled -Dvideo-codecs= -Dvulkan-drivers= --cross-file $(MESONMINGWCONFIG) -Ddefault_library=static --prefix=$(PWD)/$(x86_64MINGWOUTPUT) --reconfigure; \
	  meson install -C $(MESAMINGWBUILD);                          \
	  cp $(MESA)/include/GL/glx* $(x86_64MINGWOUTPUT)/include/GL/; \
	fi

gluglibc: mesaglibc
	[ -e $(GLU)/meson.build ] || git submodule update --init $(GLU)
	if [ ! -d $(GLUGLIBCBUILD) ]; then \
	  PKG_CONFIG_PATH=$(x86_64GLIBCOUTPUT)/lib/pkgconfig/:$(x86_64GLIBCOUTPUT)/lib/x86_64-linux-gnu/pkgconfig meson setup $(GLUGLIBCBUILD) $(GLU) -Dgl_provider=glvnd -Ddefault_library=static --prefix=$(PWD)/$(x86_64GLIBCOUTPUT); \
	  meson install -C $(GLUGLIBCBUILD);                                                 \
	elif [ -n "$$(cd $(GLU) && git diff $(cd $(PWD) && git rev-parse @:$(GLUGIT)))" ] || \
	      [ -n "$$(cd $(GLU) && git ls-files --others --exclude-standard)" ]; then       \
	  PKG_CONFIG_PATH=$(x86_64GLIBCOUTPUT)/lib/pkgconfig/:$(x86_64GLIBCOUTPUT)/lib/x86_64-linux-gnu/pkgconfig meson setup $(GLUGLIBCBUILD) $(GLU) -Dgl_provider=glvnd -Ddefault_library=static --prefix=$(PWD)/$(x86_64GLIBCOUTPUT) --reconfigure; \
	  meson install -C $(GLUGLIBCBUILD); \
	fi

mesademossetup:
	[ -e $(MESADEMOS)/meson.build ] || git submodule update --init $(MESADEMOS)
	cd $(MESADEMOS);                                               \
	if [ -z "$$(git status --porcelain=v1 2>/dev/null)" ]; then    \
	  git apply --whitespace=fix $(PWD)/swrast/mesademos.patch;    \
	  git add .;                                                   \
	  git commit -m swrastpatch >/dev/null;                        \
	  git rev-parse --verify @ > $(PWD)/swrast/mesademos.commitid; \
	  git reset --soft @~1;                                        \
	fi

mesademosglibc: gluglibc mesademossetup
	if [ ! -d $(MESADEMOSGLIBCBUILD) ]; then \
	  PKG_CONFIG_PATH=$(x86_64GLIBCOUTPUT)/lib/pkgconfig/:$(x86_64GLIBCOUTPUT)/lib/x86_64-linux-gnu/pkgconfig meson setup $(MESADEMOSGLIBCBUILD) $(MESADEMOS) -Degl=disabled -Dgles1=disabled -Dgles2=disabled -Dglut=disabled -Dlibdrm=disabled -Dmesa-library-type=static -Dosmesa=disabled -Dvulkan=disabled -Dwayland=disabled -Dx11=nx11 -Ddefault_library=static --prefix=$(PWD)/$(x86_64GLIBCOUTPUT); \
	  meson install -C $(MESADEMOSGLIBCBUILD);                                           \
	elif [ -n "$$(cd $(MESADEMOS) && < $(PWD)/swrast/mesademos.commitid git diff)" ] ||  \
	      [ -n "$$(cd $(MESADEMOS) && git ls-files --others --exclude-standard)" ]; then \
	  PKG_CONFIG_PATH=$(x86_64GLIBCOUTPUT)/lib/pkgconfig/:$(x86_64GLIBCOUTPUT)/lib/x86_64-linux-gnu/pkgconfig meson setup $(MESADEMOSGLIBCBUILD) $(MESADEMOS) -Degl=disabled -Dgles1=disabled -Dgles2=disabled -Dglut=disabled -Dlibdrm=disabled -Dmesa-library-type=static -Dosmesa=disabled -Dvulkan=disabled -Dwayland=disabled -Dx11=nx11 -Ddefault_library=static --prefix=$(PWD)/$(x86_64GLIBCOUTPUT) --reconfigure; \
	  meson install -C $(MESADEMOSGLIBCBUILD); \
	fi

mesademosmingw: mesamingw mesademossetup
	if [ ! -d $(MESADEMOSMINGWBUILD) ]; then \
	  PKG_CONFIG_PATH=$(x86_64MINGWOUTPUT)/lib/pkgconfig/ CFLAGS=-I$(PWD)/$(x86_64MINGWOUTPUT)/include meson setup $(MESADEMOSMINGWBUILD) $(MESADEMOS) -Degl=disabled -Dgles1=disabled -Dgles2=disabled -Dglut=disabled -Dlibdrm=disabled -Dmesa-library-type=static -Dosmesa=disabled -Dvulkan=disabled -Dwayland=disabled -Dx11=nx11 -Dwgl=disabled --cross-file $(MESONMINGWCONFIG) -Ddefault_library=static --prefix=$(PWD)/$(x86_64MINGWOUTPUT); \
	  meson install -C $(MESADEMOSMINGWBUILD);                                           \
	elif [ -n "$$(cd $(MESADEMOS) && < $(PWD)/swrast/mesademos.commitid git diff)" ] ||  \
	      [ -n "$$(cd $(MESADEMOS) && git ls-files --others --exclude-standard)" ]; then \
	  PKG_CONFIG_PATH=$(x86_64MINGWOUTPUT)/lib/pkgconfig/ CFLAGS=-I$(PWD)/$(x86_64MINGWOUTPUT)/include meson setup $(MESADEMOSMINGWBUILD) $(MESADEMOS) -Degl=disabled -Dgles1=disabled -Dgles2=disabled -Dglut=disabled -Dlibdrm=disabled -Dmesa-library-type=static -Dosmesa=disabled -Dvulkan=disabled -Dwayland=disabled -Dx11=nx11 -Dwgl=disabled --cross-file $(MESONMINGWCONFIG) -Ddefault_library=static --prefix=$(PWD)/$(x86_64MINGWOUTPUT) --reconfigure; \
	  meson install -C $(MESADEMOSMINGWBUILD); \
	fi
