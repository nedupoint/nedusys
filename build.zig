const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const luajit_dep = b.dependency("luajit", .{
        .target = target,
        .optimize = optimize,
    });

    const luajit = luajit_dep.module("luajit");

    const utils_mod = b.addModule("utils", .{ .root_source_file = b.path("src/utils/utils.zig"), .target = target, .optimize = optimize });

    const gensys = b.addExecutable(.{
        .name = "nedusys-gen",
        .root_source_file = b.path("src/gensys/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    gensys.root_module.addImport("luajit", luajit);
    gensys.root_module.addImport("utils", utils_mod);
    b.installArtifact(gensys);
}
