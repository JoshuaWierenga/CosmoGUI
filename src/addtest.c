#include <assert.h>
#include <stdio.h>
#include <testlib.h>

#define test(type, specifier, actual, expected) { \
  type act = actual;\
  type exp = expected;\
  printf(#actual " = %d\n", act);\
  assert(act == exp);\
}
int main(void) {
  test(int32_t, PRId32, add2(1, 2), 3);
  test(int32_t, PRId32, add3(1, 2, 3), 6);
  test(int32_t, PRId32, add4(1, 2, 3, 4), 10);
  test(int32_t, PRId32, add5(1, 2, 3, 4, 5), 15);
  test(int32_t, PRId32, add6(1, 2, 3, 4, 5, 6), 21);
  test(int32_t, PRId32, add7(1, 2, 3, 4, 5, 6, 7), 28);
}
