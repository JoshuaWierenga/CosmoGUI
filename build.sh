#! /bin/sh

# TODO: Switch back to make?
# TODO: Support aarch64 for linux and MacOS
# TODO: Support FreeBSD and NetBSD
# TODO: Ensure Musl Libc works
# TODO: Replace dlopen with custom ipc for x86-64 OpenBSD and MacOS?

COSMOCC="${COSMOCC:-x86_64-unknown-cosmo-cc}"
LINUXCC="${LINUXCC:-gcc}"
WINCC="${WINCC:-x86_64-w64-mingw32-gcc}"

RAYLIBSRC=$PWD/third_party/raylib/src/
OUTPUT=$PWD/output/
GENERATED=$PWD/src/generated/

CORES=$(($(nproc) + 1))

rm -rf "${OUTPUT:?}/" "${GENERATED:?}/"
mkdir -p "$OUTPUT/include/" "$OUTPUT/lib/" "$GENERATED/libraylib/" "$GENERATED/libraylib_wrapper/"

# Step 1: Build/obtain native library, need shared, linux and windows versions
# Static libaries are prefered since a second level of dlopen can be skipped
# Shared is needed for Implib.so to work correctly, need to fix this
make -C "$RAYLIBSRC" clean
make -C "$RAYLIBSRC" CC="$LINUXCC" PLATFORM=PLATFORM_DESKTOP -j$CORES
cp --update "$RAYLIBSRC/libraylib.a" "$OUTPUT/lib/libraylib_x86_64-unknown-linux-gnu.a"

make -C "$RAYLIBSRC" clean
make -C "$RAYLIBSRC" CC="$WINCC" PLATFORM=PLATFORM_DESKTOP PLATFORM_OS=WINDOWS -j$CORES
cp --update "$RAYLIBSRC/libraylib.a" "$OUTPUT/lib/libraylib_x86_64-pc-windows-gnu.a"

make -C "$RAYLIBSRC" clean
make -C "$RAYLIBSRC" CC="$LINUXCC" PLATFORM=PLATFORM_DESKTOP RAYLIB_LIBTYPE=SHARED -j$CORES
cp --update "$RAYLIBSRC/raylib.h" "$OUTPUT/include/raylib.h"

# Step 2: Build ctags
(cd third_party/ctags/ && ./autogen.sh && ./configure --prefix "$OUTPUT/")
make -C third_party/ctags install -j$CORES

# Step 3: Create macroless header for ctags
gcc -E -o "$GENERATED/raylib.h" "$OUTPUT/include/raylib.h"

# Step 4: Generate shared library files
python3 third_party/Implib.so/implib-gen.py "$RAYLIBSRC/libraylib.so" -o "$GENERATED/libraylib/" --ctags "$OUTPUT/bin/ctags" --input-headers "$GENERATED/raylib.h" --windows-library libraylib_wrapper_x86_64-pc-windows-gnu.dll

# Step 5: Build shared library wrapper
$LINUXCC --shared -fpic -o "$OUTPUT/lib/libraylib_wrapper_x86_64-unknown-linux-gnu.so" "$GENERATED/libraylib/libraylib.so.init.c" "$GENERATED/libraylib/libraylib.so.tramp.S" "$GENERATED/libraylib/libraylib.so.nativewrapper.c" -I"$GENERATED/"

$WINCC --shared -fpic -o "$OUTPUT/lib/libraylib_wrapper_x86_64-pc-windows-gnu.dll" "$GENERATED/libraylib/libraylib.so.nativewrapper.c" -I"$GENERATED/" -L"$OUTPUT/lib/" -l:libraylib_x86_64-pc-windows-gnu.a -lgdi32 -lwinmm

# Step 6: Generate shared library wrapper files
python3 third_party/Implib.so/implib-gen.py "$OUTPUT/lib/libraylib_wrapper_x86_64-unknown-linux-gnu.so" -o "$GENERATED/libraylib_wrapper/" --dlopen-callback cosmo_dlopen_wrapper --dlsym-callback cosmo_dlsym

# Step 7: Build cosmo exec
RAYLIBCOSMOCC="$COSMOCC -mcosmo src/dlopen_wrapper.c $GENERATED/libraylib/libraylib.so.cosmowrapper.c $GENERATED/libraylib_wrapper/* -I$OUTPUT/include/"

$RAYLIBCOSMOCC -o "$OUTPUT/bin/shapes_basic_shapes.com" "$RAYLIBSRC/../examples/shapes/shapes_basic_shapes.c"
# TODO: Fix, currently fails to compile because of redefined symbols
#$RAYLIBCOSMOCC -o $OUTPUT/bin/core_3d_camera_first_person.com src/core_3d_camera_first_person.c
$RAYLIBCOSMOCC -o "$OUTPUT/bin/core_3d_camera_split_screen.com" "$RAYLIBSRC/../examples/core/core_3d_camera_split_screen.c"
# TODO: Readd raygui dependency, I have tested this and it does work
#$RAYLIBCOSMOCC -o $OUTPUT/bin/controls_test_suite.com src/controls_test_suite.c
# TODO: Add raygames dependency, again this does work
#$RAYLIBCOSMOCC -o $OUTPUT/bin/snake.com src/snake.c
# This one has broken controls and needs a few modifications to build with this system
#$RAYLIBCOSMOCC -o $OUTPUT/bin/retro_maze.com src/retro_maze_3d/*.c
#$RAYLIBCOSMOCC -o $OUTPUT/bin/first_person_maze.com src/models_first_person_maze/models_first_person_maze.c
