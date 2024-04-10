#include "ckb_syscalls.h"

int main() {
    for (int i = 0; i < 100000000000; i++) {
        ckb_close(i);
    }
    return 0;
}
