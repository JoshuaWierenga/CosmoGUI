#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "exitcodes.h"
#include "ipc.h"

#if defined(SERVER)
const char *readWriteErrorMsg = "Unable to communicate with client";
const char *communicationErrorMsg = "Client is not communicating correctly";
const char *unexpectedEventMsg = "Client sent unexpected event";
#elif defined(CLIENT)
const char *readWriteErrorMsg = "Unable to communicate with server";
const char *communicationErrorMsg = "Server is not communicating correctly";
const char *unexpectedEventMsg = "Server sent unexpected event";
#else
#error Need endpoint type
#endif

// Keep synced with event enum
char *event_names[] = {
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

void sendevent(int fd, event ev) {
  printf("Sent %s\n", event_names[ev]);
  ssize_t len = write(fd, &ev, sizeof(ev));
  if (len != sizeof(ev)) {
    perror(readWriteErrorMsg);
    exit(READ_WRITE_ERROR);
  }
}


event recvevent(int fd) {
  event ev;
  ssize_t len = read(fd, &ev, sizeof(ev));
  if (len == -1) {
    perror(readWriteErrorMsg);
    exit(READ_WRITE_ERROR);
  }

  if (len != sizeof(ev)) {
    puts(communicationErrorMsg);
    exit(COMMUNICATION_ERROR);
  }
  printf("Received %s\n", event_names[ev]);

  return ev;
}

void recveventexpected(int fd, event expected) {
  event ev = recvevent(fd);
  if (ev != expected) {
    puts(unexpectedEventMsg);
    exit(UNEXPECTED_EVENT);
  }
}


void simplerequesteventpair(int send_fd, int recv_fd, event send_event, event recv_event) {
  sendevent(send_fd, send_event);
  recveventexpected(recv_fd, recv_event);
}

void simpleresponseeventpair(int send_fd, int recv_fd, event recv_event, event send_event) {
  recveventexpected(recv_fd, recv_event);
  sendevent(send_fd, send_event);
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

void senddata(int fd, void *var, size_t varlen) {
  printf("Sent %zu bytes\n", varlen);
  ssize_t writelen = write(fd, var, varlen);
  if (writelen != varlen) {
    perror(readWriteErrorMsg);
    exit(READ_WRITE_ERROR);
  }
}

void senddataexpected(int send_fd, int recv_fd, void *var, size_t varlen, event expected) {
  senddata(send_fd, var, varlen);
  recveventexpected(recv_fd, expected);
}


void recvdata(int recv_fd, void **dest, size_t destlen) {
  ssize_t readlen = read(recv_fd, dest, destlen);
  if (readlen == -1) {
    perror(readWriteErrorMsg);
    exit(READ_WRITE_ERROR);
  }

  if (readlen != destlen) {
    puts(communicationErrorMsg);
    exit(COMMUNICATION_ERROR);
  }
  printf("Received %zu bytes\n", readlen);
}

void recvdatarequest(int send_fd, int recv_fd, event request, void **dest, size_t len) {
  sendevent(send_fd, request);
  recvdata(recv_fd, dest, len);
}
