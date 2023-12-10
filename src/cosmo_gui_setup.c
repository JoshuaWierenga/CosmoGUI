#ifdef __COSMOPOLITAN__
#include <cosmo.h>
#include <libc/nt/events.h>
#include <libc/nt/struct/msg.h>
#endif
#include <dlfcn.h>
#include <limits.h>
#include <string.h>
#include <unistd.h>

// Prevent terminal from opening
#if defined(__COSMOPOLITAN__) && defined(DISABLECONSOLE)
void cosmo_force_gui(void) {
  struct NtMsg msg;
  GetMessage(&msg, 0, 0, 0);
}
#endif

void *cosmo_dlopen_wrapper(const char *filename) {
#ifdef __COSMOPOLITAN__
  void *handle = cosmo_dlopen(filename, RTLD_LAZY);
  if (handle) {
    return handle;
  }

  char path[PATH_MAX];
  char *execPath = GetProgramExecutableName();
  if (!execPath) {
    return NULL;
  }

  char *lastSlash = strrchr(execPath, '/');
  strcpy(path, execPath);
  strcpy(path + (lastSlash - execPath + 1), filename);

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
