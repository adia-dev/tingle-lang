const std = @import("std");
const Self = @This();

value: bool,

pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;
    try std.fmt.format(writer, "{s}", .{if (self.value) "true" else "false"});
}
