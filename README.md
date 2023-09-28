# inspectord

## Prerequisites

1. Install bpf-linker: `cargo install bpf-linker`

## Build eBPF

```bash
cargo xtask build-ebpf
```

To perform a release build you can use the `--release` flag.
You may also change the target architecture with the `--target` flag.

## Build Userspace

```bash
cargo build
```

## Run

```bash
RUST_LOG=info cargo xtask run
```

```bash
docker run \
    -v /usr/src:/usr/src:ro \
    -v /lib/modules/:/lib/modules:ro \
    -v /sys/kernel/debug/:/sys/kernel/debug:rw \
    -e RUST_BACKTRACE=1 \
    -e RUST_LOG=info \
    --net=host \
    --pid=host \
    --cap-add CAP_BPF \
    --cap-add CAP_SYS_ADMIN \
    guni1192/inspectord
```
