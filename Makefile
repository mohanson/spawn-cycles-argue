dep/ckb-c-stdlib:
	mkdir -p dep
	cd dep && git clone https://github.com/nervosnetwork/ckb-c-stdlib

dep/ckb-vm-bench-scripts:
	mkdir -p dep
	cd dep && git clone https://github.com/nervosnetwork/ckb-vm-bench-scripts
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

bin/spawn_caller_2m:
	mkdir -p bin
	riscv64-unknown-elf-gcc -O3 -I dep/ckb-c-stdlib -Wall -Werror -g -Wl,-static -fdata-sections -ffunction-sections -Wl,--gc-sections -o bin/spawn_caller_2m c/spawn_caller_2m.c
	riscv64-unknown-elf-objcopy --strip-debug --strip-all bin/spawn_caller_2m

bin/spawn_caller_4m:
	mkdir -p bin
	riscv64-unknown-elf-gcc -O3 -I dep/ckb-c-stdlib -Wall -Werror -g -Wl,-static -fdata-sections -ffunction-sections -Wl,--gc-sections -o bin/spawn_caller_4m c/spawn_caller_4m.c
	riscv64-unknown-elf-objcopy --strip-debug --strip-all bin/spawn_caller_4m

build: \
	dep/ckb-c-stdlib \
	dep/ckb-vm-bench-scripts \
	dep/ckb-vm-bench-scripts/build/secp256k1_bench \
	bin/prime \
	bin/spawn_callee \
	bin/spawn_caller_2m \
	bin/spawn_caller_4m

clean:
	rm -rf bin
	rm -rf dep
