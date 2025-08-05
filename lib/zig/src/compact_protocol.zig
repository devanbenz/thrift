const std = @import("std");
const types = @import("types.zig");
const transport = @import("transport.zig");

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

// TODO: Stub this out for compact_protocol

pub const ThriftError = error{
    ProtocolError,
    OutOfMemory,
    InvalidData,
    UnexpectedEof,
};

pub const FieldType = enum(u8) {
    BOOL = 2,
    I8 = 3,
    DOUBLE = 4,
    I16 = 6,
    I32 = 8,
    I64 = 10,
    STRING = 11,
    STRUCT = 12,
    MAP = 13,
    SET = 14,
    LIST = 15,
};

pub const FieldInfo = struct {
    name: []const u8,
    field_type: FieldType,
    field_id: i16,
};

pub const ListInfo = struct {
    element_type: FieldType,
    size: u32,
};

pub const Protocol = struct {
    const Self = @This();

    // Structure operations
    pub fn writeStructBegin(self: *Self, name: []const u8) ThriftError!void {
        _ = self;
        _ = name;
        // Implementation would go here
    }

    pub fn writeStructEnd(self: *Self) ThriftError!void {
        _ = self;
        // Implementation would go here
    }

    pub fn readStructBegin(self: *Self) ThriftError![]const u8 {
        _ = self;
        // Implementation would go here
        return "";
    }

    pub fn readStructEnd(self: *Self) ThriftError!void {
        _ = self;
        // Implementation would go here
    }

    // Field operations
    pub fn writeFieldBegin(self: *Self, field_id: i16, field_type: FieldType) ThriftError!void {
        _ = self;
        _ = field_id;
        _ = field_type;
        // Implementation would go here
    }

    pub fn writeFieldEnd(self: *Self) ThriftError!void {
        _ = self;
        // Implementation would go here
    }

    pub fn writeFieldStop(self: *Self) ThriftError!void {
        _ = self;
        // Implementation would go here
    }

    pub fn readFieldBegin(self: *Self) ThriftError!FieldInfo {
        _ = self;
        // Implementation would go here
        return FieldInfo{
            .name = "",
            .field_type = FieldType.BOOL,
            .field_id = 0,
        };
    }

    pub fn readFieldEnd(self: *Self) ThriftError!void {
        _ = self;
        // Implementation would go here
    }

    // List operations
    pub fn writeListBegin(self: *Self, element_type: FieldType, size: usize) ThriftError!void {
        _ = self;
        _ = element_type;
        _ = size;
        // Implementation would go here
    }

    pub fn writeListEnd(self: *Self) ThriftError!void {
        _ = self;
        // Implementation would go here
    }

    pub fn readListBegin(self: *Self) ThriftError!ListInfo {
        _ = self;
        // Implementation would go here
        return ListInfo{
            .element_type = FieldType.BOOL,
            .size = 0,
        };
    }

    pub fn readListEnd(self: *Self) ThriftError!void {
        _ = self;
        // Implementation would go here
    }

    // Write primitive types
    pub fn writeBool(self: *Self, value: bool) ThriftError!void {
        _ = self;
        _ = value;
        // Implementation would go here
    }

    pub fn writeI8(self: *Self, value: i8) ThriftError!void {
        _ = self;
        _ = value;
        // Implementation would go here
    }

    pub fn writeI16(self: *Self, value: i16) ThriftError!void {
        _ = self;
        _ = value;
        // Implementation would go here
    }

    pub fn writeI32(self: *Self, value: i32) ThriftError!void {
        _ = self;
        _ = value;
        // Implementation would go here
    }

    pub fn writeI64(self: *Self, value: i64) ThriftError!void {
        _ = self;
        _ = value;
        // Implementation would go here
    }

    pub fn writeDouble(self: *Self, value: f64) ThriftError!void {
        _ = self;
        _ = value;
        // Implementation would go here
    }

    pub fn writeString(self: *Self, value: []const u8) ThriftError!void {
        _ = self;
        _ = value;
        // Implementation would go here
    }

    pub fn writeBinary(self: *Self, value: []const u8) ThriftError!void {
        _ = self;
        _ = value;
        // Implementation would go here
    }

    // Read primitive types
    pub fn readBool(self: *Self) ThriftError!bool {
        _ = self;
        // Implementation would go here
        return false;
    }

    pub fn readI8(self: *Self) ThriftError!i8 {
        _ = self;
        // Implementation would go here
        return 0;
    }

    pub fn readI16(self: *Self) ThriftError!i16 {
        _ = self;
        // Implementation would go here
        return 0;
    }

    pub fn readI32(self: *Self) ThriftError!i32 {
        _ = self;
        // Implementation would go here
        return 0;
    }

    pub fn readI64(self: *Self) ThriftError!i64 {
        _ = self;
        // Implementation would go here
        return 0;
    }

    pub fn readDouble(self: *Self) ThriftError!f64 {
        _ = self;
        // Implementation would go here
        return 0.0;
    }

    pub fn readString(self: *Self, allocator: Allocator) ThriftError![]u8 {
        _ = self;
        // Implementation would go here
        return try allocator.alloc(u8, 0);
    }

    pub fn readBinary(self: *Self, allocator: Allocator) ThriftError![]u8 {
        _ = self;
        // Implementation would go here
        return try allocator.alloc(u8, 0);
    }

    // Skip operation for unknown fields
    pub fn skip(self: *Self, field_type: FieldType) ThriftError!void {
        _ = self;
        _ = field_type;
        // Implementation would go here
    }
};
