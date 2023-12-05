#include <dlfcn.h>

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
