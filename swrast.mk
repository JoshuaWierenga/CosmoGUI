# TODO: Fix linux build needing nano-X server to be a seperate program, currently LINK_APP_INTO_SERVER causes crashes
# TODO: Add dos support
# TODO: Remove need for nx11.pc, may not be possible as my patch for mesa ensures it ends up as a requirement in gl.pc
# TODO: Allow rebuilding submodules with changes when using mingw
# TODO: Check if meson --reconfigure is needed. I think that meson checks for script changes on build and reconfigures are required automatically
# TODO: Move rebuild checks from shell to make

.PHONY: swrastmingwbuild swrastglibcbuild swrastbuild nanoxclean swrastglibcclean swrastmingwclean swrastclean swrastdistclean
.PHONY: nanoxsetup nanoxglibc mesaglibc gluglibc mesademosglibc

XORGPROTO = third_party/xorgproto/
NANOX = third_party/microwindows/
NANOXSRC = third_party/microwindows/src/
MESA = third_party/mesa/
GLU = third_party/glu/
MESADEMOS = third_party/mesademos/

MESAGLIBCBUILD = $(MESA)/buildglibc/
MESAMINGWBUILD = $(MESA)/buildmingw/
GLUGLIBCBUILD = $(GLU)/buildglibc/
MESADEMOSGLIBCBUILD = $(MESADEMOS)/buildglibc/
MESADEMOSMINGWBUILD = $(MESADEMOS)/buildmingw/

XORGPROTOMINGWBUILT = $(x86_64MINGWOUTPUT)/include/GL/glxproto.h
MESAMINGWBUILT = $(MESAMINGWBUILD)/meson-logs/install-log.txt
MESADEMOSMINGWBUILT = $(MESADEMOSMINGWBUILD)/meson-logs/install-log.txt

MESONMINGWCONFIG = swrast/meson-x86_64-w64-mingw32.txt

swrastglibcbuild: mesademosglibc
swrastmingwbuild: $(MESADEMOSMINGWBUILT)
swrastbuild: swrastglibcbuild swrastmingwbuild

nanoxclean:
	[ ! -e $(NANOXSRC) ] || $(MAKE) -C $(NANOXSRC) clean
	[ ! -e $(NANOXSRC) ] || $(MAKE) -C $(NANOXSRC) -f Makefile_nr ARCH=WIN32MINGW clean

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
	[ ! -e $(NANOXSRC) ] || { cd $(NANOX) && { git reset --hard; git clean -dfx; } }
	[ ! -e $(NANOXSRC) ] || git submodule update $(NANOX)
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
	[ -d $(NANOXSRC) ] || git submodule update --init $(NANOX)
	cd $(NANOX);                                                         \
	if [ -z "$$(git status --porcelain=v1 2>/dev/null)" ]; then          \
	  git apply --whitespace=fix $(PWD)/swrast/microwindows.patch;       \
	  git add .;                                                         \
	  git commit -m swrastpatch >/dev/null;                              \
	  git rev-parse --verify HEAD > $(PWD)/swrast/microwindows.commitid; \
	  git reset --soft HEAD~1;                                           \
	fi

nanoxglibc: | nanoxsetup $(x86_64GLIBCOUTPUT)/lib/pkgconfig/
	if [ ! -f swrast/microwindows.built ] || [ "$$(cat swrast/microwindows.built)" != "glibc" ]; then \
	  $(MAKE) -C $(NANOXSRC) clean;                                                                   \
	  $(MAKE) -C $(NANOXSRC) -f Makefile_nr ARCH=WIN32MINGW clean;                                    \
	fi
	if [ ! -f swrast/microwindows.built ] || [ "$$(cat swrast/microwindows.built)" != "glibc" ] ||                  \
	    [ -n "$$(cd $(NANOX) && < $(PWD)/swrast/microwindows.commitid git diff)" ] ||                               \
	    [ -n "$$(cd $(NANOX) && git ls-files --others --exclude-standard)" ] ; then                                 \
	  $(MAKE) -C $(NANOXSRC);                                                                                       \
	  $(MAKE) -C $(NANOXSRC) install INSTALL_PREFIX=$(PWD)/$(x86_64GLIBCOUTPUT) INSTALL_OWNER1= INSTALL_OWNER2=;    \
	  sed 's#@PREFIX@#$(PWD)/$(x86_64GLIBCOUTPUT)#' swrast/nx11.pc.in > $(x86_64GLIBCOUTPUT)/lib/pkgconfig/nx11.pc; \
	  echo glibc > swrast/microwindows.built;                                                                       \
	fi

