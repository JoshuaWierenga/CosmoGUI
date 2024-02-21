#! /bin/sh
(cd third_party/xorgproto && git diff --abbrev=7 > ../../swrast/xorgproto.patch)
(cd third_party/microwindows && git diff --abbrev=7 > ../../swrast/microwindows.patch)
(cd third_party/mesa && git diff --abbrev=7 > ../../swrast/mesa.patch)
(cd third_party/mesademos && git diff --abbrev=7 > ../../swrast/mesademos.patch)
