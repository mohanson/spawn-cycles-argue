dep/ckb-c-stdlib:
	mkdir -p dep
	cd dep && git clone https://github.com/XuJiandong/ckb-c-stdlib --branch syscall-spawn

dep/ckb-vm-bench-scripts:
	mkdir -p dep
	cd dep && git clone https://github.com/nervosnetwork/ckb-vm-bench-scripts
	cd dep/ckb-vm-bench-scripts && git checkout dec7aa9
	cd dep/ckb-vm-bench-scripts && git submodule update --init --recursive

dep/ckb-vm-bench-scripts/build/secp256k1_bench:
	cd dep/ckb-vm-bench-scripts && make build/secp256k1_bench

bin/prime:
	mkdir -p bin
	riscv64-unknown-elf-gcc -Idep/ckb-vm-bench-scripts/deps/secp256k1/src \
	                        -Idep/ckb-vm-bench-scripts/deps/secp256k1 \
							-Idep/ckb-vm-bench-scripts/c \
							-O3 -Wl,-static -fdata-sections -ffunction-sections -Wl,--gc-sections -Wl,-s \
							-o bin/prime c/prime.c

bin/spawn_callee:
	mkdir -p bin
	cp dep/ckb-vm-bench-scripts/build/secp256k1_bench bin/spawn_callee

bin/spawn_caller:
	mkdir -p bin
	riscv64-unknown-elf-gcc -O3 -I dep/ckb-c-stdlib -Wall -Werror -g -Wl,-static -fdata-sections -ffunction-sections -Wl,--gc-sections -o bin/spawn_caller c/spawn_caller.c
	riscv64-unknown-elf-objcopy --strip-debug --strip-all bin/spawn_caller

bin/infinite_close:
	mkdir -p bin
	riscv64-unknown-elf-gcc -O3 -I dep/ckb-c-stdlib -Wall -Werror -g -Wl,-static -fdata-sections -ffunction-sections -Wl,--gc-sections -o bin/infinite_close c/infinite_close.c
	riscv64-unknown-elf-objcopy --strip-debug --strip-all bin/infinite_close

build: \
	dep/ckb-c-stdlib \
	dep/ckb-vm-bench-scripts \
	dep/ckb-vm-bench-scripts/build/secp256k1_bench \
	bin/prime \
	bin/spawn_callee \
	bin/spawn_caller

clean:
	rm -rf bin
	rm -rf dep
