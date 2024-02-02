const _Expression = @import("../expressions/expression.zig");
const AstVisitor = @import("visitor.zig");
const Self = @This();

fn visit_binary_expression(binary_expression: *_Expression.BinaryExpression) !void {
    _ = binary_expression;
}

pub fn visitor(self: *Self) AstVisitor {
    return .{ .ptr = self, .visit_binary_expression = visit_binary_expression };
}
