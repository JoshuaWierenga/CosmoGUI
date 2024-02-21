# TODO: Fix linux build needing nano-X server to be a seperate program, currently LINK_APP_INTO_SERVER causes crashes
# TODO: Add dos support
# TODO: Remove as much of xorgproto and libx11 as possible since many of the functions in the headers are unsupported by nano-X
# TODO: Remove need for nx11.pc, may not be possible as my patch for mesa ensures it ends up as a requirement in gl.pc
# TODO: Use actual artifacts for all BUILT variables

.PHONY: swrastmingwbuild swrastglibcbuild swrastbuild nanoxclean swrastglibcclean swrastmingwclean swrastclean

XORGPROTO = third_party/xorgproto/
LIBX11 = third_party/libx11/
NANOX = third_party/microwindows/
NANOXSRC = third_party/microwindows/src/
MESA = third_party/mesa/
GLU = third_party/glu/
MESADEMOS = third_party/mesademos/

XORGPROTOMINGWBUILD = $(XORGPROTO)/buildmingw/
MESAGLIBCBUILD = $(MESA)/buildglibc/
MESAMINGWBUILD = $(MESA)/buildmingw/
GLUGLIBCBUILD = $(GLU)/buildglibc/
MESADEMOSGLIBCBUILD = $(MESADEMOS)/buildglibc/
MESADEMOSMINGWBUILD = $(MESADEMOS)/buildmingw/

XORGPROTOMINGWBUILT = $(XORGPROTOMINGWBUILD)/meson-logs/install-log.txt
LIBX11MINGWBUILT = $(LIBX11)/libx11mingw.built
NANOXGLIBCBUILT = $(x86_64GLIBCOUTPUT)/lib/libNX11.a
NANOXMINGWBUILT = $(x86_64MINGWOUTPUT)/lib/libNX11.a
MESAGLIBCBUILT = $(x86_64GLIBCOUTPUT)/lib/x86_64-linux-gnu/libGL.a
MESAMINGWBUILT = $(MESAMINGWBUILD)/meson-logs/install-log.txt
GLUGLIBCBUILT = $(x86_64GLIBCOUTPUT)/lib/x86_64-linux-gnu/libGLU.a
MESADEMOSGLIBCBUILT = $(MESADEMOSGLIBCBUILD)/meson-logs/install-log.txt
MESADEMOSMINGWBUILT = $(MESADEMOSMINGWBUILD)/meson-logs/install-log.txt

MESONMINGWCONFIG = swrast/meson-x86_64-w64-mingw32.txt

swrastglibcbuild: $(MESADEMOSGLIBCBUILT)
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
	[ ! -e $(XORGPROTOMINGWBUILD) ] || rm -r $(XORGPROTOMINGWBUILD)
	[ ! -e $(LIBX11)/Makefile ] || $(MAKE) -C $(LIBX11) distclean
	[ ! -e $(LIBX11MINGWBUILT) ] || rm $(LIBX11MINGWBUILT)
	[ ! -e $(MESAMINGWBUILD) ] || rm -rf $(MESAMINGWBUILD)
	[ ! -e $(MESADEMOSMINGWBUILD) ] || rm -rf $(MESADEMOSMINGWBUILD)

swrastclean: swrastglibcclean swrastmingwclean


$(XORGPROTOMINGWBUILT):
	[ -e $(XORGPROTO)/meson.build ] || git submodule update --init $(XORGPROTO)
	git apply --reverse --check --directory=$(XORGPROTO) swrast/xorgproto.patch 2> /dev/null || git apply --directory=$(XORGPROTO) swrast/xorgproto.patch
	[ -e $(XORGPROTOMINGWBUILD) ] || meson setup $(XORGPROTOMINGWBUILD) $(XORGPROTO) --cross-file $(MESONMINGWCONFIG) --prefix=$(PWD)/$(x86_64MINGWOUTPUT)
	meson install -C $(XORGPROTOMINGWBUILD)

