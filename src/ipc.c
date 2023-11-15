#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "exitcodes.h"
#include "ipc.h"

//#define SHOW_EVENT_INFO
//#define SHOW_READ_WRITE_SIZES

#if defined(SERVER)
const char *name = "Server";
const char *readWriteErrorMsg = "Unable to communicate with client";
const char *communicationErrorMsg = "Client is not communicating correctly";
const char *unexpectedEventMsg = "Client sent unexpected event";
#elif defined(CLIENT)
const char *name = "Client";
const char *readWriteErrorMsg = "Unable to communicate with server";
const char *communicationErrorMsg = "Server is not communicating correctly";
const char *unexpectedEventMsg = "Server sent unexpected event";
#else
#error Need endpoint type
#endif

int clientSocketFd = 4;

// Keep synced with event enum
char *eventNames[] = {
  "SERVER_INIT",
  "SERVER_REQUEST_RESULT",
  "SERVER_ACK",
  "SERVER_EXIT",

  //------------------------------------------------------------------------------------
  // Window and Graphics Device Functions (Module: core)
  //------------------------------------------------------------------------------------

  // Window-related functions
  "CALL_RAYLIB_INITWINDOW",        // Initialize window and OpenGL context
  "CALL_RAYLIB_WINDOWSHOULDCLOSE", // Check if KEY_ESCAPE pressed or Close icon pressed
  "CALL_RAYLIB_CLOSEWINDOW",       // Close window and unload OpenGL contex

  // Drawing-related functions
  "CALL_RAYLIB_CLEARBACKGROUND",   // Set background color (framebuffer clear color)
  "CALL_RAYLIB_BEGINDRAWING",      // Setup canvas (framebuffer) to start drawing
  "CALL_RAYLIB_ENDDRAWING",        // End canvas drawing and swap buffers (double buffering)

  // Timing-related functions
  "CALL_RAYLIB_SETTARGETFPS",      // Set target FPS (maximum)

  //------------------------------------------------------------------------------------
  // Font Loading and Text Drawing Functions (Module: text)
  //------------------------------------------------------------------------------------

  // Text drawing functions
  "CALL_RAYLIB_DRAWTEXT",          // Draw text (using default font)

  "CLIENT_INIT",
  "CLIENT_REQUEST_PARAM",
  "CLIENT_REQUEST_SIZE",
  "CLIENT_RESULT_READY",
  "CLIENT_ACK",
  "CLIENT_ERR",
};

// TODO: Replace all exits with returns so that the server/client can report the error

void send_event(int socketFd, event sendEvent) {
#ifdef SHOW_EVENT_INFO
  printf("%s sent %s\n", name, eventNames[sendEvent]);
#endif
  ssize_t len = write(socketFd, &sendEvent, sizeof(sendEvent));
  if (len != sizeof(sendEvent)) {
    perror(readWriteErrorMsg);
    exit(READ_WRITE_ERROR);
  }
}


event recv_event(int socketFd) {
  event recvEvent;
  ssize_t len = read(socketFd, &recvEvent, sizeof(recvEvent));
  if (len == -1) {
    perror(readWriteErrorMsg);
    exit(READ_WRITE_ERROR);
  }

  if (len != sizeof(recvEvent)) {
    puts(communicationErrorMsg);
    exit(COMMUNICATION_ERROR);
  }
  
#ifdef SHOW_EVENT_INFO
  printf("%s received %s\n", name, eventNames[recvEvent]);
#endif

  return recvEvent;
}

void recv_event_expected(int socketFd, event recvEvent) {
  event ev = recv_event(socketFd);
  if (ev != recvEvent) {
    puts(unexpectedEventMsg);
    exit(UNEXPECTED_EVENT);
  }
}


void simple_request_event_pair(int socketFd, event sendEvent, event recvEvent) {
  send_event(socketFd, sendEvent);
  recv_event_expected(socketFd, recvEvent);
}

void simple_response_event_pair(int socketFd, event recvEvent, event sendEvent) {
  recv_event_expected(socketFd, recvEvent);
  send_event(socketFd, sendEvent);
}

// There are 6 kinds of data relevant to this system:
// 1. Data that fits into a register. Use senddata/recvdata.
// 2. Structs/arrays of data that fit in registers. Use senddata/recvdata after casting to an array.
// 3. Structs/arrays of data containing pointers that can either be sent in peices or turned into
//    a single long block of memory. Use senddata/recvdata but need custom reconstruction at dest.
//    If using a single long block of memory than pointers need to be redetermined using offsets.
// 4. Structs/arrays of data containing pointers that cannot (easily) be turned into a single block
//    of memory but the sender has full control of memory allocation. Use shared memory and then
//    send a pointer with senddata/recvdata.
// 5. Structs/arrays of data containing pointers that cannot (easily) be turned into a single block
//    of memory and the client does not have control of memory allocation but the server does not
//    need to see or modify the data (only call other client provided functions on it). Store data
//    in client as well as a pointer in a dynamic array and send the index via senddata/recvdata.
// 6. Structs/arrays of data containing pointers that cannot (easily) be turned into a single block
//    of memory, the client does not have control of memory allocation and the server needs to see
//    or modify the data. Good luck!

void send_data(int socketFd, void *data, size_t dataLen) {
  ssize_t writeLen = write(socketFd, data, dataLen);
  if (writeLen != dataLen) {
    perror(readWriteErrorMsg);
    exit(READ_WRITE_ERROR);
  }
  
#ifdef SHOW_READ_WRITE_SIZES
  printf("%s sent %zu bytes\n", name, dataLen);
#endif
}

void send_data_expected(int socketFd, void *data, size_t dataLen, event recvEvent) {
  send_data(socketFd, data, dataLen);
  recv_event_expected(socketFd, recvEvent);
}


void recv_data(int socketFd, void **data, size_t dataLen) {
  ssize_t readLen = read(socketFd, data, dataLen);
  if (readLen == -1) {
    perror(readWriteErrorMsg);
    exit(READ_WRITE_ERROR);
  }

  if (readLen != dataLen) {
    puts(communicationErrorMsg);
    exit(COMMUNICATION_ERROR);
  }

#ifdef SHOW_READ_WRITE_SIZES
  printf("%s received %zu bytes\n", name, readLen);
#endif
}

void recv_data_request(int socketFd, event sendEvent, void **data, size_t dataLen) {
  send_event(socketFd, sendEvent);
  recv_data(socketFd, data, dataLen);
}
