const std = @import("std");
const types = @import("types.zig");

pub const CompactProtocol = struct {
    _ttype: types.TType,

    _stream: std.net.

    pub const DEFAULT_MAX_MESSAGE_SIZE: i32 = 100 * 1024 * 1024;
    pub const DEFAULT_MAX_FRAME_SIZE: i32 = 16384000;
    pub const DEFAULT_TBINARY_STRICT_READ: bool = false;
    pub const DEFAULT_TBINARY_STRICT_WRITE: bool = true;

    pub fn init(allocator: std.mem.Allocator) CompactProtocol {
        return .{ ._ttype = types.TType.init(allocator) };
    }

    pub fn read_byte(self: @This()) !u8 {}
};
