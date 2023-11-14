#include <fcntl.h>
#include <inttypes.h>
#include <raylib.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "exitcodes.h"
#include "ipc.h"

int sc_fd, cs_fd;

static int openfifoclient(char *path, int oflag) {
  int fd = open(path, oflag);
  if (fd < 0) {
    perror("Error");
    exit(-1);
  }
  return fd;
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
/* Process:
   Server: CALL_ADD
   Client: CLIENT_ACK */
static void handleRaylibEvent() {
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
  
  sendevent(cs_fd, CLIENT_ACK);
}

int main() {
  puts("Starting client");
  
  // TODO Fix this breaking if the client is started first
  sc_fd = openfifoclient("/tmp/cosmoguisc", O_RDONLY);
  // temp fix for second open being ignored by server
  sleep(1);
  cs_fd = openfifoclient("/tmp/cosmoguics", O_WRONLY);

  simpleresponseeventpair(cs_fd, sc_fd, SERVER_INIT, CLIENT_INIT);
  
  bool loop = true;
  while(loop) {
    event ev = recvevent(sc_fd);
    
    switch(ev) {
      case SERVER_QUIT:
        loop = false;
        sendevent(cs_fd, CLIENT_ACK);
        break;
      case CALL_RAYLIB:
        handleRaylibEvent();
        break;
      default:
        fprintf(stderr, "Server sent unexpected event\n");
        sendevent(cs_fd, CLIENT_ERR);
        exit(UNEXPECTED_EVENT);
        break;
    }
  }

  puts("Stopping client");

  close(sc_fd);
  close(cs_fd);

  return 0;
}
