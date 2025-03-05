const std = @import("std");
const utils = @import("utils");
const luajit = @import("luajit");
const c = @import("c");
const Lua = luajit.Lua;

pub fn main() !void {
    // create allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // define stdin
    const stdin = std.io.getStdIn().reader();

    // define stdout
    const stdout = std.io.getStdOut().writer();

    // check if root
    if (std.os.linux.geteuid() != 0) {
        try stdout.print("ERROR: this program needs to be ran as root\n", .{});
        std.process.exit(1);
    }

    // confirm that the user really wants to reinstall
    try stdout.print("!!This command is very dangerous it is arch-install but for nedusys systems!! Confirm [y/n]: ", .{});

    var confirmation: [5]u8 = undefined;
    _ = try stdin.readUntilDelimiter(&confirmation, '\n');

    const trimmed_confirmation = std.mem.trim(u8, &confirmation, "\n\r");

    if (std.mem.count(u8, "n", trimmed_confirmation) > 0) {
        try stdout.print("User declined the command exiting\n", .{});
        std.process.exit(0);
    }

    // create lua
    const lua = try Lua.init(allocator);
    defer lua.deinit();

    lua.openBaseLib();
    lua.registerLibrary(
        "nedu",
        &[_]Lua.Reg{
            .{ .name = "bash", .func = &luaBash },
            .{ .name = "packages", .func = &luaPackages },
            Lua.RegEnd,
        },
    );

    // check for config file
    if (try utils.file.fileExists("/etc/nedusys/sys.lua")) {
        try stdout.print("Loading system config\n", .{});
        const data = try utils.file.readFileCStyleReturn("/etc/nedusys/sys.lua", allocator);
        defer allocator.free(data);
        try stdout.print("Finished loading system config\n", .{});
        try stdout.print("Parsing config\n", .{});

        lua.doString(data) catch |err| {
            switch (err) {
                error.InvalidSyntax => {
                    try stdout.print("ERROR: invalid syntax in /etc/nedusys/sys.lua to get more details try lua /etc/nedusys/sys.lua\n", .{});
                },
                else => {
                    try stdout.print("ERROR: unknown lua error: {}\n", .{err});
                },
            }
            std.process.exit(1);
        };
    } else {
        try stdout.print("ERROR: required file: /etc/nedusys/sys.lua does not exist please create it\n", .{});
    }
}

fn luaBash(lua: *luajit.Lua) callconv(.c) i32 {
    const input = lua.checkString(1);

    std.debug.print("executing: {s}\n", .{input});
    const sliced: [:0]const u8 = std.mem.sliceTo(input, 0);
    const slicednonull: []const u8 = sliced[0..sliced.len];

    utils.execute.execute(@constCast(slicednonull), std.heap.page_allocator) catch |err| {
        std.debug.print("ERROR: {}\n", .{err});

        lua.pushNumber(0);

        std.process.exit(1);
    };

    lua.pushNumber(1);

    return 1;
}

fn luaPackages(lua: *luajit.Lua) callconv(.c) i32 {
    if (!lua.isTable(1)) {
        std.debug.print("ERROR: packages function takes a table as the first and only param\n", .{});

        std.process.exit(1);
    }
    handlePackages(lua, std.heap.page_allocator) catch |err| {
        std.debug.print("ERROR: {}\n", .{err});

        std.process.exit(1);
    };
    return 0;
}

fn handlePackages(lua: *luajit.Lua, allocator: std.mem.Allocator) !void {
    const stdout = std.io.getStdOut().writer();
    var packages = std.ArrayList(u8).init(allocator);
    defer packages.deinit();

    //try packages.appendSlice("pacstrap -K /mnt/");

    try packages.appendSlice("pacman -S --needed --noconfirm");

    try utils.luaUtils.tableToArrayListAppendFunc(1, lua, &packages);
    if (packages.items.len == 0) {
        try stdout.print("WARNING: skipping install step due to requested packages being 0\n", .{});
        return;
    }

    try stdout.print("running: {s}\n", .{packages.items});
    try utils.execute.execute(packages.items, allocator);
}
