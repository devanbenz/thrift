const std = @import("std");

pub const TransportReader = struct {
    ptr: ?*anyopaque,
    readAllFn: *const fn (ptr: *anyopaque, buffer: []u8) anyerror!void,
    readFn: *const fn (ptr: *anyopaque, buffer: []u8, len: usize) anyerror!void,
    seekFn: *const fn (ptr: *anyopaque, pos: usize) anyerror!void,

    fn readAll(self: TransportReader, buffer: []u8) !void {
        return self.readAllFn(self.ptr.?, buffer);
    }

    fn read(self: TransportReader, buffer: []u8, len: usize) !void {
        return self.readFn(self.ptr.?, buffer, len);
    }

    fn seek(self: TransportReader, pos: usize) !void {
        return self.seekFn(self.ptr.?, pos);
    }
};

pub const Transport = struct {
    _reader: TransportReader,
    _curr_byte: usize,
    const Self = @This();

    pub fn init(transport_reader: TransportReader) Transport {
        return .{ ._reader = transport_reader, ._curr_byte = 0 };
    }

    pub fn read_byte(self: Self, buffer: []u8) !TransportReader {
        if (self._reader.ptr == null) {
            return error.NoTransportReaderDefined;
        }

        return self._reader.read(buffer, 1);
    }

    pub fn readAll(self: Self, buffer: []u8) !void {
        if (self._reader.ptr == null) {
            return error.NoTransportReaderDefined;
        }

        return self._reader.readAll(buffer);
    }

    pub fn read(self: Self, buffer: []u8, len: usize) !void {
        if (self._reader.ptr == null) {
            return error.NoTransportReaderDefined;
        }

        return self._reader.read(buffer, len);
    }

    pub fn seek(self: Self, pos: usize) !void {
        if (self._reader.ptr == null) {
            return error.NoTransportReaderDefined;
        }

        return self._reader.seek(pos);
    }
};
