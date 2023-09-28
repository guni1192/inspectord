#![no_std]
#![no_main]

use aya_bpf::{
    macros::{map, tracepoint},
    maps::PerfEventArray,
    programs::TracePointContext,
    BpfContext,
};

use aya_log_ebpf::info;
use inspectord_common::ExecveLog;

#[map(name = "EVENTS")]
static mut EVENTS: PerfEventArray<ExecveLog> =
    PerfEventArray::<ExecveLog>::with_max_entries(1024, 0);

#[tracepoint]
pub fn inspectord(ctx: TracePointContext) -> u32 {
    match try_inspectord(ctx) {
        Ok(ret) => ret,
        Err(ret) => ret as u32,
    }
}

fn try_inspectord(ctx: TracePointContext) -> Result<u32, i64> {
    let uid = ctx.uid();
    let gid = ctx.gid();

    if uid != 0 && gid != 0 {
        return Ok(0);
    }

    let pid = ctx.pid();
    let comm = ctx.command()?;
    // comm: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],

    let mut entry = ExecveLog {
        pid,
        uid,
        gid,
        comm,
    };
    entry.comm[..comm.len()].copy_from_slice(&comm);

    unsafe { EVENTS.output(&ctx, &entry, 0) };

    info!(&ctx, "execve: pid: {}, uid: {}, gid: {}", pid, uid, gid);

    Ok(0)
}

#[panic_handler]
fn panic(_info: &core::panic::PanicInfo) -> ! {
    unsafe { core::hint::unreachable_unchecked() }
}
