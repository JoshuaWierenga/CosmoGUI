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

#ifdef __COSMOPOLITAN__
//#define mkfifo(path, mode) mknod(path, mode | S_IFIFO, 0)
int32_t sys_mknod(const char *, uint32_t, uint64_t);
#endif


typedef enum {
  SERVER_INIT,
  CLIENT_INIT,
} state;

int openfifoserver(char *path, mode_t mode, int oflag) {
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

int main() {
  int sc_fd = openfifoserver("/tmp/cosmoguisc", 0600, O_WRONLY);
  int cs_fd = openfifoserver("/tmp/cosmoguics", 0600, O_RDONLY);

  state init[1] = { SERVER_INIT };
  write(sc_fd, init, sizeof(init));
  puts("sent SERVER_INIT");

  ssize_t test = read(cs_fd, init, sizeof(init));
  if (test == -1) {
    printf("%i: %m\n", errno);
  }

  if (*init != CLIENT_INIT) {
    puts("client is non responding correctly");
    return 1;
  }
  puts("received CLIENT_INIT");

  close(sc_fd);
  close(cs_fd);

  return 0;
}
