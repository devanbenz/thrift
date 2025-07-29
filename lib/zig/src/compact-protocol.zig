const std = @import("std");
const types = @import("types.zig");
const transport = @import("transport.zig");
const test_utils = @import("test_utils.zig");

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

pub const CompactProtocol = struct {
    _ttype: types.TType,
    _stream: transport.Transport,
    _buf: []u8,

    const Self = @This();

    pub const DEFAULT_MAX_MESSAGE_SIZE: usize = 100 * 1024 * 1024;
    pub const DEFAULT_MAX_FRAME_SIZE: usize = 16384000;
    pub const DEFAULT_TBINARY_STRICT_READ: bool = false;
    pub const DEFAULT_TBINARY_STRICT_WRITE: bool = true;

    const MESSAGE_ID: u8 = 0x82;

    const CompactMessageType = enum(u8) {
        Call = 1,
        Reply = 2,
        Exception = 3,
        Oneway = 4,
    };

    const CompactMessage = struct { seq: i32, name_len: i32, name: []const u8, type: CompactMessageType };

    pub fn init(allocator: std.mem.Allocator, stream: transport.Transport) !CompactProtocol {
        const internal_buf = try allocator.alloc(u8, DEFAULT_MAX_MESSAGE_SIZE);
        return .{ ._ttype = try types.TType.init(allocator), ._stream = stream, ._buf = internal_buf };
    }

    fn read_byte(self: Self, buf: []u8) !void {
        try self._stream.read_byte(buf);
    }

    fn read(self: Self, buf: []u8, len: usize) !void {
        try self._stream.read(buf, len);
    }

    pub fn read_message_begin() !CompactMessage {
        // Read protocol ID

    }
};

test "test zigzag encoding and decoding" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var test_reader = test_utils.TestReader.init("TEST");
    const test_transport = try transport.Transport.init(test_reader.transport_reader());

    _ = try CompactProtocol.init(allocator, test_transport);

    const out_encoded = int_to_zigzag(-20);
    try std.testing.expect(out_encoded == 39);
    const out_decoded = zigzag_to_int(39);
    try std.testing.expect(out_decoded == -20);

    const out_encoded_64 = long_to_zigzag(@as(i64, -20));
    try std.testing.expect(out_encoded_64 == 39);
    const out_decoded_64 = zigzag_to_long(@as(i64, 39));
    try std.testing.expect(out_decoded_64 == -20);
}
