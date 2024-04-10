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
  int err = 0;
  int8_t spawn_exit_code = 255;
  uint64_t pid = 0;
  uint64_t fds[1] = {0};
  spawn_args_t spgs = {.argc = 5, .argv = argv, .process_id = &pid, .inherited_fds = fds};

  for (int i = 0; i < 1024; i++) {
    err = ckb_spawn(1, 3, 0, 0, &spgs);
    if (err != 0) {
      return 1;
    }
    err = ckb_wait(pid, &spawn_exit_code);
    if (err != 0) {
      return 2;
    }
    if (spawn_exit_code != 0) {
      return 3;
    }
  }
  return 0;
}
