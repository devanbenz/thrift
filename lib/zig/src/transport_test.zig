const std = @import("std");
const ttransport = @import("transport.zig");

const TestReader = struct {
    _internal_buf: []const u8,
    _curr_byte_pos: usize,

    fn init(data: []const u8) TestReader {
        return .{ ._internal_buf = data, ._curr_byte_pos = 0 };
    }

    fn readAll(ptr: *anyopaque, buffer: []u8) !void {
        const self: *TestReader = @ptrCast(@alignCast(ptr));
        if (self._internal_buf.len == 0) {
            return error.EmptyTestBuffer;
        }

        const remaining = self._internal_buf[self._curr_byte_pos..];
        const copy_len = @min(buffer.len, remaining.len);
        @memcpy(buffer[0..copy_len], remaining[0..copy_len]);
    }

    fn read(ptr: *anyopaque, buffer: []u8, len: usize) !void {
        const self: *TestReader = @ptrCast(@alignCast(ptr));
        if (self._internal_buf.len == 0) {
            return error.EmptyTestBuffer;
        }

        const remaining = self._internal_buf[self._curr_byte_pos..];
        const copy_len = @min(@min(buffer.len, len), remaining.len);
        @memcpy(buffer[0..copy_len], remaining[0..copy_len]);
        self._curr_byte_pos += copy_len;
    }

    fn seek(ptr: *anyopaque, pos: usize) !void {
        const self: *TestReader = @ptrCast(@alignCast(ptr));
        self._curr_byte_pos += pos;
    }

    fn transport_reader(self: *TestReader) ttransport.TransportReader {
        return ttransport.TransportReader{
            .ptr = self,
            .readAllFn = TestReader.readAll,
            .readFn = TestReader.read,
            .seekFn = @ptrCast(&TestReader.seek),
        };
    }
};

test "TransportReader test" {
    const test_buf = [_]u8{ 10, 10, 10, 10 };
    var reader = TestReader.init(test_buf[0..]);
    const transport = ttransport.Transport.init(reader.transport_reader());

    var buf = [_]u8{ 0, 0, 0, 0 };
    try transport.readAll(&buf);

    for (buf, 0..) |v, i| {
        try std.testing.expect(v == test_buf[i]);
    }
}
