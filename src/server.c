#ifdef __COSMOPOLITAN__
#include <cosmo.h>
#endif
#include <raylib.h>
#include <spawn.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>

#include "exitcodes.h"
#include "ipc.h"

// TODO: Detect ctrl+c and shutdown raylib
// TODO: Embed clients in server zip

int fd;
extern char **environ;

static pid_t open_client(int client_fd) {
  char *clientPath;
#if defined(__COSMOPOLITAN__)
  if (IsLinux()) {
    clientPath = "output/bin/linux/client";
  } else if (IsWindows()) {
    clientPath = "output/bin/windows/client.exe";
  } else {
    fprintf(stderr, "OS not supported");
    exit(CLIENT_ERROR);
  }
#elif defined(__linux__)
  clientPath = "output/bin/linux/client";
#elif defined(_WIN32)
  clientPath = "output/bin/windows/client.exe";
#else
#error OS not supported
#endif

#if defined(__COSMOPOLITAN__) || defined(__linux__)
  char buf[PATH_MAX + 1];
  char *actualPath = realpath(clientPath, buf);
  char *argv[] = {actualPath, NULL};

  posix_spawn_file_actions_t actions;
  int res = posix_spawn_file_actions_init(&actions);
  if (res) {
    fprintf(stderr, "Error: %s\n", strerror(res));
    exit(CLIENT_ERROR);
  }
  res = posix_spawn_file_actions_addclose(&actions, fd);
  if (res) {
    fprintf(stderr, "Error: %s\n", strerror(res));
    exit(CLIENT_ERROR);
  }
  if (client_fd != client_socket_fd) {
    res = posix_spawn_file_actions_adddup2(&actions, client_fd, client_socket_fd);
    if (res) {
      fprintf(stderr, "Error: %s\n", strerror(res));
      exit(CLIENT_ERROR);
    }
    res = posix_spawn_file_actions_addclose(&actions, client_fd);
    if (res) {
      fprintf(stderr, "Error: %s\n", strerror(res));
      exit(CLIENT_ERROR);
    }
  }

  pid_t pid;
  posix_spawn(&pid, actualPath, &actions, NULL, argv, environ);
  if (res) {
    fprintf(stderr, "Error: %s\n", strerror(res));
    exit(CLIENT_ERROR);
  }

  return pid;
// Todo use CreateProcess or something for windows
#else
#error OS not supported
#endif
}

/* Process:
   Server: CALL_RAYLIB_INITWINDOW
   Client: CLIENT_REQUEST_SIZE
   Server: datalen
   Client: CLIENT_REQUEST_PARAM
   Server: {wdith, height, title}
   Client: CLIENT_ACK */
void InitWindow(int width, int height, const char *title) {
  simple_request_event_pair(fd, CALL_RAYLIB_INITWINDOW, CLIENT_REQUEST_SIZE);

  size_t titlelen = strlen(title) + 1;
  size_t datalen = sizeof(width) + sizeof(height) + titlelen;

  send_data_expected(fd, &datalen, sizeof(datalen), CLIENT_REQUEST_PARAM);

  char data[datalen];
  char *pData = data;
  memcpy(pData, &width, sizeof(width));
  memcpy(pData += sizeof(width), &height, sizeof(height));
  memcpy(pData += sizeof(height), title, titlelen);

  send_data_expected(fd, data, sizeof(data), CLIENT_ACK);
}

/* Process:
   Server: CALL_RAYLIB_WINDOWSHOULDCLOSE
   Client: CLIENT_RESULT_READY
   Server: SERVER_REQUEST_RESULT
   Client: result
   Server: SERVER_ACK */
bool WindowShouldClose(void) {
  simple_request_event_pair(fd, CALL_RAYLIB_WINDOWSHOULDCLOSE, CLIENT_RESULT_READY);

  bool result;
  recv_data_request(fd, SERVER_REQUEST_RESULT, (void **)&result, sizeof(result));
  send_event(fd, SERVER_ACK);

  return result;
}

/* Process:
   Server: CALL_RAYLIB_CLOSEWINDOW
   Client: CLIENT_ACK */
// Renamed to avoid conflict with windows' CloseWindow
static void RLCloseWindow(void) {
  simple_request_event_pair(fd, CALL_RAYLIB_CLOSEWINDOW, CLIENT_ACK);
}

/* Process:
   Server: CALL_RAYLIB_CLEARBACKGROUND
   Client: CLIENT_REQUEST_PARAM
   Server: color
   Client: CLIENT_ACK */
void ClearBackground(Color color) {
  simple_request_event_pair(fd, CALL_RAYLIB_CLEARBACKGROUND, CLIENT_REQUEST_PARAM);
  send_data_expected(fd, &color, sizeof(color), CLIENT_ACK);
}

/* Process:
   Server: CALL_RAYLIB_BEGINDRAWING
   Client: CLIENT_ACK */
void BeginDrawing(void) {
  simple_request_event_pair(fd, CALL_RAYLIB_BEGINDRAWING, CLIENT_ACK);
}

/* Process:
   Server: CALL_RAYLIB_BEGINDRAWING
   Client: CLIENT_ACK */
void EndDrawing(void) {
  simple_request_event_pair(fd, CALL_RAYLIB_ENDDRAWING, CLIENT_ACK);
}

/* Process:
   Server: CALL_RAYLIB_SETTARGETFPS
   Client: CLIENT_REQUEST_PARAM
   Server: fps
   Client: CLIENT_ACK */
void SetTargetFPS(int fps) {
  simple_request_event_pair(fd, CALL_RAYLIB_SETTARGETFPS, CLIENT_REQUEST_PARAM);
  send_data_expected(fd, &fps, sizeof(fps), CLIENT_ACK);
}

/* Process:
   Server: CALL_RAYLIB_DRAWTEXT
   Client: CLIENT_REQUEST_SIZE
   Server: datalen
   Client: CLIENT_REQUEST_PARAM
   Server: {text, posX, posY, floatSize, color}
   Client: CLIENT_ACK */
// Renamed to avoid conflict with windows' DrawText
static void RLDrawText(const char *text, int posX, int posY, int fontSize, Color color) {
  simple_request_event_pair(fd, CALL_RAYLIB_DRAWTEXT, CLIENT_REQUEST_SIZE);

  size_t textlen = strlen(text) + 1;
  size_t datalen = textlen + sizeof(posX) + sizeof(posY) + sizeof(fontSize) + sizeof(color);

  send_data_expected(fd, &datalen, sizeof(datalen), CLIENT_REQUEST_PARAM);

  char data[datalen];
  char *pData = data;
  memcpy(pData, text, textlen);
  memcpy(pData += textlen, &posX, sizeof(posX));
  memcpy(pData += sizeof(posX), &posY, sizeof(posY));
  memcpy(pData += sizeof(posY), &fontSize, sizeof(fontSize));
  memcpy(pData += sizeof(fontSize), &color, sizeof(color));

  send_data_expected(fd, data, sizeof(data), CLIENT_ACK);
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

  int fds[2];
  socketpair(PF_LOCAL, SOCK_STREAM, 0, fds);

  fd = fds[0];
  pid_t client = open_client(fds[1]);
  close(fds[1]);

  simple_request_event_pair(fd, SERVER_INIT, CLIENT_INIT);

  runRaylib();

  simple_request_event_pair(fd, SERVER_QUIT, CLIENT_ACK);

  int res = waitpid(client, NULL, 0);
  if (res == -1) {
    perror("Error");
    exit(CLIENT_ERROR);
  }

  puts("Stopping server");

  close(fd);

  return 0;
}
