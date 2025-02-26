const std = @import("std");

pub fn handleError(err: anyerror) !void {
    const stdout = std.io.getStdOut().writer();
    switch (err) {
        error.AccessDenied => {
            try stdout.print("error.AccessDenied are you running this as root?\n", .{});
        },
        else => {
            try stdout.print("{} error does not have a case please make a github issue\n", .{err});
        },
    }
}