$(LIBX11MINGWBUILT):
	[ -e $(LIBX11)/configure.ac ] || git submodule update --init $(LIBX11)
	autoreconf -iv $(LIBX11)
	cd $(LIBX11) && CC=$(x86_64MINGWCC) CXX=$(x86_64MINGWC++) ./configure
	$(MAKE) -C $(LIBX11)/include install prefix=$(PWD)/$(x86_64MINGWOUTPUT)
	touch $(LIBX11MINGWBUILT)

$(NANOXGLIBCBUILT) : | nanoxclean $(x86_64GLIBCOUTPUT)/lib/pkgconfig/
	[ -e $(NANOXSRC) ] || git submodule update --init $(NANOX)
	git apply --reverse --check --directory=$(NANOX) swrast/microwindows.patch 2> /dev/null || git apply --directory=$(NANOX) swrast/microwindows.patch
	$(MAKE) -C $(NANOXSRC)
	$(MAKE) -C $(NANOXSRC) install INSTALL_PREFIX=$(PWD)/$(x86_64GLIBCOUTPUT) INSTALL_OWNER1= INSTALL_OWNER2=
	sed 's#@PREFIX@#$(PWD)/$(x86_64GLIBCOUTPUT)#' swrast/nx11.pc.in > $(x86_64GLIBCOUTPUT)/lib/pkgconfig/nx11.pc

