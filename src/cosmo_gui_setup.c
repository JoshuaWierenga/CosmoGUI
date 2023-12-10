#ifdef __COSMOPOLITAN__
#include <libc/nt/events.h>
#include <libc/nt/struct/msg.h>
#endif
#include <dlfcn.h>

// Prevent terminal from opening
#if defined(__COSMOPOLITAN__) && defined(DISABLECONSOLE)
void cosmo_force_gui(void) {
  struct NtMsg msg;
  GetMessage(&msg, 0, 0, 0);
}
#endif

void *cosmo_dlopen_wrapper(const char *filename) {
#ifdef __COSMOPOLITAN__
  return cosmo_dlopen(filename, RTLD_LAZY);
#else
  return dlopen(filename, RTLD_LAZY);
#endif
}

#ifndef __COSMOPOLITAN__
void *cosmo_dlsym(void *handle, const char *symbol) {
  return dlsym(handle, symbol);
}
#endif
