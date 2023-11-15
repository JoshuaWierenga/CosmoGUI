#ifndef ipcevents_h
#define ipcevents_h

#include <stdint.h>

// Keep synced with event_names
typedef enum {
  SERVER_INIT,
  SERVER_REQUEST_RESULT,
  SERVER_ACK,
  SERVER_QUIT,

  //------------------------------------------------------------------------------------
  // Window and Graphics Device Functions (Module: core)
  //------------------------------------------------------------------------------------

  // Window-related functions
  CALL_RAYLIB_INITWINDOW,        // Initialize window and OpenGL context
  CALL_RAYLIB_WINDOWSHOULDCLOSE, // Check if KEY_ESCAPE pressed or Close icon pressed
  CALL_RAYLIB_CLOSEWINDOW,       // Close window and unload OpenGL context

  // Drawing-related functions
  CALL_RAYLIB_CLEARBACKGROUND,   // Set background color (framebuffer clear color)
  CALL_RAYLIB_BEGINDRAWING,      // Setup canvas (framebuffer) to start drawing
  CALL_RAYLIB_ENDDRAWING,        // End canvas drawing and swap buffers (double buffering)

  // Timing-related functions
  CALL_RAYLIB_SETTARGETFPS,      // Set target FPS (maximum)

  //------------------------------------------------------------------------------------
  // Font Loading and Text Drawing Functions (Module: text)
  //------------------------------------------------------------------------------------

  // Text drawing functions
  CALL_RAYLIB_DRAWTEXT,          // Draw text (using default font)

  CLIENT_INIT,
  CLIENT_REQUEST_PARAM,
  CLIENT_REQUEST_SIZE,
  CLIENT_RESULT_READY,
  CLIENT_ACK,
  CLIENT_ERR,
} event;

extern const char *readWriteErrorMsg;
extern const char *communicationErrorMsg;
extern const char *unexpectedEventMsg;

extern char *event_names[18];

extern int client_socket_fd;

void send_event(int socketFd, event sendEvent);

event recv_event(int socketFd);
void recv_event_expected(int socketFd, event recvEvent);

void simple_request_event_pair(int socketFd, event sendEvent, event recvEvent);
void simple_response_event_pair(int socketFd, event recvEvent, event sendEvent);

void send_data(int socketFd, void *data, size_t dataLen);
void send_data_expected(int socketFd, void *data, size_t dataLen, event recvEvent);

void recv_data(int socketFd, void **data, size_t dataLen);
void recv_data_request(int socketFd, event send_event, void **data, size_t dataLen);

#endif /* ipcevents_h */
