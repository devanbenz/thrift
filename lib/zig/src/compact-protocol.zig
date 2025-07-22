const std = @import("std");

pub const DEFAULT_MAX_MESSAGE_SIZE: i32 = 100 * 1024 * 1024;
pub const DEFAULT_MAX_FRAME_SIZE: i32 = 16384000;
pub const DEFAULT_TBINARY_STRICT_READ: bool = false;
pub const DEFAULT_TBINARY_STRICT_WRITE: bool = true;

pub const CompactProtocol = struct {
    pub fn init() CompactProtocol {}
};
