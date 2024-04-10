# Spawn Cyclse Argure

本项目提供了三个关于 spawn syscall 的测试用例, 用于评估 spawn syscall 的额外 cycles 消耗. 我计划引入两个关于 cycles 的常量, 分别是

```rs
pub const SPAWN_EXTRA_CYCLES_BASE: u64 = 100_000;
pub const SPAWN_YIELD_CYCLES_BASE: u64 = 800;
```

|   syscall    |                                      cycles                                      |
| ------------ | -------------------------------------------------------------------------------- |
| spawn        | 500 + SPAWN_YIELD_CYCLES_BASE + BYTES_TRANSFERD_CYCLES + SPAWN_EXTRA_CYCLES_BASE |
| pipe         | 500 + SPAWN_YIELD_CYCLES_BASE                                                    |
| inherited_fd | 500 + SPAWN_YIELD_CYCLES_BASE                                                    |
| read         | 500 + SPAWN_YIELD_CYCLES_BASE + BYTES_TRANSFERD_CYCLES                           |
| write        | 500 + SPAWN_YIELD_CYCLES_BASE + BYTES_TRANSFERD_CYCLES                           |
| wait         | 500 + SPAWN_YIELD_CYCLES_BASE                                                    |
| close        | 500 + SPAWN_YIELD_CYCLES_BASE                                                    |
| process_id   | 500                                                                              |

```sh
$ make build
```

```sh
$ tree bin
bin
├── prime           # 该脚本循环执行 1024 次 secp256k1 ecdsa verify
├── spawn_callee    # 该脚本从命令行接受参数并执行一次 secp256k1 ecdsa verify
├── spawn_caller    # 该脚本循环调用 1024 次 spawn_callee
└── infinite_close  # 该脚本循环调用 ckb_close, 没有次数限制
```

之后将如下三个测试用例添加到[此](https://github.com/nervosnetwork/ckb/blob/ckb2023/script/src/verify/tests/ckb_latest/features_since_v2023.rs):

```rs
#[test]
fn check_prime_secp256k1() {
    let script_version = SCRIPT_VERSION;

    let (spawn_caller_cell, spawn_caller_data_hash) =
        load_cell_from_path("/tmp/spawn-cycles-argue/bin/prime");

    let spawn_caller_script = Script::new_builder()
        .hash_type(script_version.data_hash_type().into())
        .code_hash(spawn_caller_data_hash)
        .build();
    let output = CellOutputBuilder::default()
        .capacity(capacity_bytes!(100).pack())
        .lock(spawn_caller_script)
        .build();
    let input = CellInput::new(OutPoint::null(), 0);

    let transaction = TransactionBuilder::default().input(input).build();
    let dummy_cell = create_dummy_cell(output);

    let rtx = ResolvedTransaction {
        transaction,
        resolved_cell_deps: vec![spawn_caller_cell],
        resolved_inputs: vec![dummy_cell],
        resolved_dep_groups: vec![],
    };
    let verifier = TransactionScriptsVerifierWithEnv::new();
    let tic = std::time::SystemTime::now();
    let result = verifier.verify_without_limit(script_version, &rtx);
    let toc = std::time::SystemTime::elapsed(&tic).unwrap();
    println!("{:?} {:?}", toc.as_millis(), result);
    assert_eq!(result.is_ok(), script_version >= ScriptVersion::V2);
}

#[test]
fn check_spawn_secp256k1() {
    let script_version = SCRIPT_VERSION;

    let (spawn_caller_cell, spawn_caller_data_hash) =
        load_cell_from_path("/tmp/spawn-cycles-argue/bin/spawn_caller");
    let (spawn_callee_cell, _spawn_callee_data_hash) =
        load_cell_from_path("/tmp/spawn-cycles-argue/bin/spawn_callee");

    let spawn_caller_script = Script::new_builder()
        .hash_type(script_version.data_hash_type().into())
        .code_hash(spawn_caller_data_hash)
        .build();
    let output = CellOutputBuilder::default()
        .capacity(capacity_bytes!(100).pack())
        .lock(spawn_caller_script)
        .build();
    let input = CellInput::new(OutPoint::null(), 0);

    let transaction = TransactionBuilder::default().input(input).build();
    let dummy_cell = create_dummy_cell(output);

    let rtx = ResolvedTransaction {
        transaction,
        resolved_cell_deps: vec![spawn_caller_cell, spawn_callee_cell],
        resolved_inputs: vec![dummy_cell],
        resolved_dep_groups: vec![],
    };
    let verifier = TransactionScriptsVerifierWithEnv::new();
    let tic = std::time::SystemTime::now();
    let result = verifier.verify_without_limit(script_version, &rtx);
    let toc = std::time::SystemTime::elapsed(&tic).unwrap();
    println!("{:?} {:?}", toc.as_millis(), result);
    assert_eq!(result.is_ok(), script_version >= ScriptVersion::V2);
}

#[test]
fn check_infinite_close() {
    let script_version = SCRIPT_VERSION;

    let (spawn_caller_cell, spawn_caller_data_hash) =
        load_cell_from_path("/tmp/spawn-cycles-argue/bin/infinite_close");

    let spawn_caller_script = Script::new_builder()
        .hash_type(script_version.data_hash_type().into())
        .code_hash(spawn_caller_data_hash)
        .build();
    let output = CellOutputBuilder::default()
        .capacity(capacity_bytes!(100).pack())
        .lock(spawn_caller_script)
        .build();
    let input = CellInput::new(OutPoint::null(), 0);

    let transaction = TransactionBuilder::default().input(input).build();
    let dummy_cell = create_dummy_cell(output);

    let rtx = ResolvedTransaction {
        transaction,
        resolved_cell_deps: vec![spawn_caller_cell],
        resolved_inputs: vec![dummy_cell],
        resolved_dep_groups: vec![],
    };
    let verifier = TransactionScriptsVerifierWithEnv::new();
    let tic = std::time::SystemTime::now();
    let result = verifier.verify(script_version, &rtx, 1127690716);
    let toc = std::time::SystemTime::elapsed(&tic).unwrap();
    println!("{:?} {:?}", toc.as_millis(), result);
    assert_eq!(result.is_ok(), script_version >= ScriptVersion::V2);
}
```

并添加如下代码到[虚拟机运行结束时](https://github.com/nervosnetwork/ckb/blob/ckb2023/script/src/verify.rs#L1018)

```rs
println!("cycles={:?}", machine.machine.cycles());
```

执行测试

```sh
$ cargo test --release -- --nocapture verify::tests::ckb_2023::features_since_v2023::check_prime_secp256k1
$ cargo test --release -- --nocapture verify::tests::ckb_2023::features_since_v2023::check_spawn_secp256k1
$ cargo test --release -- --nocapture verify::tests::ckb_2023::features_since_v2023::check_infinite_close
```

获得测试结果

```text
check_prime_secp256k1: cycles=1127690716 mils=3432
check_spawn_secp256k1: cycles=1796047682 mils=4986
check_infinite_close:  cycles=1127690716 mils=3534
```

可以发现单位时间内消耗的 cycles 数量总体是一致的.
