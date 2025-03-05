const std = @import("std");
const luajit = @import("luajit");
const Lua = luajit.Lua;

pub fn tableToArrayList(tableName: [:0]const u8, lua: *Lua, allocator: std.mem.Allocator) !std.ArrayList(u8) {
    var out = std.ArrayList(u8).init(allocator);

    _ = lua.getGlobal(tableName);

    if (lua.isTable(-1) == true) {
        lua.pushNil();

        while (lua.next(-2) != false) {
            if (lua.isString(-1)) {
                // sometimes i hate zig
                const sliced: [:0]const u8 = std.mem.sliceTo(try lua.tostring(-1), 0);
                const slicednonull: []const u8 = sliced[0..sliced.len];
                try out.appendslice(" ");
                try out.appendslice(@constCast(slicednonull));
            }
            lua.pop(1);
        }
    }
    lua.pop(1);
    return out;
}

pub fn tableToArrayListAppend(tableName: [:0]const u8, lua: *Lua, arrayList: *std.ArrayList(u8)) !void {
    _ = lua.getGlobal(tableName);

    if (lua.isTable(-1) == true) {
        lua.pushNil();

        while (lua.next(-2) != false) {
            if (lua.isString(-1)) {
                // sometimes i hate zig
                const sliced: [:0]const u8 = std.mem.sliceTo(try lua.toString(-1), 0);
                const slicedNoNull: []const u8 = sliced[0..sliced.len];
                try arrayList.appendSlice(" ");
                try arrayList.appendSlice(@constCast(slicedNoNull));
            }
            lua.pop(1);
        }
    }
    lua.pop(1);
}

pub fn tableToArrayListAppendFunc(index: i32, lua: *Lua, arrayList: *std.ArrayList(u8)) !void {
    lua.pushNil();

    while (lua.next(index) != false) {
        if (lua.isString(-1)) {
            // sometimes i hate zig
            const sliced: [:0]const u8 = std.mem.sliceTo(try lua.toString(-1), 0);
            const slicedNoNull: []const u8 = sliced[0..sliced.len];
            try arrayList.appendSlice(" ");
            try arrayList.appendSlice(@constCast(slicedNoNull));
        }
        lua.pop(index);
    }
}
