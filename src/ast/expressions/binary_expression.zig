const std = @import("std");

const Expression = @import("expressions.zig").Expression;
const Token = @import("../../token/token.zig");
const Self = @This();

left: Expression = undefined,
operator: Token = undefined,
right: Expression = undefined,

pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;
    try std.fmt.format(writer, "({s} {} {})", .{ self.operator.lexeme, self.left, self.right });
}
