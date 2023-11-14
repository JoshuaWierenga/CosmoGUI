#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "exitcodes.h"
#include "ipc.h"

#if defined(SERVER)
const char *readWriteErrorMsg = "Unable to communicate with client";
const char *communicationErrorMsg = "Client is non communicating correctly";
const char *unexpectedEventMsg = "Client sent unexpected event";
#elif defined(CLIENT)
const char *readWriteErrorMsg = "Unable to communicate with server";
const char *communicationErrorMsg = "Server is non communicating correctly";
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
  
  "CALL_RAYLIB",
  
  "CLIENT_INIT",
  "CLIENT_REQUEST_PARAM",
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
// 1. Data that fits into a register. Use sendvar/recvvar.
// 2. Structs/arrays of data that fit in registers. Use sendvar/recvvar after casting to an array.
// 3. Structs/arrays of data containing pointers that can either be sent in peices or turned into
//    a single long block of memory. Use sendvar/recvvar but need custom reconstruction at dest.
//    If using a single long block of memory than pointers need to be redetermined using offsets.
// 4. Structs/arrays of data containing pointers that cannot (easily) be turned into a single block
//    of memory but the sender has full control of memory allocation. Use shared memory and then
//    send a pointer with sendvar/recvvar.
// 5. Structs/arrays of data containing pointers that cannot (easily) be turned into a single block
//    of memory and the client does not have control of memory allocation but the server does not
//    need to see or modify the data (only call other client provided functions on it). Store data
//    in client as well as a pointer in a dynamic array and send the index via sendvar/recvvar.
// 6. Structs/arrays of data containing pointers that cannot (easily) be turned into a single block
//    of memory, the client does not have control of memory allocation and the server needs to see
//    or modify the data. Good luck!

void sendvar(int fd, void *var, size_t varlen) {
  printf("Sent var of length %zu\n", varlen);
  ssize_t writelen = write(fd, var, varlen);
  if (writelen != varlen) {
    perror(readWriteErrorMsg);
    exit(READ_WRITE_ERROR);
  }
}

void sendvarexpected(int send_fd, int recv_fd, void *var, size_t varlen, event expected) {
  sendvar(send_fd, var, varlen);
  recveventexpected(recv_fd, expected);
}


void recvvar(int recv_fd, void **dest, size_t destlen) {
  ssize_t readlen = read(recv_fd, dest, destlen);
  if (readlen == -1) {
    perror(readWriteErrorMsg);
    exit(READ_WRITE_ERROR);
  }
  
  if (readlen != destlen) {
    puts(communicationErrorMsg);
    exit(COMMUNICATION_ERROR);
  }
  printf("Received var of length %zu\n", readlen);
}

void recvvarrequest(int send_fd, int recv_fd, event request, void **dest, size_t len) {
  sendevent(send_fd, request);
  recvvar(recv_fd, dest, len);
}
