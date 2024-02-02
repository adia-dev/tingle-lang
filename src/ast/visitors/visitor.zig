const _Expression = @import("../expressions/expression.zig");

ptr: *anyopaque,
visit_binary_expression: *const fn (ctx: *anyopaque, binary_expression: *_Expression.BinaryExpression) anyerror!void,
