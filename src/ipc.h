#ifndef ipcevents_h
#define ipcevents_h

#include <stdint.h>

// Keep synced with event_names
typedef enum {
  SERVER_INIT,
  SERVER_REQUEST_RESULT,
  SERVER_ACK,
  SERVER_QUIT,
  
  CALL_RAYLIB,
  
  CLIENT_INIT,
  CLIENT_REQUEST_PARAM,
  CLIENT_RESULT_READY,
  CLIENT_ACK,
  CLIENT_ERR,
} event;

extern const char *readWriteErrorMsg;
extern const char *communicationErrorMsg;
extern const char *unexpectedEventMsg;

extern char *event_names[10];

void sendevent(int, event);

event recvevent(int);
void recveventexpected(int, event);

void simplerequesteventpair(int send_fd, int recv_fd, event send_event, event recv_event);
void simpleresponseeventpair(int send_fd, int recv_fd, event recv_event, event send_event);

void sendvar(int, void *, size_t);
void sendvarexpected(int, int, void *, size_t, event);

void recvvar(int, void **, size_t);
void recvvarrequest(int, int, event, void **, size_t);

#endif /* ipcevents_h */
