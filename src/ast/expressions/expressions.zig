const std = @import("std");

pub const BinaryExpression = @import("binary_expression.zig");
pub const UnaryExpression = @import("unary_expression.zig");
pub const GroupExpression = @import("group_expression.zig");
pub const IdentifierExpression = @import("identifier.zig");
pub const NumberLiteralExpression = @import("number_literal_expression.zig");
pub const BooleanLiteralExpression = @import("boolean_literal_expression.zig");
pub const StringLiteralExpression = @import("string_literal_expression.zig");

pub const ExpressionTag = enum {
    unary,
    binary,
    group,
    identifier,
    number,
    boolean,
    string,
};

pub const Expression = union(ExpressionTag) {
    unary: ?*UnaryExpression,
    binary: ?*BinaryExpression,
    group: ?*GroupExpression,
    identifier: ?*IdentifierExpression,
    number: ?*NumberLiteralExpression,
    boolean: ?*BooleanLiteralExpression,
    string: ?*StringLiteralExpression,

    pub fn format(self: Expression, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        switch (self) {
            inline else => |expression| {
                if (expression) |expr| {
                    try expr.format(fmt, options, writer);
                }
            },
        }
    }

    pub fn downcast(self: Expression, comptime T: type) ?*T {
        inline for (@typeInfo(Expression).Union.fields) |field| {
            if (field.type == ?*T) {
                return @field(self, field.name);
            }
        }
        return null;
    }
};
