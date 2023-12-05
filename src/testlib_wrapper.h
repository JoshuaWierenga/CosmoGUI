#include <stdint.h>

// TODO: Add automatic alignment and size checking for all supported arch/libc/os combinations
typedef struct {
  int32_t a, b;
} Add2Params_t;

int32_t add2_wrapper(Add2Params_t *add2params);
