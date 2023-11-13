#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

typedef enum {
  SERVER_INIT,
  CLIENT_INIT,
} state;

int openfifoclient(char *path, int oflag) {
  int fd = open(path, oflag);
  if (fd < 0) {
    perror("Error");
    exit(-1);
  }
  return fd;
}

int main() {
  int sc_fd = openfifoclient("/tmp/cosmoguisc", O_RDONLY);
  // temp fix for second open being ignored by server
  sleep(1);
  int cs_fd = openfifoclient("/tmp/cosmoguics", O_WRONLY);

  state init[1];
  read(sc_fd, init, sizeof(init));
  if (init[0] != SERVER_INIT) {
    puts("server is non responding correctly");
    return 1;
  }
  puts("received SERVER_INIT");

  init[0] = CLIENT_INIT;
  write(cs_fd, init, sizeof(init));
  puts("sent CLIENT_INIT");

  return 0;
}
