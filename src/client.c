#include <fcntl.h>
#include <inttypes.h>
#include <raylib.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
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

/* Process:
   Server: CALL_RAYLIB_INITWINDOW
   Client: CLIENT_REQUEST_SIZE
   Server: datalen
   Client: CLIENT_REQUEST_PARAM
   Server: {wdith, height, title}
   Client: CLIENT_ACK */
static void handleRaylibInitWindowEvent(void) {
  size_t datalen;
  recvdatarequest(cs_fd, sc_fd, CLIENT_REQUEST_SIZE, (void **)&datalen, sizeof(datalen));
  printf("datalen: %zu\n", datalen);

  char data[datalen];
  char *pData = data;
  recvdatarequest(cs_fd, sc_fd, CLIENT_REQUEST_PARAM, (void **)&data, sizeof(data));

  int width, height;
  memcpy(&width, pData, sizeof(width));
  memcpy(&height, pData += sizeof(width), sizeof(height));
  char *title = pData += sizeof(height);
  printf("width: %i, height: %i, title: \"%s\"\n", width, height, title);

  InitWindow(width, height, title);
  sendevent(cs_fd, CLIENT_ACK);
}

/* Process:
   Server: CALL_RAYLIB_WINDOWSHOULDCLOSE
   Client: CLIENT_RESULT_READY
   Server: SERVER_REQUEST_RESULT
   Client: result
   Server: SERVER_ACK */
static void handleRaylibWindowShouldClose(void) {
  // Technically out of order but whatever
  simplerequesteventpair(cs_fd, sc_fd, CLIENT_RESULT_READY, SERVER_REQUEST_RESULT);

  bool result = WindowShouldClose();
  printf("result: %hhu\n", result);

  senddataexpected(cs_fd, sc_fd, &result, sizeof(result), SERVER_ACK);
}

/* Process:
   Server: CALL_RAYLIB_CLEARBACKGROUND
   Client: CLIENT_REQUEST_PARAM
   Server: color
   Client: CLIENT_ACK */
static void handleRaylibClearBackground(void) {
  Color color;
  recvdatarequest(cs_fd, sc_fd, CLIENT_REQUEST_PARAM, (void **)&color, sizeof(color));
  printf("r: %hhu, g: %hhu, b: %hhx, a: %hhx\n", color.r, color.g, color.b, color.a);

  ClearBackground(color);
  sendevent(cs_fd, CLIENT_ACK);
}

/* Process:
   Server: CALL_RAYLIB_SETTARGETFPS
   Client: CLIENT_REQUEST_PARAM
   Server: fps
   Client: CLIENT_ACK */
static void handleRaylibSetTargetFPSEvent(void) {
  int fps;
  recvdatarequest(cs_fd, sc_fd, CLIENT_REQUEST_PARAM, (void **)&fps, sizeof(fps));
  printf("fps: %i\n", fps);

  SetTargetFPS(fps);
  sendevent(cs_fd, CLIENT_ACK);
}

/* Process:
   Server: CALL_RAYLIB_DRAWTEXT
   Client: CLIENT_REQUEST_SIZE
   Server: datalen
   Client: CLIENT_REQUEST_PARAM
   Server: {text, posX, posY, floatSize, color}
   Client: CLIENT_ACK */
static void handleRaylibDrawText(void) {
  size_t datalen;
  recvdatarequest(cs_fd, sc_fd, CLIENT_REQUEST_SIZE, (void **)&datalen, sizeof(datalen));
  printf("datalen: %zu\n", datalen);

  char data[datalen];
  char *pData = data;
  recvdatarequest(cs_fd, sc_fd, CLIENT_REQUEST_PARAM, (void **)&data, sizeof(data));

  char *text = pData;
  int posX, posY, fontSize;
  Color color;
  memcpy(&posX, pData += strlen(text) + 1, sizeof(posX));
  memcpy(&posY, pData += sizeof(posX), sizeof(posY));
  memcpy(&fontSize, pData += sizeof(posY), sizeof(fontSize));
  memcpy(&color, pData += sizeof(fontSize), sizeof(color));
  printf("text: \"%s\", posX: %i, posY: %i, fontSize %i, r: %hhu, g: %hhu, b: %hhx, a: %hhx\n", text, posX, posY, fontSize, color.r, color.g, color.b, color.a);

  DrawText(text, posX, posY, fontSize, color);
  sendevent(cs_fd, CLIENT_ACK);
}

int main(void) {
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

      //------------------------------------------------------------------------------------
      // Window and Graphics Device Functions (Module: core)
      //------------------------------------------------------------------------------------

      // Window-related functions
      case CALL_RAYLIB_INITWINDOW:
        handleRaylibInitWindowEvent();
        break;
      case CALL_RAYLIB_WINDOWSHOULDCLOSE:
        handleRaylibWindowShouldClose();
        break;
      case CALL_RAYLIB_CLOSEWINDOW:
        CloseWindow();
        sendevent(cs_fd, CLIENT_ACK);
        break;

      // Drawing-related functions
      case CALL_RAYLIB_CLEARBACKGROUND:
        handleRaylibClearBackground();
        break;
      case CALL_RAYLIB_BEGINDRAWING:
        BeginDrawing();
        sendevent(cs_fd, CLIENT_ACK);
        break;
      case CALL_RAYLIB_ENDDRAWING:
        EndDrawing();
        sendevent(cs_fd, CLIENT_ACK);
        break;

      // Timing-related functions
      case CALL_RAYLIB_SETTARGETFPS:
        handleRaylibSetTargetFPSEvent();
        break;

      //------------------------------------------------------------------------------------
      // Font Loading and Text Drawing Functions (Module: text)
      //------------------------------------------------------------------------------------

      // Text drawing functions
      case CALL_RAYLIB_DRAWTEXT:
        handleRaylibDrawText();
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