# This does not actually depend on the glibc build but both build in tree and so cannot run at once
$(NANOXMINGWBUILT): | nanoxclean $(NANOXGLIBCBUILT) $(x86_64MINGWOUTPUT)/include/X11/extensions/ $(x86_64MINGWOUTPUT)/lib/pkgconfig/
	[ -e $(NANOXSRC) ] || git submodule update --init $(NANOX)
	git apply --reverse --check --directory=$(NANOX) swrast/microwindows.patch 2> /dev/null || git apply --directory=$(NANOX) swrast/microwindows.patch
	$(MAKE) -C $(NANOXSRC) -f Makefile_nr ARCH=WIN32MINGW
	cp $(NANOXSRC)/nx11/X11-local/X11/extensions/shape.h $(x86_64MINGWOUTPUT)/include/X11/extensions/
	cp $(NANOXSRC)/lib/*.a $(x86_64MINGWOUTPUT)/lib/
	sed 's#@PREFIX@#$(PWD)/$(x86_64MINGWOUTPUT)#' swrast/nx11.pc.in > $(x86_64MINGWOUTPUT)/lib/pkgconfig/nx11.pc

$(MESAGLIBCBUILT): $(NANOXGLIBCBUILT)
	[ -e $(MESA)/meson.build ] || git submodule update --init $(MESA)
	git apply --reverse --check --directory=$(MESA) swrast/mesa.patch 2> /dev/null || git apply --directory=$(MESA) swrast/mesa.patch
	[ -e $(MESAGLIBCBUILD) ] || PKG_CONFIG_PATH=$(x86_64GLIBCOUTPUT)/lib/pkgconfig/ meson setup $(MESAGLIBCBUILD) $(MESA) -Ddri3=disabled -Degl=disabled -Dgallium-drivers=swrast -Dgles1=disabled -Dgles2=disabled -Dglx=nxlib -Dosmesa=false -Dplatforms=x11 -Dshared-glapi=disabled -Dvalgrind=disabled -Dvideo-codecs= -Dvulkan-drivers= -Ddefault_library=static --prefix=$(PWD)/$(x86_64GLIBCOUTPUT)
	meson install -C $(MESAGLIBCBUILD)

$(MESAMINGWBUILT): $(XORGPROTOMINGWBUILT) $(LIBX11MINGWBUILT) $(NANOXMINGWBUILT) | $(x86_64MINGWOUTPUT)/include/GL/
	[ -e $(MESA)/meson.build ] || git submodule update --init $(MESA)
	git apply --reverse --check --directory=$(MESA) swrast/mesa.patch 2> /dev/null || git apply --directory=$(MESA) swrast/mesa.patch
	[ -e $(MESAMINGWBUILD) ] || PKG_CONFIG_PATH=$(x86_64MINGWOUTPUT)/lib/pkgconfig/ CFLAGS=-I$(PWD)/$(x86_64MINGWOUTPUT)/include meson setup $(MESAMINGWBUILD) $(MESA) -Ddri3=disabled -Degl=disabled -Dgallium-drivers=swrast -Dgles1=disabled -Dgles2=disabled -Dglx=nxlib -Dosmesa=false -Dplatforms=x11 -Dshared-glapi=disabled -Dvalgrind=disabled -Dvideo-codecs= -Dvulkan-drivers= --cross-file $(MESONMINGWCONFIG) -Ddefault_library=static --prefix=$(PWD)/$(x86_64MINGWOUTPUT)
	meson install -C $(MESAMINGWBUILD)
	cp $(MESA)/include/GL/glx* $(x86_64MINGWOUTPUT)/include/GL/

$(GLUGLIBCBUILT): $(MESAGLIBCBUILT)
	[ -e $(GLU)/meson.build ] || git submodule update --init $(GLU)
	[ -e $(GLUGLIBCBUILD) ] || PKG_CONFIG_PATH=$(x86_64GLIBCOUTPUT)/lib/pkgconfig/:$(x86_64GLIBCOUTPUT)/lib/x86_64-linux-gnu/pkgconfig meson setup $(GLUGLIBCBUILD) $(GLU) -Dgl_provider=glvnd -Ddefault_library=static --prefix=$(PWD)/$(x86_64GLIBCOUTPUT)
	meson install -C $(GLUGLIBCBUILD)

$(MESADEMOSGLIBCBUILT): $(GLUGLIBCBUILT)
	[ -e $(MESADEMOS)/meson.build ] || git submodule update --init $(MESADEMOS)
	git apply --reverse --check --directory=$(MESADEMOS) swrast/mesademos.patch 2> /dev/null || git apply --directory=$(MESADEMOS) swrast/mesademos.patch
	[ -e $(MESADEMOSGLIBCBUILD) ] || PKG_CONFIG_PATH=$(x86_64GLIBCOUTPUT)/lib/pkgconfig/:$(x86_64GLIBCOUTPUT)/lib/x86_64-linux-gnu/pkgconfig meson setup $(MESADEMOSGLIBCBUILD) $(MESADEMOS) -Degl=disabled -Dgles1=disabled -Dgles2=disabled -Dglut=disabled -Dlibdrm=disabled -Dmesa-library-type=static -Dosmesa=disabled -Dvulkan=disabled -Dwayland=disabled -Dx11=nx11 -Ddefault_library=static --prefix=$(PWD)/$(x86_64GLIBCOUTPUT)
	meson install -C $(MESADEMOSGLIBCBUILD)

$(MESADEMOSMINGWBUILT): $(MESAMINGWBUILT)
	[ -e $(MESADEMOS)/meson.build ] || git submodule update --init $(MESADEMOS)
	git apply --reverse --check --directory=$(MESADEMOS) swrast/mesademos.patch 2> /dev/null || git apply --directory=$(MESADEMOS) swrast/mesademos.patch
	[ -e $(MESADEMOSMINGWBUILD) ] || PKG_CONFIG_PATH=$(x86_64MINGWOUTPUT)/lib/pkgconfig/ CFLAGS=-I$(PWD)/$(x86_64MINGWOUTPUT)/include meson setup $(MESADEMOSMINGWBUILD) $(MESADEMOS) -Degl=disabled -Dgles1=disabled -Dgles2=disabled -Dglut=disabled -Dlibdrm=disabled -Dmesa-library-type=static -Dosmesa=disabled -Dvulkan=disabled -Dwayland=disabled -Dx11=nx11 -Dwgl=disabled --cross-file $(MESONMINGWCONFIG) -Ddefault_library=static --prefix=$(PWD)/$(x86_64MINGWOUTPUT)
	meson install -C $(MESADEMOSMINGWBUILD)
