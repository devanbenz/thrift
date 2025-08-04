const std = @import("std");
const ttransport = @import("transport.zig");

pub const TestReader = struct {
    _internal_buf: []const u8,
    _curr_byte_pos: usize,

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

    fn open(ptr: *anyopaque) !void {
        _ = ptr;
        return;
    }

    fn close(ptr: *anyopaque) !void {
        _ = ptr;
        return;
    }

    pub fn init(data: []const u8) TestReader {
        return .{ ._internal_buf = data, ._curr_byte_pos = 0 };
    }

    pub fn transport_reader(self: *TestReader) ttransport.TransportReader {
        return ttransport.TransportReader{ .ptr = self, .readFn = @ptrCast(&TestReader.read), .openFn = @ptrCast(&TestReader.open), .closeFn = @ptrCast(&TestReader.close) };
    }
};
