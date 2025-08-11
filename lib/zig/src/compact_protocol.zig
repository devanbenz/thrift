const std = @import("std");
const types = @import("types.zig");
const transport = @import("transport.zig");
const protocol = @import("protocol.zig");
const Protocol = protocol.Protocol;
const ThriftError = ThriftError;
const FieldType = FieldType;
const FieldInfo = FieldInfo;
const ListInfo = ListInfo;

// zigzag encoding and decoding
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

pub const DEFAULT_MAX_MESSAGE_SIZE: usize = 100 * 1024 * 1024;
pub const DEFAULT_MAX_FRAME_SIZE: usize = 16384000;
pub const DEFAULT_TBINARY_STRICT_READ: bool = false;
pub const DEFAULT_TBINARY_STRICT_WRITE: bool = true;
const MESSAGE_ID: u8 = 0x82;
const MESSAGE_VERSION: u8 = 1;

const CompactMessageType = enum(u8) {
    Call = 1,
    Reply = 2,
    Exception = 3,
    Oneway = 4,
};

const CompactMessage = struct { seq: i32, name_len: i32, name: []const u8, type: CompactMessageType };

pub const CompactProtocolError = error{ IncorrectMessageHeader, IncorrectMessageVersion };

pub const CompactProtocol = struct {
    _ttype: types.TType,
    _stream: transport.Transport,
    _buf: []u8,
    _allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, stream: transport.Transport) !CompactProtocol {
        const internal_buf = try allocator.alloc(u8, DEFAULT_MAX_MESSAGE_SIZE);
        return .{ ._ttype = try types.TType.init(allocator), ._stream = stream, ._buf = internal_buf, ._allocator = allocator };
    }

    fn read_byte(self: Self, buf: []u8) !void {
        try self._stream.read_byte(buf);
    }

    fn read_varint(self: Self) !i64 {
        var result: i64 = 0;
        var shift: u6 = 0;
        while (true) {
            const byte = try self.read_byte_direct();
            const a = @as(i64, byte & 0x7f);
            result |= a << shift;

            if ((byte & 0x80) != 0x80) {
                break;
            }

            shift += 7;
        }

        return result;
    }

    fn read_varint_32(self: Self) !i32 {
        const varint_64 = try self.read_varint();
        return @intCast(varint_64);
    }

    pub fn read_byte_direct(self: Self) !u8 {
        var buf = [1]u8{0};
        try self.read_byte(&buf);
        return buf[0];
    }

    pub fn read(self: Self, buf: []u8, len: usize) !void {
        try self._stream.read(buf, len);
    }

    pub fn read_message_begin(self: Self) !CompactMessage {
        // Read protocol ID 0x82
        const id = try self.read_byte_direct();
        if (id != MESSAGE_ID) {
            return CompactProtocolError.IncorrectMessageHeader;
        }

        // Read message type and version
        const next_byte = try self.read_byte_direct();
        const msg_type = next_byte >> 5;
        const msg_version = next_byte & 0b00011111;
        if (msg_version != MESSAGE_VERSION) {
            return CompactProtocolError.IncorrectMessageVersion;
        }

        // Read sequence ID as varint
        const seq_id = try self.read_varint_32();

        // Read name length as varint
        const name_len: usize = @intCast(try self.read_varint_32());

        // Read message name
        const name_buf = try self._allocator.alloc(u8, name_len);
        try self.read(name_buf, name_len);

        return CompactMessage{ .seq = seq_id, .name = name_buf, .name_len = @intCast(name_len), .type = @enumFromInt(msg_type) };
    }

    // Protocol method implementations
    pub fn writeStructBegin(ptr: *anyopaque, name: []const u8) ThriftError!void {
        _ = ptr;
        _ = name;
        // TODO: Implement me!
    }

    pub fn writeStructEnd(ptr: *anyopaque) ThriftError!void {
        _ = ptr;
        // TODO: Implement me!
    }

    pub fn readStructBegin(ptr: *anyopaque) ThriftError![]const u8 {
        _ = ptr;
        // TODO: Implement me!
        return "";
    }

    pub fn readStructEnd(ptr: *anyopaque) ThriftError!void {
        _ = ptr;
        // TODO: Implement me!
    }

    pub fn writeFieldBegin(ptr: *anyopaque, field_id: i16, field_type: FieldType) ThriftError!void {
        _ = ptr;
        _ = field_id;
        _ = field_type;
        // TODO: Implement me!
    }

    pub fn writeFieldEnd(ptr: *anyopaque) ThriftError!void {
        _ = ptr;
        // TODO: Implement me!
    }

    pub fn writeFieldStop(ptr: *anyopaque) ThriftError!void {
        _ = ptr;
        // TODO: Implement me!
    }

    pub fn readFieldBegin(ptr: *anyopaque) ThriftError!FieldInfo {
        _ = ptr;
        // TODO: Implement me!
        return FieldInfo{
            .name = "",
            .field_type = FieldType.BOOL,
            .field_id = 0,
        };
    }

    pub fn readFieldEnd(ptr: *anyopaque) ThriftError!void {
        _ = ptr;
        // TODO: Implement me!
    }

    pub fn writeListBegin(ptr: *anyopaque, element_type: FieldType, size: usize) ThriftError!void {
        _ = ptr;
        _ = element_type;
        _ = size;
        // TODO: Implement me!
    }

    pub fn writeListEnd(ptr: *anyopaque) ThriftError!void {
        _ = ptr;
        // TODO: Implement me!
    }

    pub fn readListBegin(ptr: *anyopaque) ThriftError!ListInfo {
        _ = ptr;
        // TODO: Implement me!
        return ListInfo{
            .element_type = FieldType.BOOL,
            .size = 0,
        };
    }

    pub fn readListEnd(ptr: *anyopaque) ThriftError!void {
        _ = ptr;
        // TODO: Implement me!
    }

    pub fn writeBool(ptr: *anyopaque, value: bool) ThriftError!void {
        _ = ptr;
        _ = value;
        // TODO: Implement me!
    }

    pub fn writeI8(ptr: *anyopaque, value: i8) ThriftError!void {
        _ = ptr;
        _ = value;
        // TODO: Implement me!
    }

    pub fn writeI16(ptr: *anyopaque, value: i16) ThriftError!void {
        _ = ptr;
        _ = value;
        // TODO: Implement me!
    }

    pub fn writeI32(ptr: *anyopaque, value: i32) ThriftError!void {
        _ = ptr;
        _ = value;
        // TODO: Implement me!
    }

    pub fn writeI64(ptr: *anyopaque, value: i64) ThriftError!void {
        _ = ptr;
        _ = value;
        // TODO: Implement me!
    }

    pub fn writeDouble(ptr: *anyopaque, value: f64) ThriftError!void {
        _ = ptr;
        _ = value;
        // TODO: Implement me!
    }

    pub fn writeString(ptr: *anyopaque, value: []const u8) ThriftError!void {
        _ = ptr;
        _ = value;
        // TODO: Implement me!
    }

    pub fn writeBinary(ptr: *anyopaque, value: []const u8) ThriftError!void {
        _ = ptr;
        _ = value;
        // TODO: Implement me!
    }

    pub fn readBool(ptr: *anyopaque) ThriftError!bool {
        _ = ptr;
        // TODO: Implement me!
        return false;
    }

    pub fn readI8(ptr: *anyopaque) ThriftError!i8 {
        _ = ptr;
        // TODO: Implement me!
        return 0;
    }

    pub fn readI16(ptr: *anyopaque) ThriftError!i16 {
        _ = ptr;
        // TODO: Implement me!
        return 0;
    }

    pub fn readI32(ptr: *anyopaque) ThriftError!i32 {
        _ = ptr;
        // TODO: Implement me!
        return 0;
    }

    pub fn readI64(ptr: *anyopaque) ThriftError!i64 {
        _ = ptr;
        // TODO: Implement me!
        return 0;
    }

    pub fn readDouble(ptr: *anyopaque) ThriftError!f64 {
        _ = ptr;
        // TODO: Implement me!
        return 0.0;
    }

    pub fn readString(ptr: *anyopaque, allocator: std.mem.Allocator) ThriftError![]u8 {
        _ = ptr;
        // TODO: Implement me!
        return try allocator.alloc(u8, 0);
    }

    pub fn readBinary(ptr: *anyopaque, allocator: std.mem.Allocator) ThriftError![]u8 {
        _ = ptr;
        // TODO: Implement me!
        return try allocator.alloc(u8, 0);
    }

    pub fn skip(ptr: *anyopaque, field_type: FieldType) ThriftError!void {
        _ = ptr;
        _ = field_type;
        // TODO: Implement me!
    }

    pub fn protocol(self: *Self) Protocol {
        return Protocol{
            .ptr = self,
            .writeStructBeginFn = writeStructBegin,
            .writeStructEndFn = writeStructEnd,
            .readStructBeginFn = readStructBegin,
            .readStructEndFn = readStructEnd,
            .writeFieldBeginFn = writeFieldBegin,
            .writeFieldEndFn = writeFieldEnd,
            .writeFieldStopFn = writeFieldStop,
            .readFieldBeginFn = readFieldBegin,
            .readFieldEndFn = readFieldEnd,
            .writeListBeginFn = writeListBegin,
            .writeListEndFn = writeListEnd,
            .readListBeginFn = readListBegin,
            .readListEndFn = readListEnd,
            .writeBoolFn = writeBool,
            .writeI8Fn = writeI8,
            .writeI16Fn = writeI16,
            .writeI32Fn = writeI32,
            .writeI64Fn = writeI64,
            .writeDoubleFn = writeDouble,
            .writeStringFn = writeString,
            .writeBinaryFn = writeBinary,
            .readBoolFn = readBool,
            .readI8Fn = readI8,
            .readI16Fn = readI16,
            .readI32Fn = readI32,
            .readI64Fn = readI64,
            .readDoubleFn = readDouble,
            .readStringFn = readString,
            .readBinaryFn = readBinary,
            .skipFn = skip,
        };
    }
};

test "test zigzag encoding and decoding" {
    const out_encoded = int_to_zigzag(-20);
    try std.testing.expect(out_encoded == 39);
    const out_decoded = zigzag_to_int(39);
    try std.testing.expect(out_decoded == -20);

    const out_encoded_64 = long_to_zigzag(@as(i64, -20));
    try std.testing.expect(out_encoded_64 == 39);
    const out_decoded_64 = zigzag_to_long(@as(i64, 39));
    try std.testing.expect(out_decoded_64 == -20);
}
