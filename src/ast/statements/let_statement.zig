const std = @import("std");
const Self = @This();
const Token = @import("../../token/token.zig");
const Expressions = @import("../expressions/expressions.zig");
const Expression = Expressions.Expression;
const Identifier = Expressions.Identifier;

token: Token = undefined,
identifier: Identifier = undefined,
expression: Expression = undefined,

pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;
    try std.fmt.format(writer, "{s} {} = {};", .{ self.token.lexeme, self.identifier, self.expression });
}
