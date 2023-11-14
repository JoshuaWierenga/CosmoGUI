#include <dummy.h>
#include <fcntl.h>
#include <inttypes.h>
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

/* Process:
   Server: CALL_ADD
   Client: CLIENT_REQUEST_PARAM
   Server: a
   Client: CLIENT_REQUEST_PARAM
   Server: b
   Client: CLIENT_RESULT_READY
   Server: SERVER_REQUEST_RESULT
   Client: res
   Server: SERVER_ACK */
static void handleAddEvent() {
  uint32_t a, b, res;
  recvvarrequest(cs_fd, sc_fd, CLIENT_REQUEST_PARAM, (void **)&a, sizeof(a));
  recvvarrequest(cs_fd, sc_fd, CLIENT_REQUEST_PARAM, (void **)&b, sizeof(b));
  
  printf("a = %" PRId32 ", b = %" PRId32 "\n", a, b);
  res = add(a, b);
  printf("res = %" PRId32 "\n", res);
  simplerequesteventpair(cs_fd, sc_fd, CLIENT_RESULT_READY, SERVER_REQUEST_RESULT);
  
  sendvarexpected(cs_fd, sc_fd, &res, sizeof(res), SERVER_ACK);
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
      case CALL_ADD:
        handleAddEvent();
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
