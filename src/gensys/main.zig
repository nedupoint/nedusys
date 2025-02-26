const std = @import("std");
const utils = @import("utils");
const luajit = @import("luajit");
const Lua = luajit.Lua;

pub fn main() !void {
    // create allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // define stdout
    const stdout = std.io.getStdOut().writer();

    // check if root
    if (std.os.linux.geteuid() != 0) {
        try stdout.print("ERROR: this program needs to be ran as root\n", .{});
        std.process.exit(1);
    }

    // create lua
    const lua = try Lua.init(allocator);
    defer lua.deinit();

    lua.openBaseLib();
    // check for config file
    if (try utils.file.fileExists("/etc/nedusys/sys.lua")) {
        try stdout.print("Loading system config\n", .{});
        const data = try utils.file.readFileCStyleReturn("/etc/nedusys/sys.lua", allocator);
        defer allocator.free(data);
        try lua.doString(data);
        try stdout.print("Finished loading system config\n", .{});
        try stdout.print("Parsing config\n", .{});
        try handlePackages(lua, allocator);
    } else {
        try stdout.print("ERROR: required file: /etc/nedusys/sys.lua does not exist please create it\n", .{});
    }
}

fn handlePackages(lua: *luajit.Lua, allocator: std.mem.Allocator) !void {
    const stdout = std.io.getStdOut().writer();
    var packages = std.ArrayList(u8).init(allocator);
    defer packages.deinit();

    try packages.appendSlice("pacman -S --needed --noconfirm");

    _ = lua.getGlobal("packages");

    if (lua.isTable(-1) == true) {
        lua.pushNil();

        while (lua.next(-2) != false) {
            if (lua.isString(-1)) {
                // sometimes i hate zig
                const sliced: [:0]const u8 = std.mem.sliceTo(try lua.toString(-1), 0);
                const slicedNoNull: []const u8 = sliced[0..sliced.len];
                try packages.appendSlice(" ");
                try packages.appendSlice(@constCast(slicedNoNull));
            }
            lua.pop(1);
        }
    }
    lua.pop(1);
    try stdout.print("running: {s}\n", .{packages.items});
    try utils.execute.execute(packages.items, allocator);
}
