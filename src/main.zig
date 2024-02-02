const std = @import("std");
const Logger = @import("core/logger.zig");
const REPL = @import("repl/repl.zig");
const ast = @import("ast/ast.zig");
const Expressions = ast.Expressions;

pub const std_options = struct {
    pub const log_level = .debug;
    pub const logFn = Logger.log;
};

pub fn main() !void {
    var left: Expressions.LiteralExpression = .{ .string = .{ .value = "Abdoulaye" } };
    var right: Expressions.LiteralExpression = .{ .string = .{ .value = "Dia" } };
    var concat: Expressions.BinaryExpression = .{ .left = .{ .literal = &left }, .operator = .{ .type = .plusplus, .lexeme = "++" }, .right = .{ .literal = &right } };
    var minus_concat: Expressions.UnaryExpression = .{ .operator = .{ .type = .minus, .lexeme = "-" }, .expression = .{ .binary = &concat } };
    var group: Expressions.GroupExpression = .{ .expression = .{ .unary = &minus_concat } };

    const expression: Expressions.Expression = .{ .group = &group };

    std.debug.print("\n{}\n", .{expression});
}

// pub fn main() !void {
//     var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
//     defer arena.deinit();

//     var repl = REPL.init(arena.allocator());
//     defer repl.deinit();

//     try repl.start();
// }
