const std = @import("std");
const types = @import("types.zig");
const transport = @import("transport.zig");

pub const CompactProtocol = struct {
    _ttype: types.TType,
    _stream: transport.Transport,
    _buf: []u8,

    const Self = @This();

    pub const DEFAULT_MAX_MESSAGE_SIZE: i32 = 100 * 1024 * 1024;
    pub const DEFAULT_MAX_FRAME_SIZE: i32 = 16384000;
    pub const DEFAULT_TBINARY_STRICT_READ: bool = false;
    pub const DEFAULT_TBINARY_STRICT_WRITE: bool = true;

    const MESSAGE_ID: u8 = 0x82;

    const CompactMessage = struct { seq: i32, name_len: i32, name: []const u8 };
    const CompactMessageType = enum(u8) {
        Call = 1,
        Reply = 2,
        Exception = 3,
        Oneway = 4,
    };

    pub fn init(allocator: std.mem.Allocator, stream: transport.Transport) CompactProtocol {
        const internal_buf = try allocator.alloc(u8, DEFAULT_MAX_MESSAGE_SIZE);
        return .{ ._ttype = types.TType.init(allocator), ._stream = stream, ._buf = internal_buf };
    }

    fn int_to_zigzag(n: i32) i32 {
        return (n << 1) ^ (n >> 31);
    }

    fn zigzag_to_int(n: i32) i32 {
        return (n >> 1) ^ -(n & 1);
    }

    fn long_to_zigzag(n: i64) i64 {
        return (n << 1) ^ (n >> 63);
    }

    fn zigzag_to_long(n: i64) i64 {
        return (n >> 1) ^ -(n & 1);
    }

    fn read_byte(self: Self, buf: []u8) !void {
        try self._stream.read_byte(buf);
    }

    fn read(self: Self, buf: []u8, len: usize) !void {
        try self._stream.read(buf, len);
    }

    pub fn read_message_begin(self: Self) !CompactMessage {
        // Read protocol ID

    }
};
