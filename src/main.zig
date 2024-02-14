const std = @import("std");
const ChromaLogger = @import("chroma-logger");
const REPL = @import("repl/repl.zig");
const ast = @import("ast/ast.zig");
const Expressions = ast.Expressions;
const Statements = ast.Statements;

pub const std_options: std.Options = .{ .log_level = .debug, .logFn = ChromaLogger.log };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var repl = REPL.init(arena.allocator());
    defer repl.deinit();

    try repl.start();
}
