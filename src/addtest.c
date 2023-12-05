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
  test(int, "d", add2(1, 2), 3);
  test(int, "d", add3(1, 2, 3), 6);
  test(int, "d", add4(1, 2, 3, 4), 10);
  test(int, "d", add5(1, 2, 3, 4, 5), 15);
  test(int, "d", add6(1, 2, 3, 4, 5, 6), 21);
}