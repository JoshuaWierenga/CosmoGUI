# TODO: Add linux support
# TODO: Add dos support
# TODO: Remove as much of xorgproto and libx11 as possible since many of the functions in the headers are unsupported by nano-X
# TODO: Remove need for nx11.pc
# TODO: Remove need for glx.pc

.PHONY: swrastbuild swrastclean

XORGPROTO = third_party/xorgproto/
LIBX11 = third_party/libx11/
NANOX = third_party/microwindows/
NANOXSRC = third_party/microwindows/src/
MESA = third_party/mesa/
MESADEMOS = third_party/mesademos/

XORGPROTOWINBUILD = $(XORGPROTO)/buildwin/
MESAWINBUILD = $(MESA)/buildwin/
MESADEMOSWINBUILD = $(MESADEMOS)/buildwin/

XORGPROTOWINBUILT = $(XORGPROTOWINBUILD)/meson-logs/install-log.txt
LIBX11WINBUILT = $(LIBX11)/libx11win.built
NANOXWINBUILT = $(NANOXSRC)/lib/libNX11.a
MESAWINBUILT = $(MESAWINBUILD)/meson-logs/install-log.txt
MESADEMOSWINBUILT = $(MESADEMOSWINBUILD)/meson-logs/install-log.txt

MESONWINCONFIG = swrast/meson-x86_64-w64-mingw32.txt

swrastbuild: $(MESADEMOSWINBUILT)

swrastclean:
	[ ! -e $(XORGPROTOWINBUILD) ] || rm -r $(XORGPROTOWINBUILD)
	[ ! -e $(LIBX11)/Makefile ] || $(MAKE) -C $(LIBX11) distclean
	[ ! -e $(LIBX11WINBUILT) ] || rm $(LIBX11WINBUILT)
	[ ! -e $(NANOXSRC) ] || $(MAKE) -C $(NANOXSRC) -f Makefile_nr ARCH=WIN32MINGW clean
	[ ! -e $(MESAWINBUILD) ] || rm -rf $(MESAWINBUILD)
	[ ! -e $(MESADEMOSWINBUILD) ] || rm -rf $(MESADEMOSWINBUILD)


$(XORGPROTOWINBUILT):
	[ -e $(XORGPROTO)/meson.build ] || git submodule update --init $(XORGPROTO)
	git apply --reverse --check --directory=$(XORGPROTO) swrast/xorgproto.patch 2> /dev/null || git apply --directory=$(XORGPROTO) swrast/xorgproto.patch
	[ -e $(XORGPROTOWINBUILD) ] || meson setup $(XORGPROTOWINBUILD) $(XORGPROTO) --cross-file $(MESONWINCONFIG) -Dprefix=$(PWD)/$(x86_64MINGWOUTPUT)
	meson install -C $(XORGPROTOWINBUILD)

$(LIBX11WINBUILT):
	[ -e $(LIBX11)/configure.ac ] || git submodule update --init $(LIBX11)
	autoreconf -iv $(LIBX11)
	cd $(LIBX11) && CC=$(x86_64MINGWCC) CXX=$(x86_64MINGWC++) ./configure
	$(MAKE) -C $(LIBX11)/include install prefix=$(PWD)/$(x86_64MINGWOUTPUT)
	touch $(LIBX11WINBUILT)

$(NANOXWINBUILT): | $(x86_64MINGWOUTPUT)/include/X11/extensions/ $(x86_64MINGWOUTPUT)/lib/pkgconfig/
	[ -e $(NANOXSRC) ] || git submodule update --init $(NANOX)
	git apply --reverse --check --directory=$(NANOX) swrast/microwindows.patch 2> /dev/null || git apply --directory=$(NANOX) swrast/microwindows.patch
	$(MAKE) -C $(NANOXSRC) -f Makefile_nr ARCH=WIN32MINGW
	cp $(NANOXSRC)/nx11/X11-local/X11/extensions/shape.h $(x86_64MINGWOUTPUT)/include/X11/extensions/
	cp $(NANOXSRC)/lib/*.a $(x86_64MINGWOUTPUT)/lib/
	sed 's#@PREFIX@#$(PWD)/$(x86_64MINGWOUTPUT)#' swrast/nx11.pc.in > $(x86_64MINGWOUTPUT)/lib/pkgconfig/nx11.pc

$(MESAWINBUILT): $(XORGPROTOWINBUILT) $(LIBX11WINBUILT) $(NANOXWINBUILT) | $(x86_64MINGWOUTPUT)/include/GL/
	[ -e $(MESA)/meson.build ] || git submodule update --init $(MESA)
	git apply --reverse --check --directory=$(MESA) swrast/mesa.patch 2> /dev/null || git apply --directory=$(MESA) swrast/mesa.patch
	[ -e $(MESAWINBUILD) ] || PKG_CONFIG_PATH=$(x86_64MINGWOUTPUT)/lib/pkgconfig/ CFLAGS=-I$(PWD)/$(x86_64MINGWOUTPUT)/include meson setup $(MESAWINBUILD) $(MESA) -Ddri3=disabled -Degl=disabled -Dgallium-drivers=swrast -Dgles1=disabled -Dgles2=disabled -Dglx=nxlib -Dosmesa=false -Dplatforms=x11 -Dshared-glapi=disabled -Dvalgrind=disabled -Dvideo-codecs= -Dvulkan-drivers= --cross-file $(MESONWINCONFIG) -Ddefault_library=static -Dprefix=$(PWD)/$(x86_64MINGWOUTPUT)
	meson install -C $(MESAWINBUILD)
	cp $(x86_64MINGWOUTPUT)/lib/pkgconfig/gl.pc $(x86_64MINGWOUTPUT)/lib/pkgconfig/glx.pc
	cp $(MESA)/include/GL/glx* $(x86_64MINGWOUTPUT)/include/GL/

$(MESADEMOSWINBUILT): $(MESAWINBUILT)
	[ -e $(MESADEMOS)/meson.build ] || git submodule update --init $(MESADEMOS)
	git apply --reverse --check --directory=$(MESADEMOS) swrast/mesademos.patch 2> /dev/null || git apply --directory=$(MESADEMOS) swrast/mesademos.patch
	[ -e $(MESADEMOSWINBUILD) ] || PKG_CONFIG_PATH=$(x86_64MINGWOUTPUT)/lib/pkgconfig/ CFLAGS=-I$(PWD)/$(x86_64MINGWOUTPUT)/include meson setup $(MESADEMOSWINBUILD) $(MESADEMOS) -Degl=disabled -Dgles1=disabled -Dgles2=disabled -Dglut=disabled -Dlibdrm=disabled -Dmesa-library-type=static -Dosmesa=disabled -Dvulkan=disabled -Dwayland=disabled -Dx11=nx11 -Dwgl=disabled --cross-file $(MESONWINCONFIG) -Ddefault_library=static -Dprefix=$(PWD)/$(x86_64MINGWOUTPUT)
	meson install -C $(MESADEMOSWINBUILD)
