const std = @import("std");

const Expression = @import("expressions.zig").Expression;
const Token = @import("../../token/token.zig");
const Self = @This();

operator: Token,
expression: Expression,

pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;
    try std.fmt.format(writer, "({s} {})", .{ self.operator.lexeme, self.expression });
}
