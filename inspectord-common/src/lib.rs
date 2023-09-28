#![no_std]

#[repr(C)]
#[derive(Copy, Clone)]
pub struct ExecveLog {
    pub pid: u32,
    pub uid: u32,
    pub gid: u32,
    pub comm: [u8; 16],
}

#[cfg(feature = "user")]
unsafe impl aya::Pod for ExecveLog {}
