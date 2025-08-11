const std = @import("std");
const testing = std.testing;
const types = @import("types.zig");

test "TType constants have correct values" {
    try testing.expect(types.TType.STOP == 0);
    try testing.expect(types.TType.VOID == 1);
    try testing.expect(types.TType.BOOL == 2);
    try testing.expect(types.TType.BYTE == 3);
    try testing.expect(types.TType.I08 == 3);
    try testing.expect(types.TType.DOUBLE == 4);
    try testing.expect(types.TType.I16 == 6);
    try testing.expect(types.TType.I32 == 8);
    try testing.expect(types.TType.I64 == 10);
    try testing.expect(types.TType.STRING == 11);
    try testing.expect(types.TType.UTF7 == 11);
    try testing.expect(types.TType.STRUCT == 12);
    try testing.expect(types.TType.MAP == 13);
    try testing.expect(types.TType.SET == 14);
    try testing.expect(types.TType.LIST == 15);
    try testing.expect(types.TType.UUID == 16);
}

test "TType.init creates proper type mapping" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var ttype = try types.TType.init(allocator);
    defer ttype._type_map.deinit();

    // Test that all mappings exist and are correct
    try testing.expectEqualStrings("STOP", try ttype.string(types.TType.STOP));
    try testing.expectEqualStrings("VOID", try ttype.string(types.TType.VOID));
    try testing.expectEqualStrings("BOOL", try ttype.string(types.TType.BOOL));
    try testing.expectEqualStrings("BYTE", try ttype.string(types.TType.BYTE));
    try testing.expectEqualStrings("DOUBLE", try ttype.string(types.TType.DOUBLE));
    try testing.expectEqualStrings("I16", try ttype.string(types.TType.I16));
    try testing.expectEqualStrings("I32", try ttype.string(types.TType.I32));
    try testing.expectEqualStrings("I64", try ttype.string(types.TType.I64));
    try testing.expectEqualStrings("STRING", try ttype.string(types.TType.STRING));
    try testing.expectEqualStrings("STRUCT", try ttype.string(types.TType.STRUCT));
    try testing.expectEqualStrings("MAP", try ttype.string(types.TType.MAP));
    try testing.expectEqualStrings("SET", try ttype.string(types.TType.SET));
    try testing.expectEqualStrings("LIST", try ttype.string(types.TType.LIST));
    try testing.expectEqualStrings("UUID", try ttype.string(types.TType.UUID));
}

test "TType.string returns correct string representation" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var ttype = try types.TType.init(allocator);
    defer ttype._type_map.deinit();

    // Test individual type string lookups
    const stop_str = try ttype.string(0);
    try testing.expectEqualStrings("STOP", stop_str);

    const void_str = try ttype.string(1);
    try testing.expectEqualStrings("VOID", void_str);

    const bool_str = try ttype.string(2);
    try testing.expectEqualStrings("BOOL", bool_str);

    const string_str = try ttype.string(11);
    try testing.expectEqualStrings("STRING", string_str);

    const uuid_str = try ttype.string(16);
    try testing.expectEqualStrings("UUID", uuid_str);
}

test "TType handles duplicate constants correctly" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var ttype = try types.TType.init(allocator);
    defer ttype._type_map.deinit();

    // BYTE and I08 both have value 3, but BYTE should be the string returned
    const byte_str = try ttype.string(3);
    try testing.expectEqualStrings("BYTE", byte_str);

    // STRING and UTF7 both have value 11, but STRING should be the string returned
    const string_str = try ttype.string(11);
    try testing.expectEqualStrings("STRING", string_str);
}
