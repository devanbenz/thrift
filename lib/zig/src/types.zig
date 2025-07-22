const std = @import("std");

var type_gpa = std.heap.GeneralPurposeAllocator(.{}){};
const type_allocator = type_gpa.allocator();

pub const TType = struct {
    _type_map: std.AutoHashMap(u8, []const u8),

    pub const STOP = 0;
    pub const VOID = 1;
    pub const BOOL = 2;
    pub const BYTE = 3;
    pub const I08 = 3;
    pub const DOUBLE = 4;
    pub const I16 = 6;
    pub const I32 = 8;
    pub const I64 = 10;
    pub const STRING = 11;
    pub const UTF7 = 11;
    pub const STRUCT = 12;
    pub const MAP = 13;
    pub const SET = 14;
    pub const LIST = 15;
    pub const UUID = 16;

    pub fn init(allocator: std.mem.Allocator) !TType {
        var type_names = std.AutoHashMap(u8, []const u8).init(allocator);

        try type_names.put(STOP, "STOP");
        try type_names.put(VOID, "VOID");
        try type_names.put(BOOL, "BOOL");
        try type_names.put(BYTE, "BYTE");
        try type_names.put(DOUBLE, "DOUBLE");
        try type_names.put(I16, "I16");
        try type_names.put(I32, "I32");
        try type_names.put(I64, "I64");
        try type_names.put(STRING, "STRING");
        try type_names.put(STRUCT, "STRUCT");
        try type_names.put(MAP, "MAP");
        try type_names.put(SET, "SET");
        try type_names.put(LIST, "LIST");
        try type_names.put(UUID, "UUID");

        return TType{ ._type_map = type_names };
    }

    pub fn string(self: @This(), ttype: u8) ![]const u8 {
        const str = self._type_map.get(ttype) orelse return error.TypeNotFound;
        return str;
    }
};
