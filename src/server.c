#ifdef __COSMOPOLITAN__
#include <cosmo.h>
#endif
#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
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
   Server: CALL_ADD
   Client: CLIENT_REQUEST_PARAM
   Server: a
   Client: CLIENT_REQUEST_PARAM
   Server: b
   Client: CLIENT_RESULT_READY
   Server: SERVER_REQUEST_RESULT
   Client: res
   Server: SERVER_ACK */
static int32_t add(int32_t a, int32_t b) {
  int32_t res;
  
  simplerequesteventpair(sc_fd, cs_fd, CALL_ADD, CLIENT_REQUEST_PARAM);
  sendvarexpected(sc_fd, cs_fd, (void *)&a, sizeof(a), CLIENT_REQUEST_PARAM);
  sendvarexpected(sc_fd, cs_fd, (void *)&b, sizeof(b), CLIENT_RESULT_READY);
  recvvarrequest(sc_fd, cs_fd, SERVER_REQUEST_RESULT, (void *)&res, sizeof(res));
  sendevent(sc_fd, SERVER_ACK);
  
  return res;
}

int main() {
  puts("Starting server");
  
  sc_fd = openfifoserver("/tmp/cosmoguisc", 0600, O_WRONLY);
  cs_fd = openfifoserver("/tmp/cosmoguics", 0600, O_RDONLY);

  simplerequesteventpair(sc_fd, cs_fd, SERVER_INIT, CLIENT_INIT);

  int32_t res = add(3, 5);
  printf("3 + 5 = %" PRId32 "\n", res);

  simplerequesteventpair(sc_fd, cs_fd, SERVER_QUIT, CLIENT_ACK);

  puts("Stopping server");

  close(sc_fd);
  close(cs_fd);

  return 0;
}
