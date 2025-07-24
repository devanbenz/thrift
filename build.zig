// build.zig for thrift package

const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("thrift", .{
        .root_source_file = b.path("lib/zig/src/root.zig"),
        .target = target,
    });

    // Add tests
    const tests = b.addTest(.{
        .root_source_file = b.path("lib/zig/src/types_test.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_tests.step);
}
