const std = @import("std");
const Self = @This();

value: i32 = 0,

pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;
    try std.fmt.format(writer, "{d}", .{self.value});
}
