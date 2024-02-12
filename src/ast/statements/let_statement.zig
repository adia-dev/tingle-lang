const std = @import("std");
const Self = @This();
const Token = @import("../../token/token.zig");
const Expressions = @import("../expressions/expressions.zig");
const Expression = Expressions.Expression;
const IdentifierExpression = Expressions.IdentifierExpression;

token: Token = undefined,
identifier: IdentifierExpression = undefined,
expression: ?Expression = undefined,

pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;
    if (self.expression) |expression| {
        try std.fmt.format(writer, "{s} {} = {};", .{ self.token.lexeme, self.identifier, expression });
    } else {
        try std.fmt.format(writer, "{s} {};", .{ self.token.lexeme, self.identifier });
    }
}
