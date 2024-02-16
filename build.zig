const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const chroma_dep = b.dependency("chroma", .{ .target = target, .optimize = optimize });
    const chroma_logger_dep = b.dependency("chroma-logger", .{ .target = target, .optimize = optimize });

    const exe = b.addExecutable(.{
        .name = "tingle-lang",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.linkSystemLibrary("readline");
    exe.root_module.addImport("chroma", chroma_dep.module("chroma"));
    exe.root_module.addImport("chroma-logger", chroma_logger_dep.module("chroma-logger"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/tests.zig" },
        .test_runner = "src/test_runner.zig",
        .target = target,
        .optimize = optimize,
    });

    if (target.result.os.tag != .windows) {
        exe_unit_tests.linkSystemLibrary("readline");
    }
    exe_unit_tests.root_module.addImport("chroma", chroma_dep.module("chroma"));
    exe_unit_tests.root_module.addImport("chroma-logger", chroma_logger_dep.module("chroma-logger"));

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
