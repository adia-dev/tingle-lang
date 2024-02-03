const std = @import("std");
const Self = @This();
const Token = @import("../../token/token.zig");

token: Token = undefined,
value: []const u8 = undefined,

pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;
    try std.fmt.format(writer, "{s}", .{self.token.lexeme});
}
