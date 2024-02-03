const std = @import("std");

pub const BinaryExpression = @import("binary_expression.zig");
pub const UnaryExpression = @import("unary_expression.zig");
pub const GroupExpression = @import("group_expression.zig");
pub const LiteralExpression = @import("literal_expression.zig").LiteralExpression;

pub const Identifier = @import("identifier.zig");

pub const Expression = union(enum) {
    unary: ?*UnaryExpression,
    binary: ?*BinaryExpression,
    group: ?*GroupExpression,
    literal: ?*LiteralExpression,
    identifier: ?*Identifier,

    pub fn format(self: Expression, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        switch (self) {
            inline else => |expression| {
                if (expression) |expr| {
                    try expr.format(fmt, options, writer);
                }
            },
        }
    }
};
