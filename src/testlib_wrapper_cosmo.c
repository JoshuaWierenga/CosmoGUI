#include <stdint.h>
#include <testlib.h>
#include <testlib_wrapper.h>

int32_t add2(int32_t a, int32_t b) {
  Add2Params_t params = {a, b};
  return add2_wrapper(&params);
}
