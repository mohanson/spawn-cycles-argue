#include <stdint.h>
#include <string.h>

#include "ckb_syscalls.h"

int main() {
  const char *argv[] = {
    "secp256k1_bench",
    "033f8cf9c4d51a33206a6c1c6b27d2cc5129daa19dbd1fc148d395284f6b26411f",
    "304402203679d909f43f073c7c1dcf8468a485090589079ee834e6eed92fea9b09b06a2402201e46f1075afa18f306715e7db87493e7b7e779569aa13c64ab3d09980b3560a3",
    "foo",
    "bar"
  };
  int8_t spawn_exit_code = 255;
  uint8_t spawn_content[80] = {};
  uint64_t spawn_content_length = 80;
  spawn_args_t spgs = {
      .memory_limit = 4,
      .exit_code = &spawn_exit_code,
      .content = &spawn_content[0],
      .content_length = &spawn_content_length,
  };
  for (int i = 0; i < 1024; i++) {
    int success = ckb_spawn(1, 3, 0, 5, argv, &spgs);
    if (success != 0) {
      return 1;
    }
    if (spawn_exit_code != 0) {
      return 1;
    }
  }
  return 0;
}
