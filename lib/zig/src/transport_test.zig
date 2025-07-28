const std = @import("std");
const ttransport = @import("transport.zig");
const test_utils = @import("test_utils.zig");

test "TransportReader test" {
    const test_buf = [_]u8{ 10, 10, 10, 10 };
    var reader = test_utils.TestReader.init(test_buf[0..]);
    const transport = try ttransport.Transport.init(reader.transport_reader());

    var buf = [_]u8{ 0, 0, 0, 0 };
    try transport.readAll(&buf);

    for (buf, 0..) |v, i| {
        try std.testing.expect(v == test_buf[i]);
    }
}
