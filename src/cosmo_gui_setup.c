#ifdef __COSMOPOLITAN__
#include <cosmo.h>
#include <libc/nt/events.h>
#include <libc/nt/struct/msg.h>
#endif
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#if defined(__COSMOPOLITAN__)
// Prevent terminal from opening on windows
#if defined(DISABLECONSOLE)
static void cosmo_force_gui(void) {
  struct NtMsg msg;
  GetMessage(&msg, 0, 0, 0);
}
#endif

static char linuxLibPath[] = "/tmp/XXXXXX.so";
static char windowsLibPath[] = "/tmp/XXXXXX.dll";
static int linuxLibPathSuffixLen = 3; // strlen(".so")
static int windowsLibPathSuffixLen = 4; // strlen(".dll")

void delete_library(void) {
  if (IsLinux()) {
    unlink(linuxLibPath);
  } else if (IsWindows()) {
    unlink(windowsLibPath);
  }
}

static char *extract_lib(const char *filename) {
  char *libPath;
  int libPathSuffixLen;
  char zipPath[PATH_MAX] = "/zip/";
  strlcpy(zipPath + 5, filename, sizeof(zipPath) - 5); // strlen("/zip/")
  if (IsLinux()) {
    libPath = linuxLibPath;
    libPathSuffixLen = linuxLibPathSuffixLen;
  } else if (IsWindows()) {
    libPath = windowsLibPath;
    libPathSuffixLen = windowsLibPathSuffixLen;
  } else {
    fprintf(stderr, "Dynamic loading is not supported on this OS");
    exit(1);
  }

  // From libc/testlib/extract.c
  int zipFd, libFd;
  if ((zipFd = open(zipPath, O_RDONLY)) == -1) {
    if (ENOENT == errno) {
      return NULL;
    }
    perror(zipPath);
    exit(1);
  }
  if ((libFd = openatemp(AT_FDCWD, libPath, libPathSuffixLen, 0, 0)) == -1) {
    perror(libPath);
    exit(1);
  }
  if (copyfd(zipFd, libFd, -1) == -1) {
    perror(zipPath);
    exit(1);
  }
  if (close(libFd)) {
    perror(libPath);
    exit(1);
  }
  if (close(zipFd)) {
    perror(zipPath);
    exit(1);
  }

  atexit(delete_library);
  return libPath;
}
#endif

void *cosmo_dlopen_wrapper(const char *filename) {
#ifdef __COSMOPOLITAN__
  char *tmpLib = extract_lib(filename);
  void *handle = cosmo_dlopen(tmpLib, RTLD_LAZY);
  if (handle) {
    return handle;
  }

  handle = cosmo_dlopen(filename, RTLD_LAZY);
  if (handle) {
    return handle;
  }

  char path[PATH_MAX];
  char *execPath = GetProgramExecutableName();
  if (!execPath) {
    return NULL;
  }

  char *lastSlash = strrchr(execPath, '/');
  size_t offset = lastSlash - execPath + 1;
  strlcpy(path, execPath, sizeof(path));
  strlcpy(path + offset, filename, sizeof(path) - offset);

  return cosmo_dlopen(path, RTLD_LAZY);
#else
  return dlopen(filename, RTLD_LAZY);
#endif
}

#ifndef __COSMOPOLITAN__
void *cosmo_dlsym(void *handle, const char *symbol) {
  return dlsym(handle, symbol);
}
#endif
