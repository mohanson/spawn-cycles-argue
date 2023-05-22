# Spawn Cyclse Argure

本项目提供了三个关于 spawn syscall 的测试用例, 用于评估 spawn syscall 的额外 cycles 消耗.

```sh
$ make build
```

```sh
$ tree bin
bin
├── prime           # 该脚本循环执行 1024 次 secp256k1 ecdsa verify
├── spawn_callee    # 该脚本从命令行接受参数并执行一次 secp256k1 ecdsa verify
├── spawn_caller_2m # 该脚本循环调用 1024 次 spawn_callee, 子虚拟机设置 2m 内存
└── spawn_caller_4m # 该脚本循环调用 1024 次 spawn_callee, 子虚拟机设置 4m 内存
```

之后将如下三个测试用例添加到[此](https://github.com/nervosnetwork/ckb/blob/ckb2023/script/src/verify/tests/ckb_latest/features_since_v2023.rs):

```rs
#[test]
fn check_spawn_secp256k1_2m() {
    let script_version = SCRIPT_VERSION;

    let (spawn_caller_cell, spawn_caller_data_hash) =
        load_cell_from_path("/tmp/spawn-cycles-argue/bin/spawn_caller_2m");
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
    println!("{:?}", toc.as_millis());
    assert_eq!(result.is_ok(), script_version >= ScriptVersion::V2);
}

#[test]
fn check_spawn_secp256k1_4m() {
    let script_version = SCRIPT_VERSION;

    let (spawn_caller_cell, spawn_caller_data_hash) =
        load_cell_from_path("/tmp/spawn-cycles-argue/bin/spawn_caller_4m");
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
    println!("{:?}", toc.as_millis());
    assert_eq!(result.is_ok(), script_version >= ScriptVersion::V2);
}

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
    println!("{:?}", toc.as_millis());
    assert_eq!(result.is_ok(), script_version >= ScriptVersion::V2);
}
```

并添加如下代码到[虚拟机运行结束时](https://github.com/nervosnetwork/ckb/blob/ckb2023/script/src/verify.rs#L1018)

```rs
println!("cycles={:?}", machine.machine.cycles());
```

执行测试

```sh
$ cargo test --release -- --nocapture verify::tests::ckb_2023::features_since_v2023::check_spawn_secp256k1_2m
$ cargo test --release -- --nocapture verify::tests::ckb_2023::features_since_v2023::check_spawn_secp256k1_4m
$ cargo test --release -- --nocapture verify::tests::ckb_2023::features_since_v2023::check_prime_secp256k1
```

获得测试结果

```text
check_spawn_secp256k1_2m: cycles=1410654032 mils=4705
check_spawn_secp256k1_4m: cycles=1410654032 mils=4693
check_prime_secp256k1:    cycles=1127690716 mils=3432
```

可以发现:

1. 子虚拟机内存设置为 2m 还是 4m, 对整体运行时间几乎没有影响.
2. 对于 secp256k1 来说, spawn syscall 如果额外消耗 `(1127690716 / 3432 * 4693 - 1410654032) / 1024 = 128298`, 那么单位时间内两者消耗的 cycles 将基本相同.

我建议将 spawn syscall 的额外 syscall 消耗分为两个部分, 分别是固定消耗和内存消耗, 公式为

```
spawn_cycles = 100000 + memory_size_in_bytes / 64
```
