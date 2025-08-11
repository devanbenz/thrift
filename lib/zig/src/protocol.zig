const std = @import("std");

pub const ThriftError = error{ ProtocolError, OutOfMemory, InvalidData, UnexpectedEof };

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
    ptr: ?*anyopaque,
    writeStructBeginFn: *const fn (ptr: *anyopaque, name: []const u8) ThriftError!void,
    writeStructEndFn: *const fn (ptr: *anyopaque) ThriftError!void,
    readStructBeginFn: *const fn (ptr: *anyopaque) ThriftError![]const u8,
    readStructEndFn: *const fn (ptr: *anyopaque) ThriftError!void,
    writeFieldBeginFn: *const fn (ptr: *anyopaque, field_id: i16, field_type: FieldType) ThriftError!void,
    writeFieldEndFn: *const fn (ptr: *anyopaque) ThriftError!void,
    writeFieldStopFn: *const fn (ptr: *anyopaque) ThriftError!void,
    readFieldBeginFn: *const fn (ptr: *anyopaque) ThriftError!FieldInfo,
    readFieldEndFn: *const fn (ptr: *anyopaque) ThriftError!void,
    writeListBeginFn: *const fn (ptr: *anyopaque, element_type: FieldType, size: usize) ThriftError!void,
    writeListEndFn: *const fn (ptr: *anyopaque) ThriftError!void,
    readListBeginFn: *const fn (ptr: *anyopaque) ThriftError!ListInfo,
    readListEndFn: *const fn (ptr: *anyopaque) ThriftError!void,
    writeBoolFn: *const fn (ptr: *anyopaque, value: bool) ThriftError!void,
    writeI8Fn: *const fn (ptr: *anyopaque, value: i8) ThriftError!void,
    writeI16Fn: *const fn (ptr: *anyopaque, value: i16) ThriftError!void,
    writeI32Fn: *const fn (ptr: *anyopaque, value: i32) ThriftError!void,
    writeI64Fn: *const fn (ptr: *anyopaque, value: i64) ThriftError!void,
    writeDoubleFn: *const fn (ptr: *anyopaque, value: f64) ThriftError!void,
    writeStringFn: *const fn (ptr: *anyopaque, value: []const u8) ThriftError!void,
    writeBinaryFn: *const fn (ptr: *anyopaque, value: []const u8) ThriftError!void,
    readBoolFn: *const fn (ptr: *anyopaque) ThriftError!bool,
    readI8Fn: *const fn (ptr: *anyopaque) ThriftError!i8,
    readI16Fn: *const fn (ptr: *anyopaque) ThriftError!i16,
    readI32Fn: *const fn (ptr: *anyopaque) ThriftError!i32,
    readI64Fn: *const fn (ptr: *anyopaque) ThriftError!i64,
    readDoubleFn: *const fn (ptr: *anyopaque) ThriftError!f64,
    readStringFn: *const fn (ptr: *anyopaque, allocator: std.mem.Allocator) ThriftError![]u8,
    readBinaryFn: *const fn (ptr: *anyopaque, allocator: std.mem.Allocator) ThriftError![]u8,
    skipFn: *const fn (ptr: *anyopaque, field_type: FieldType) ThriftError!void,

    pub fn writeStructBegin(self: Protocol, name: []const u8) ThriftError!void {
        return self.writeStructBeginFn(self.ptr.?, name);
    }

    pub fn writeStructEnd(self: Protocol) ThriftError!void {
        return self.writeStructEndFn(self.ptr.?);
    }

    pub fn readStructBegin(self: Protocol) ThriftError![]const u8 {
        return self.readStructBeginFn(self.ptr.?);
    }

    pub fn readStructEnd(self: Protocol) ThriftError!void {
        return self.readStructEndFn(self.ptr.?);
    }

    pub fn writeFieldBegin(self: Protocol, field_id: i16, field_type: FieldType) ThriftError!void {
        return self.writeFieldBeginFn(self.ptr.?, field_id, field_type);
    }

    pub fn writeFieldEnd(self: Protocol) ThriftError!void {
        return self.writeFieldEndFn(self.ptr.?);
    }

    pub fn writeFieldStop(self: Protocol) ThriftError!void {
        return self.writeFieldStopFn(self.ptr.?);
    }

    pub fn readFieldBegin(self: Protocol) ThriftError!FieldInfo {
        return self.readFieldBeginFn(self.ptr.?);
    }

    pub fn readFieldEnd(self: Protocol) ThriftError!void {
        return self.readFieldEndFn(self.ptr.?);
    }

    pub fn writeListBegin(self: Protocol, element_type: FieldType, size: usize) ThriftError!void {
        return self.writeListBeginFn(self.ptr.?, element_type, size);
    }

    pub fn writeListEnd(self: Protocol) ThriftError!void {
        return self.writeListEndFn(self.ptr.?);
    }

    pub fn readListBegin(self: Protocol) ThriftError!ListInfo {
        return self.readListBeginFn(self.ptr.?);
    }

    pub fn readListEnd(self: Protocol) ThriftError!void {
        return self.readListEndFn(self.ptr.?);
    }

    pub fn writeBool(self: Protocol, value: bool) ThriftError!void {
        return self.writeBoolFn(self.ptr.?, value);
    }

    pub fn writeI8(self: Protocol, value: i8) ThriftError!void {
        return self.writeI8Fn(self.ptr.?, value);
    }

    pub fn writeI16(self: Protocol, value: i16) ThriftError!void {
        return self.writeI16Fn(self.ptr.?, value);
    }

    pub fn writeI32(self: Protocol, value: i32) ThriftError!void {
        return self.writeI32Fn(self.ptr.?, value);
    }

    pub fn writeI64(self: Protocol, value: i64) ThriftError!void {
        return self.writeI64Fn(self.ptr.?, value);
    }

    pub fn writeDouble(self: Protocol, value: f64) ThriftError!void {
        return self.writeDoubleFn(self.ptr.?, value);
    }

    pub fn writeString(self: Protocol, value: []const u8) ThriftError!void {
        return self.writeStringFn(self.ptr.?, value);
    }

    pub fn writeBinary(self: Protocol, value: []const u8) ThriftError!void {
        return self.writeBinaryFn(self.ptr.?, value);
    }

    pub fn readBool(self: Protocol) ThriftError!bool {
        return self.readBoolFn(self.ptr.?);
    }

    pub fn readI8(self: Protocol) ThriftError!i8 {
        return self.readI8Fn(self.ptr.?);
    }

    pub fn readI16(self: Protocol) ThriftError!i16 {
        return self.readI16Fn(self.ptr.?);
    }

    pub fn readI32(self: Protocol) ThriftError!i32 {
        return self.readI32Fn(self.ptr.?);
    }

    pub fn readI64(self: Protocol) ThriftError!i64 {
        return self.readI64Fn(self.ptr.?);
    }

    pub fn readDouble(self: Protocol) ThriftError!f64 {
        return self.readDoubleFn(self.ptr.?);
    }

    pub fn readString(self: Protocol, allocator: std.mem.Allocator) ThriftError![]u8 {
        return self.readStringFn(self.ptr.?, allocator);
    }

    pub fn readBinary(self: Protocol, allocator: std.mem.Allocator) ThriftError![]u8 {
        return self.readBinaryFn(self.ptr.?, allocator);
    }

    pub fn skip(self: Protocol, field_type: FieldType) ThriftError!void {
        return self.skipFn(self.ptr.?, field_type);
    }
};