nanoxmingw: | nanoxsetup $(if $(filter $(fixnanoxparallel),yes), nanoxglibc) $(x86_64MINGWOUTPUT)/include/ $(x86_64MINGWOUTPUT)/lib/pkgconfig/
	if [ ! -f swrast/microwindows.built ] || [ "$$(cat swrast/microwindows.built)" != "mingw" ]; then \
	  $(MAKE) -C $(NANOXSRC) clean;                                                                   \
	  $(MAKE) -C $(NANOXSRC) -f Makefile_nr ARCH=WIN32MINGW clean;                                    \
	fi
	if [ ! -f swrast/microwindows.built ] || [ "$$(cat swrast/microwindows.built)" != "mingw" ] ||                  \
	    [ -n "$$(cd $(NANOX) && < $(PWD)/swrast/microwindows.commitid git diff)" ] ||                               \
	    [ -n "$$(cd $(NANOX) && git ls-files --others --exclude-standard)" ] ; then                                 \
	  $(MAKE) -C $(NANOXSRC) -f Makefile_nr ARCH=WIN32MINGW;                                                        \
	  cp -r $(NANOXSRC)/nx11/X11-local/X11/ $(x86_64MINGWOUTPUT)/include/;                                          \
	  cp $(NANOXSRC)/lib/*.a $(x86_64MINGWOUTPUT)/lib/;                                                             \
	  sed 's#@PREFIX@#$(PWD)/$(x86_64MINGWOUTPUT)#' swrast/nx11.pc.in > $(x86_64MINGWOUTPUT)/lib/pkgconfig/nx11.pc; \
	  echo mingw > swrast/microwindows.built;                                                                       \
	fi

mesaglibc: nanoxglibc
	[ -e $(MESA)/meson.build ] || git submodule update --init $(MESA)
	cd $(MESA);                                                  \
	if [ -z "$$(git status --porcelain=v1 2>/dev/null)" ]; then  \
	  git apply --whitespace=fix $(PWD)/swrast/mesa.patch;       \
	  git add .;                                                 \
	  git commit -m swrastpatch >/dev/null;                      \
	  git rev-parse --verify HEAD > $(PWD)/swrast/mesa.commitid; \
	  git reset --soft HEAD~1;                                   \
	fi
	if [ ! -d $(MESAGLIBCBUILD) ]; then \
	  PKG_CONFIG_PATH=$(x86_64GLIBCOUTPUT)/lib/pkgconfig/ meson setup $(MESAGLIBCBUILD) $(MESA) -Ddri3=disabled -Degl=disabled -Dgallium-drivers=swrast -Dgles1=disabled -Dgles2=disabled -Dglx=nxlib -Dosmesa=false -Dplatforms=x11 -Dshared-glapi=disabled -Dvalgrind=disabled -Dvideo-codecs= -Dvulkan-drivers= -Ddefault_library=static --prefix=$(PWD)/$(x86_64GLIBCOUTPUT); \
	  meson install -C $(MESAGLIBCBUILD);                                            \
	elif [ -n "$$(cd $(MESA) && < $(PWD)/swrast/mesa.commitid git diff)" ] ||        \
	      [ -n "$$(cd $(MESA) && git ls-files --others --exclude-standard)" ] ; then \
	  PKG_CONFIG_PATH=$(x86_64GLIBCOUTPUT)/lib/pkgconfig/ meson setup $(MESAGLIBCBUILD) $(MESA) -Ddri3=disabled -Degl=disabled -Dgallium-drivers=swrast -Dgles1=disabled -Dgles2=disabled -Dglx=nxlib -Dosmesa=false -Dplatforms=x11 -Dshared-glapi=disabled -Dvalgrind=disabled -Dvideo-codecs= -Dvulkan-drivers= -Ddefault_library=static --prefix=$(PWD)/$(x86_64GLIBCOUTPUT) --reconfigure; \
	  meson install -C $(MESAGLIBCBUILD); \
	fi

$(MESAMINGWBUILT): $(XORGPROTOMINGWBUILT) nanoxmingw | $(x86_64MINGWOUTPUT)/include/GL/
	[ -e $(MESA)/meson.build ] || git submodule update --init $(MESA)
	[ -n "$$(cd $(MESA) && git status --porcelain=v1 2>/dev/null)" ] || git apply --directory=$(MESA) swrast/mesa.patch
	[ -e $(MESAMINGWBUILD) ] || PKG_CONFIG_PATH=$(x86_64MINGWOUTPUT)/lib/pkgconfig/ CFLAGS=-I$(PWD)/$(x86_64MINGWOUTPUT)/include meson setup $(MESAMINGWBUILD) $(MESA) -Ddri3=disabled -Degl=disabled -Dgallium-drivers=swrast -Dgles1=disabled -Dgles2=disabled -Dglx=nxlib -Dosmesa=false -Dplatforms=x11 -Dshared-glapi=disabled -Dvalgrind=disabled -Dvideo-codecs= -Dvulkan-drivers= --cross-file $(MESONMINGWCONFIG) -Ddefault_library=static --prefix=$(PWD)/$(x86_64MINGWOUTPUT)
	meson install -C $(MESAMINGWBUILD)
	cp $(MESA)/include/GL/glx* $(x86_64MINGWOUTPUT)/include/GL/

gluglibc: mesaglibc
	[ -e $(GLU)/meson.build ] || git submodule update --init $(GLU)
	if [ ! -d $(GLUGLIBCBUILD) ]; then \
	  PKG_CONFIG_PATH=$(x86_64GLIBCOUTPUT)/lib/pkgconfig/:$(x86_64GLIBCOUTPUT)/lib/x86_64-linux-gnu/pkgconfig meson setup $(GLUGLIBCBUILD) $(GLU) -Dgl_provider=glvnd -Ddefault_library=static --prefix=$(PWD)/$(x86_64GLIBCOUTPUT); \
	  meson install -C $(GLUGLIBCBUILD);                                            \
	elif [ -n "$$(cd $(GLU) && git diff $(cd .. && git rev-parse HEAD:./glu))" ] || \
	      [ -n "$$(cd $(GLU) && git ls-files --others --exclude-standard)" ] ; then \
	  PKG_CONFIG_PATH=$(x86_64GLIBCOUTPUT)/lib/pkgconfig/:$(x86_64GLIBCOUTPUT)/lib/x86_64-linux-gnu/pkgconfig meson setup $(GLUGLIBCBUILD) $(GLU) -Dgl_provider=glvnd -Ddefault_library=static --prefix=$(PWD)/$(x86_64GLIBCOUTPUT) --reconfigure; \
	  meson install -C $(GLUGLIBCBUILD); \
	fi

mesademosglibc: gluglibc
	[ -e $(MESADEMOS)/meson.build ] || git submodule update --init $(MESADEMOS)
	cd $(MESADEMOS);                                                  \
	if [ -z "$$(git status --porcelain=v1 2>/dev/null)" ]; then       \
	  git apply --whitespace=fix $(PWD)/swrast/mesademos.patch;       \
	  git add .;                                                      \
	  git commit -m swrastpatch >/dev/null;                           \
	  git rev-parse --verify HEAD > $(PWD)/swrast/mesademos.commitid; \
	  git reset --soft HEAD~1;                                        \
	fi
	if [ ! -d $(MESADEMOSGLIBCBUILD) ]; then \
	  PKG_CONFIG_PATH=$(x86_64GLIBCOUTPUT)/lib/pkgconfig/:$(x86_64GLIBCOUTPUT)/lib/x86_64-linux-gnu/pkgconfig meson setup $(MESADEMOSGLIBCBUILD) $(MESADEMOS) -Degl=disabled -Dgles1=disabled -Dgles2=disabled -Dglut=disabled -Dlibdrm=disabled -Dmesa-library-type=static -Dosmesa=disabled -Dvulkan=disabled -Dwayland=disabled -Dx11=nx11 -Ddefault_library=static --prefix=$(PWD)/$(x86_64GLIBCOUTPUT); \
	  meson install -C $(MESADEMOSGLIBCBUILD);                                            \
	elif [ -n "$$(cd $(MESADEMOS) && < $(PWD)/swrast/mesademos.commitid git diff)" ] ||   \
	      [ -n "$$(cd $(MESADEMOS) && git ls-files --others --exclude-standard)" ] ; then \
	  PKG_CONFIG_PATH=$(x86_64GLIBCOUTPUT)/lib/pkgconfig/:$(x86_64GLIBCOUTPUT)/lib/x86_64-linux-gnu/pkgconfig meson setup $(MESADEMOSGLIBCBUILD) $(MESADEMOS) -Degl=disabled -Dgles1=disabled -Dgles2=disabled -Dglut=disabled -Dlibdrm=disabled -Dmesa-library-type=static -Dosmesa=disabled -Dvulkan=disabled -Dwayland=disabled -Dx11=nx11 -Ddefault_library=static --prefix=$(PWD)/$(x86_64GLIBCOUTPUT) --reconfigure; \
	  meson install -C $(MESADEMOSGLIBCBUILD); \
	fi

$(MESADEMOSMINGWBUILT): $(MESAMINGWBUILT)
	[ -e $(MESADEMOS)/meson.build ] || git submodule update --init $(MESADEMOS)
	[ -n "$$(cd $(MESADEMOS) && git status --porcelain=v1 2>/dev/null)" ] || git apply --directory=$(MESADEMOS) swrast/mesademos.patch
	[ -e $(MESADEMOSMINGWBUILD) ] || PKG_CONFIG_PATH=$(x86_64MINGWOUTPUT)/lib/pkgconfig/ CFLAGS=-I$(PWD)/$(x86_64MINGWOUTPUT)/include meson setup $(MESADEMOSMINGWBUILD) $(MESADEMOS) -Degl=disabled -Dgles1=disabled -Dgles2=disabled -Dglut=disabled -Dlibdrm=disabled -Dmesa-library-type=static -Dosmesa=disabled -Dvulkan=disabled -Dwayland=disabled -Dx11=nx11 -Dwgl=disabled --cross-file $(MESONMINGWCONFIG) -Ddefault_library=static --prefix=$(PWD)/$(x86_64MINGWOUTPUT)
	meson install -C $(MESADEMOSMINGWBUILD)
