#include <stdint.h>
#include <testlib.h>

#include "testlib_wrapper.h"

int32_t add2_wrapper(Add2Params_t *add2params) {
  return add2(add2params->a, add2params->b);
}

int32_t add3_wrapper(Add3Params_t *add3params) {
  return add3(add3params->a, add3params->b, add3params->c);
}

int32_t add4_wrapper(Add4Params_t *add4params) {
  return add4(add4params->a, add4params->b, add4params->c, add4params->d);
}

int32_t add5_wrapper(Add5Params_t *add5params) {
  return add5(add5params->a, add5params->b, add5params->c, add5params->d, add5params->e);
}

int32_t add6_wrapper(Add6Params_t *add6params) {
  return add6(add6params->a, add6params->b, add6params->c, add6params->d, add6params->e, add6params->f);
}

int32_t add7_wrapper(Add7Params_t *add7params) {
  return add7(add7params->a, add7params->b, add7params->c, add7params->d, add7params->e, add7params->f, add7params->g);
}
