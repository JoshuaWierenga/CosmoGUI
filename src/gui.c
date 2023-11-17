#include <cosmo.h>
#include <dlfcn.h>
#include <raylib.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef __COSMOPOLITAN__
#define wontreturn __attribute__((__noreturn__))
#endif

// Tested against 8c7c9c1e069cb9e33ea5858540106ee476b970f, cosmo dynamic loading functions have been
// changing constantly since their introduction and only just got to the point of working for this.
// The only issue I know that survived all of the changes is that calling cosmo_dlerror when no error
// has occurred causes a seg fault because dlerror is allowed to return null which cosmo unconditionally
// calls strlcpy on. Wrapping the dlerror_set(res) call with "if (res)" fixes it. There were many more 
// fixes previously so glad they are no longer needed. No more stack corruption on loading shared libaries
// with their own shared libaries!

// TODO: Move raylib into gui with rglfw in shared libaries
// TODO: Pack shared libraries into cosmo zip

wontreturn void defaultFunc(const char *name) {
  fprintf(stderr, "FATAL: Function is not loaded: %s\n", name);
  exit(1);
}

#define wrapFunction(returnType, name, parameters, parameterNames) \
returnType (*P ## name)parameters = NULL;\
returnType name parameters {\
  if (!P ## name) {\
    defaultFunc(#name);\
  }\
  fprintf(stderr, "INFO: Calling libraylib function: " # name "\n");\
  return P ## name parameterNames;\
}

#define loadLibrary(var, path, mode) \
void *var = cosmo_dlopen(path, mode);\
if (!var) {\
  fprintf(stderr, "%s\n", dlerror());\
  exit(1);\
} else {\
  fprintf(stderr, "INFO: Loaded required library: " # path "\n");\
}

#define loadFunction(lib, name)\
P ## name = cosmo_dlsym(lib, #name);\
if (!P ## name) {\
  fprintf(stderr, "ERROR: Failed to load required function: " # name ": %s\n", dlerror());\
} else {\
  fprintf(stderr, "INFO: Loaded required function: " # name "\n");\
}

//------------------------------------------------------------------------------------
// Window and Graphics Device Functions (Module: core)
//------------------------------------------------------------------------------------

// Window-related functions
wrapFunction(void, InitWindow, (int width, int height, const char *title), (width, height, title))
wrapFunction(bool, WindowShouldClose, (void), ())
wrapFunction(void, CloseWindow, (void), ())

// Drawing-related functions
wrapFunction(void, ClearBackground, (Color color), (color))
wrapFunction(void, BeginDrawing, (void), ())
wrapFunction(void, EndDrawing, (void), ())

// Timing-related functions
wrapFunction(void, SetTargetFPS, (int fps), (fps))

//------------------------------------------------------------------------------------
// Font Loading and Text Drawing Functions (Module: text)
//------------------------------------------------------------------------------------
wrapFunction(void, DrawText, (const char *text, int posX, int posY, int fontSize, Color color), (text, posX, posY, fontSize, color));

static char linuxLibPath[] = "output/lib/x86_64-unknown-linux-gnu/libraylib.so";
static char windowsLibPath[] = "output/lib/x86_64-pc-windows-gnu/raylib.dll";

char *getLibPath() {
#if defined(__COSMOPOLITAN__)
  static char *libPath;
  if (IsLinux()) {
    puts("OS: Linux, SERVER LIBC: Cosmo, NATIVE LIBC: ?");
    libPath = linuxLibPath;
  } else if (IsWindows()) {
    puts("OS: Windows: SERVER LIBC: Cosmo, NATIVE LIBC: (u)crt");
    libPath = windowsLibPath;
  } else {
    fprintf(stderr, "OS not supported");
    exit(1);
  }
#elif defined(__linux__)
  puts("OS: Linux, SERVER LIBC: glibc/musl, NATIVE LIBC: glibc/musl");
  static char *libPath = linuxLibPath;
#elif defined(_WIN32)
  puts("OS: Windows, SERVER LIBC: (u)crt, NATIVE LIBC: (u)crt");
  static char *libPath = windowsLibPath;
#else
#error OS not supported
#endif /* __COSMOPOLITAN__, __linux__, _WIN32 */

  printf("PATH: %s\n", libPath);

  return libPath;
}

void initRaylibWrapper(char *raylibPath) {
  loadLibrary(libraylib, raylibPath, RTLD_LAZY);
  
  loadFunction(libraylib, InitWindow);
  loadFunction(libraylib, SetTargetFPS);
  loadFunction(libraylib, WindowShouldClose);
  loadFunction(libraylib, BeginDrawing);
  loadFunction(libraylib, ClearBackground);
  loadFunction(libraylib, DrawText);
  loadFunction(libraylib, EndDrawing);
  loadFunction(libraylib, CloseWindow);
}


/*******************************************************************************************
*
*   raylib [core] example - Basic window
*
*   Welcome to raylib!
*
*   To test examples, just press F6 and execute raylib_compile_execute script
*   Note that compiled executable is placed in the same folder as .c file
*
*   You can find all basic examples on C:\raylib\raylib\examples folder or
*   raylib official webpage: www.raylib.com
*
*   Enjoy using raylib. :)
*
*   Example originally created with raylib 1.0, last time updated with raylib 1.0
*
*   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
*   BSD-like license that allows static linking with closed source software
*
*   Copyright (c) 2013-2023 Ramon Santamaria (@raysan5)
*
********************************************************************************************/
void runRaylib(void) {
  // Initialization
  //--------------------------------------------------------------------------------------
  const int screenWidth = 800;
  const int screenHeight = 450;

  InitWindow(screenWidth, screenHeight, "raylib [core] example - basic window");

  SetTargetFPS(60);               // Set our game to run at 60 frames-per-second
  //--------------------------------------------------------------------------------------

  // Main game loop
  while (!WindowShouldClose())    // Detect window close button or ESC key
  {
    // Update
    //----------------------------------------------------------------------------------
    // TODO: Update your variables here
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    BeginDrawing();

      ClearBackground(RAYWHITE);

      DrawText("Congrats! You created your first window!", 190, 200, 20, LIGHTGRAY);

    EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  CloseWindow();        // Close window and OpenGL context
  //--------------------------------------------------------------------------------------
}

int main(void) {
  puts("Starting server");

  char *raylibPath = getLibPath();
  initRaylibWrapper(raylibPath);

  runRaylib();

  puts("Stopping server");

  return 0;
}
