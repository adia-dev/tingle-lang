const std = @import("std");
const Logger = @import("core/logger.zig");
const REPL = @import("repl/repl.zig");
const ast = @import("ast/ast.zig");
const Expressions = ast.Expressions;
const Statements = ast.Statements;

pub const std_options = struct {
    pub const log_level = .debug;
    pub const logFn = Logger.log;
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var repl = REPL.init(arena.allocator());
    defer repl.deinit();

    try repl.start();
}
