const std = @import("std");
const Self = @This();

value: []const u8,

pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;
    try std.fmt.format(writer, "{s}", .{self.value});
}
