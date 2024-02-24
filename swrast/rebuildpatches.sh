#! /bin/sh
(
  cd third_party/microwindows || exit
  git add -N src/nx11/X11-local/X11/Xlibint.h src/nx11/X11-local/X11/Xmd.h
  git diff --abbrev=7 $(cd .. && git rev-parse HEAD:./microwindows) > ../../swrast/microwindows.patch
)
(cd third_party/mesa && git diff --abbrev=7 $(cd .. && git rev-parse HEAD:./mesa) > ../../swrast/mesa.patch)
(cd third_party/mesademos && git diff --abbrev=7 $(cd .. && git rev-parse HEAD:./mesademos) > ../../swrast/mesademos.patch)
