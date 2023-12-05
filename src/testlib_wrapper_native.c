#include <stdint.h>
#include <testlib.h>

#include "testlib_wrapper.h"

int32_t add2_wrapper(Add2Params_t *add2params) {
  return add2(add2params->a, add2params->b);
}
