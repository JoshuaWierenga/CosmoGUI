#include <stdint.h>
#include <testlib.h>
#include <testlib_wrapper.h>

int32_t add2(int32_t a, int32_t b) {
  Add2Params_t params = {a, b};
  return add2_wrapper(&params);
}

int32_t add3(int32_t a, int32_t b, int32_t c) {
  Add3Params_t params = {a, b, c};
  return add3_wrapper(&params);
}

int32_t add4(int32_t a, int32_t b, int32_t c, int32_t d) {
  Add4Params_t params = {a, b, c, d};
  return add4_wrapper(&params);
}

int32_t add5(int32_t a, int32_t b, int32_t c, int32_t d, int32_t e) {
  Add5Params_t params = {a, b, c, d, e};
  return add5_wrapper(&params);
}

int32_t add6(int32_t a, int32_t b, int32_t c, int32_t d, int32_t e, int32_t f) {
  Add6Params_t params = {a, b, c, d, e, f};
  return add6_wrapper(&params);
}

int32_t add7(int32_t a, int32_t b, int32_t c, int32_t d, int32_t e, int32_t f, int32_t g) {
  Add7Params_t params = {a, b, c, d, e, f, g};
  return add7_wrapper(&params);
}
