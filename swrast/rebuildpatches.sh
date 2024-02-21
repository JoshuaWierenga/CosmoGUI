#! /bin/sh
(
  cd third_party/microwindows || exit
  git diff --abbrev=7 > ../../swrast/microwindows.patch
  git diff --abbrev=7 --no-index /dev/null src/nx11/X11-local/X11/Xlibint.h >> ../../swrast/microwindows.patch
  git diff --abbrev=7 --no-index /dev/null src/nx11/X11-local/X11/Xmd.h >> ../../swrast/microwindows.patch
)
(cd third_party/mesa && git diff --abbrev=7 > ../../swrast/mesa.patch)
(cd third_party/mesademos && git diff --abbrev=7 > ../../swrast/mesademos.patch)
