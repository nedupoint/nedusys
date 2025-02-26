const std = @import("std");
const errorhandler = @import("error.zig");

// basic util for verifying that files exist
pub fn fileExists(path: []const u8) !bool {
    // https://nofmal.github.io/zig-with-example/file/ kinda stolen from here lol
    const file = std.fs.cwd().openFile(path, .{}) catch |err| switch (err) {
        error.FileNotFound => return false,
        else => return err,
    };
    defer file.close();
    return true;
}

// basic util for reading files
pub fn readFile(filepath: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

    const out = try file.readToEndAlloc(allocator, 1000000);
    return out;
}

// i have to use this to make lua happy
pub fn readFileCStyleReturn(filepath: []const u8, allocator: std.mem.Allocator) ![:0]const u8 {
    const file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

    const file_metadata = try file.metadata();
    const file_size = file_metadata.size();

    var buffer = try allocator.alloc(u8, file_size + 1);
    _ = try file.readAll(buffer[0..file_size]);

    buffer[file_size] = 0;

    return buffer[0..file_size :0];
}

// basic util for writing files
pub fn writeFile(filepath: []const u8, data: []const u8) !void {
    var file = std.fs.cwd().createFile(filepath, .{}) catch |err| {
        try errorhandler.handleError(err);
        std.process.exit(1);
    };
    defer file.close();

    try file.writeAll(data);
}

// basic util for making dirs
pub fn createDir(dirPath: []const u8) !void {
    std.fs.cwd().makeDir(dirPath) catch |err| {
        try errorhandler.handleError(err);
        std.process.exit(1);
    };
}
