const std = @import("std");
const test_utils = @import("test_utils.zig");
const transport = @import("transport.zig");
const compact_proto = @import("compact_protocol.zig");

test "CompactProtocol test basic usage" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var test_reader = test_utils.TestReader.init("Tadashi");
    const test_transport = try transport.Transport.init(test_reader.transport_reader());

    var compact = try compact_proto.CompactProtocol.init(allocator, test_transport);
    const b = try compact.read_byte_direct();
    try std.testing.expect(b == 'T');
}

const compact_protocol_test_data = [_]u8{
    // Byte 1: Protocol ID (0x82 = 1000 0010)
    0x82,

    // Byte 2: Message type (001) + Version (00001) = 0010 0001 = 0x21
    // mmm = 001 (Call), vvvvv = 00001 (version 1)
    0x21,

    // Sequence ID: 42 encoded as varint
    // 42 in binary: 101010
    // Since it fits in 7 bits, it's just: 0010 1010 = 0x2A
    0x2A,

    // Method name length: 10 encoded as varint
    // 10 in binary: 1010
    // Since it fits in 7 bits: 0000 1010 = 0x0A
    0x0A,

    // Method name: "testMethod" (UTF-8 encoded)
    't',
    'e',
    's',
    't',
    'M',
    'e',
    't',
    'h',
    'o',
    'd',
};

test "CompactProtocol test message okay" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var test_reader = test_utils.TestReader.init(&compact_protocol_test_data);
    const test_transport = try transport.Transport.init(test_reader.transport_reader());

    var compact = try compact_proto.CompactProtocol.init(allocator, test_transport);
    const msg = try compact.read_message_begin();
    try std.testing.expect(@intFromEnum(msg.type) == 1);
    try std.testing.expect(msg.seq == 42);
}

const compact_protocol_test_bad_header = [_]u8{
    0x81,
    0x21,
    0x2A,
    0x0A,
    't',
    'e',
    's',
    't',
    'M',
    'e',
    't',
    'h',
    'o',
    'd',
};

test "CompactProtocol test bad header in message" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var test_reader = test_utils.TestReader.init(&compact_protocol_test_bad_header);
    const test_transport = try transport.Transport.init(test_reader.transport_reader());

    var compact = try compact_proto.CompactProtocol.init(allocator, test_transport);
    try std.testing.expectError(compact_proto.CompactProtocolError.IncorrectMessageHeader, compact.read_message_begin());
}

const compact_protocol_test_bad_version = [_]u8{
    0x82,
    0x23,
    0x2A,
    0x0A,
    't',
    'e',
    's',
    't',
    'M',
    'e',
    't',
    'h',
    'o',
    'd',
};

test "CompactProtocol test bad version in message" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var test_reader = test_utils.TestReader.init(&compact_protocol_test_bad_header);
    const test_transport = try transport.Transport.init(test_reader.transport_reader());

    var compact = try compact_proto.CompactProtocol.init(allocator, test_transport);
    try std.testing.expectError(compact_proto.CompactProtocolError.IncorrectMessageVersion, compact.read_message_begin());
}

pub const compact_protocol_large_seqid = [_]u8{
    // Protocol ID
    0x82,

    // Message type: Reply (2) + Version (1) = 0100 0001 = 0x41
    0x41,

    // Sequence ID: 16384 (requires 3 bytes in varint)
    // 16384 = 0100 0000 0000 0000 in binary
    0x80,
    0x80,
    0x01,

    // Method name length: 4
    0x04,

    // Method name: "ping"
    'p',
    'i',
    'n',
    'g',
};

test "CompactProtocol test message okay with large sequence" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var test_reader = test_utils.TestReader.init(&compact_protocol_large_seqid);
    const test_transport = try transport.Transport.init(test_reader.transport_reader());

    var compact = try compact_proto.CompactProtocol.init(allocator, test_transport);
    const msg = try compact.read_message_begin();
    try std.testing.expect(@intFromEnum(msg.type) == 2);
    try std.testing.expect(msg.seq == 16384);
    try std.testing.expect(msg.name_len == 4);
    try std.testing.expectEqualStrings(msg.name, "ping");
}
