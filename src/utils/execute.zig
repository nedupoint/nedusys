const std = @import("std");
const ChildProcess = std.process.Child;

pub fn execute(input: []u8, allocator: std.mem.Allocator) !void {
    var args = std.ArrayList([]const u8).init(allocator);
    defer args.deinit();

    var splitInput = std.mem.splitAny(u8, input, " ");

    while (splitInput.next()) |split| {
        try args.append(split);
    }

    var cmd = ChildProcess.init(args.items, allocator);
    cmd.stdout_behavior = .Inherit;
    cmd.stderr_behavior = .Inherit;

    try cmd.spawn();
    _ = cmd.wait() catch |err| {
        switch (err) {
            error.FileNotFound => {
                return error.CommandNotFound;
            },
            else => {
                return err;
            },
        }
    };
}
