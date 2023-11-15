#include <raylib.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "exitcodes.h"
#include "ipc.h"

//#define SHOW_WRAPPER_DATA

int fd;

/* Process:
   Server: CALL_RAYLIB_INITWINDOW
   Client: CLIENT_REQUEST_SIZE
   Server: datalen
   Client: CLIENT_REQUEST_PARAM
   Server: {wdith, height, title}
   Client: CLIENT_ACK */
static void handleRaylibInitWindow(void) {
  size_t datalen;
  recv_data_request(fd, CLIENT_REQUEST_SIZE, (void **)&datalen, sizeof(datalen));
  //printf("datalen: %zu\n", datalen);

  char data[datalen];
  char *pData = data;
  recv_data_request(fd, CLIENT_REQUEST_PARAM, (void **)&data, sizeof(data));

  int width, height;
  memcpy(&width, pData, sizeof(width));
  memcpy(&height, pData += sizeof(width), sizeof(height));
  char *title = pData += sizeof(height);

#ifdef SHOW_WRAPPER_DATA
  printf("InitWindow(%i, %i, \"%s\")\n", width, height, title);
#endif

  InitWindow(width, height, title);
  send_event(fd, CLIENT_ACK);
}

/* Process:
   Server: CALL_RAYLIB_WINDOWSHOULDCLOSE
   Client: CLIENT_RESULT_READY
   Server: SERVER_REQUEST_RESULT
   Client: result
   Server: SERVER_ACK */
static void handleRaylibWindowShouldClose(void) {
  // Technically out of order but whatever
  simple_request_event_pair(fd, CLIENT_RESULT_READY, SERVER_REQUEST_RESULT);

  bool result = WindowShouldClose();

#ifdef SHOW_WRAPPER_DATA
  printf("WindowShouldClose() = %hhu\n", result);
#endif

  send_data_expected(fd, &result, sizeof(result), SERVER_ACK);
}

/* Process:
   Server: CALL_RAYLIB_CLEARBACKGROUND
   Client: CLIENT_REQUEST_PARAM
   Server: color
   Client: CLIENT_ACK */
static void handleRaylibClearBackground(void) {
  Color color;
  recv_data_request(fd, CLIENT_REQUEST_PARAM, (void **)&color, sizeof(color));

#ifdef SHOW_WRAPPER_DATA
  printf("ClearBackground({%hhu, %hhu, %hhu, %hhu})\n", color.r, color.g, color.b, color.a);
#endif

  ClearBackground(color);
  send_event(fd, CLIENT_ACK);
}

/* Process:
   Server: CALL_RAYLIB_SETTARGETFPS
   Client: CLIENT_REQUEST_PARAM
   Server: fps
   Client: CLIENT_ACK */
static void handleRaylibSetTargetFPS(void) {
  int fps;
  recv_data_request(fd, CLIENT_REQUEST_PARAM, (void **)&fps, sizeof(fps));

#ifdef SHOW_WRAPPER_DATA
  printf("SetTargetFps(%i)\n", fps);
#endif

  SetTargetFPS(fps);
  send_event(fd, CLIENT_ACK);
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
  recv_data_request(fd, CLIENT_REQUEST_SIZE, (void **)&datalen, sizeof(datalen));
  //printf("datalen: %zu\n", datalen);

  char data[datalen];
  char *pData = data;
  recv_data_request(fd, CLIENT_REQUEST_PARAM, (void **)&data, sizeof(data));

  char *text = pData;
  int posX, posY, fontSize;
  Color color;
  memcpy(&posX, pData += strlen(text) + 1, sizeof(posX));
  memcpy(&posY, pData += sizeof(posX), sizeof(posY));
  memcpy(&fontSize, pData += sizeof(posY), sizeof(fontSize));
  memcpy(&color, pData += sizeof(fontSize), sizeof(color));

#ifdef SHOW_WRAPPER_DATA
  printf("DrawText(\"%s\", %i, %i, %i, {%hhu, %hhu, %hhu, %hhu})\n", text, posX, posY, fontSize,
    color.r, color.g, color.b, color.a);
#endif

  DrawText(text, posX, posY, fontSize, color);
  send_event(fd, CLIENT_ACK);
}

int main(int argc, char **argv) {
  puts("Starting client");
  fd = client_socket_fd;

  simple_response_event_pair(fd, SERVER_INIT, CLIENT_INIT);

  bool loop = true;
  while(loop) {
    event ev = recv_event(fd);

    switch(ev) {
      case SERVER_QUIT:
        loop = false;
        send_event(fd, CLIENT_ACK);
        break;

      //------------------------------------------------------------------------------------
      // Window and Graphics Device Functions (Module: core)
      //------------------------------------------------------------------------------------

      // Window-related functions
      case CALL_RAYLIB_INITWINDOW:
        handleRaylibInitWindow();
        break;
      case CALL_RAYLIB_WINDOWSHOULDCLOSE:
        handleRaylibWindowShouldClose();
        break;
      case CALL_RAYLIB_CLOSEWINDOW:
        CloseWindow();
        send_event(fd, CLIENT_ACK);
        break;

      // Drawing-related functions
      case CALL_RAYLIB_CLEARBACKGROUND:
        handleRaylibClearBackground();
        break;
      case CALL_RAYLIB_BEGINDRAWING:
        BeginDrawing();
        send_event(fd, CLIENT_ACK);
        break;
      case CALL_RAYLIB_ENDDRAWING:
        EndDrawing();
        send_event(fd, CLIENT_ACK);
        break;

      // Timing-related functions
      case CALL_RAYLIB_SETTARGETFPS:
        handleRaylibSetTargetFPS();
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
        send_event(fd, CLIENT_ERR);
        exit(UNEXPECTED_EVENT);
        break;
    }
  }

  puts("Stopping client");

  close(fd);

  return 0;
}
