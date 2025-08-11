const std = @import("std");
const ttransport = @import("transport.zig");
const test_utils = @import("test_utils.zig");

test "TransportReader test read" {
    const test_buf = [_]u8{ 10, 10, 10, 10 };
    var reader = test_utils.TestReader.init(test_buf[0..]);
    const transport = try ttransport.Transport.init(reader.transport_reader());

    var buf = [_]u8{ 0, 0, 0, 0 };
    try transport.read(&buf, 4);

    for (buf, 0..) |v, i| {
        try std.testing.expect(v == test_buf[i]);
    }
}

test "Transport test read_bytes" {
    const test_buf: []const u8 = "Tadashi";
    var reader = test_utils.TestReader.init(test_buf);
    const transport = try ttransport.Transport.init(reader.transport_reader());

    var buf = [1]u8{0};
    try transport.read_byte(&buf);

    try std.testing.expect(std.mem.eql(u8, buf[0..], "T"));
}
