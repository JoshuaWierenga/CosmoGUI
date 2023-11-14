#ifdef __COSMOPOLITAN__
#include <cosmo.h>
#endif
#include <errno.h>
#include <fcntl.h>
#include <raylib.h>
#include <sys/stat.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "exitcodes.h"
#include "ipc.h"

#ifdef __COSMOPOLITAN__
int32_t sys_mknod(const char *, uint32_t, uint64_t);
#endif

int sc_fd, cs_fd;

static int openfifoserver(char *path, mode_t mode, int oflag) {
  if (unlink(path) != 0 && errno != ENOENT) {
    perror("Error");
    exit(-1);
  }

#ifdef __COSMOPOLITAN__
  if (IsWindows()) {
    // TODO: Fix, the plan is to use unamed pipes so this may
    // not end up mattering
    exit(-1);
  } else {
    // Cosmo mknod does not allow S_IFIFO
    sys_mknod(path, mode | S_IFIFO, 0);
  }
#else
  if (mkfifo(path, mode) != 0) {
    perror("Error");
    exit(-1);
  }
#endif

  int fd = open(path, oflag);
  if (fd < 0) {
    perror("Error");
    exit(-1);
  }

  return fd;
}

/* Process:
   Server: CALL_RAYLIB_INITWINDOW
   Client: CLIENT_REQUEST_SIZE
   Server: datalen
   Client: CLIENT_REQUEST_PARAM
   Server: {wdith, height, title}
   Client: CLIENT_ACK */
void InitWindow(int width, int height, const char *title) {
  simplerequesteventpair(sc_fd, cs_fd, CALL_RAYLIB_INITWINDOW, CLIENT_REQUEST_SIZE);

  size_t titlelen = strlen(title) + 1;
  size_t datalen = sizeof(width) + sizeof(height) + titlelen;

  senddataexpected(sc_fd, cs_fd, &datalen, sizeof(datalen), CLIENT_REQUEST_PARAM);

  char data[datalen];
  char *pData = data;
  memcpy(pData, &width, sizeof(width));
  memcpy(pData += sizeof(width), &height, sizeof(height));
  memcpy(pData += sizeof(height), title, titlelen);

  senddataexpected(sc_fd, cs_fd, data, sizeof(data), CLIENT_ACK);
}

/* Process:
   Server: CALL_RAYLIB_WINDOWSHOULDCLOSE
   Client: CLIENT_RESULT_READY
   Server: SERVER_REQUEST_RESULT
   Client: result
   Server: SERVER_ACK */
bool WindowShouldClose(void) {
  simplerequesteventpair(sc_fd, cs_fd, CALL_RAYLIB_WINDOWSHOULDCLOSE, CLIENT_RESULT_READY);

  bool result;
  recvdatarequest(sc_fd, cs_fd, SERVER_REQUEST_RESULT, (void **)&result, sizeof(result));
  sendevent(sc_fd, SERVER_ACK);

  return result;
}

/* Process:
   Server: CALL_RAYLIB_CLOSEWINDOW
   Client: CLIENT_ACK */
// Renamed to avoid conflict with windows' CloseWindow
void RLCloseWindow(void) {
  simplerequesteventpair(sc_fd, cs_fd, CALL_RAYLIB_CLOSEWINDOW, CLIENT_ACK);
}

/* Process:
   Server: CALL_RAYLIB_CLEARBACKGROUND
   Client: CLIENT_REQUEST_PARAM
   Server: color
   Client: CLIENT_ACK */
void ClearBackground(Color color) {
  simplerequesteventpair(sc_fd, cs_fd, CALL_RAYLIB_CLEARBACKGROUND, CLIENT_REQUEST_PARAM);
  senddataexpected(sc_fd, cs_fd, &color, sizeof(color), CLIENT_ACK);
}

/* Process:
   Server: CALL_RAYLIB_BEGINDRAWING
   Client: CLIENT_ACK */
void BeginDrawing(void) {
  simplerequesteventpair(sc_fd, cs_fd, CALL_RAYLIB_BEGINDRAWING, CLIENT_ACK);
}

/* Process:
   Server: CALL_RAYLIB_BEGINDRAWING
   Client: CLIENT_ACK */
void EndDrawing(void) {
  simplerequesteventpair(sc_fd, cs_fd, CALL_RAYLIB_ENDDRAWING, CLIENT_ACK);
}

/* Process:
   Server: CALL_RAYLIB_SETTARGETFPS
   Client: CLIENT_REQUEST_PARAM
   Server: fps
   Client: CLIENT_ACK */
void SetTargetFPS(int fps) {
  simplerequesteventpair(sc_fd, cs_fd, CALL_RAYLIB_SETTARGETFPS, CLIENT_REQUEST_PARAM);
  senddataexpected(sc_fd, cs_fd, &fps, sizeof(fps), CLIENT_ACK);
}

/* Process:
   Server: CALL_RAYLIB_DRAWTEXT
   Client: CLIENT_REQUEST_SIZE
   Server: datalen
   Client: CLIENT_REQUEST_PARAM
   Server: {text, posX, posY, floatSize, color}
   Client: CLIENT_ACK */
// Renamed to avoid conflict with windows' DrawText
void RLDrawText(const char *text, int posX, int posY, int fontSize, Color color) {
  simplerequesteventpair(sc_fd, cs_fd, CALL_RAYLIB_DRAWTEXT, CLIENT_REQUEST_SIZE);

  size_t textlen = strlen(text) + 1;
  size_t datalen = textlen + sizeof(posX) + sizeof(posY) + sizeof(fontSize) + sizeof(color);

  senddataexpected(sc_fd, cs_fd, &datalen, sizeof(datalen), CLIENT_REQUEST_PARAM);

  char data[datalen];
  char *pData = data;
  memcpy(pData, text, textlen);
  memcpy(pData += textlen, &posX, sizeof(posX));
  memcpy(pData += sizeof(posX), &posY, sizeof(posY));
  memcpy(pData += sizeof(posY), &fontSize, sizeof(fontSize));
  memcpy(pData += sizeof(fontSize), &color, sizeof(color));

  senddataexpected(sc_fd, cs_fd, data, sizeof(data), CLIENT_ACK);
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

      RLDrawText("Congrats! You created your first window!", 190, 200, 20, LIGHTGRAY);

    EndDrawing();
    //----------------------------------------------------------------------------------
  }

  // De-Initialization
  //--------------------------------------------------------------------------------------
  RLCloseWindow();        // Close window and OpenGL context
  //--------------------------------------------------------------------------------------
}

int main(void) {
  puts("Starting server");

  sc_fd = openfifoserver("/tmp/cosmoguisc", 0600, O_WRONLY);
  cs_fd = openfifoserver("/tmp/cosmoguics", 0600, O_RDONLY);

  simplerequesteventpair(sc_fd, cs_fd, SERVER_INIT, CLIENT_INIT);

  runRaylib();

  simplerequesteventpair(sc_fd, cs_fd, SERVER_QUIT, CLIENT_ACK);

  puts("Stopping server");

  close(sc_fd);
  close(cs_fd);

  return 0;
}
