#include <stdint.h>

// TODO: Automate wrapper generation
// TODO: Add automatic alignment and size checking for all supported arch/libc/os combinations
typedef struct {
  int32_t a, b;
} Add2Params_t;

typedef struct {
  int32_t a, b, c;
} Add3Params_t;

typedef struct {
  int32_t a, b, c, d;
} Add4Params_t;

typedef struct {
  int32_t a, b, c, d, e;
} Add5Params_t;

typedef struct {
  int32_t a, b, c, d, e, f;
} Add6Params_t;

typedef struct {
  int32_t a, b, c, d, e, f, g;
} Add7Params_t;

int32_t add2_wrapper(Add2Params_t *add2params);
int32_t add3_wrapper(Add3Params_t *add3params);
int32_t add4_wrapper(Add4Params_t *add4params);
int32_t add5_wrapper(Add5Params_t *add5params);
int32_t add6_wrapper(Add6Params_t *add6params);
int32_t add7_wrapper(Add7Params_t *add7params);
