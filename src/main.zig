const std = @import("std");
const ChromaLogger = @import("chroma-logger");
const REPL = @import("repl/repl.zig");
const ast = @import("ast/ast.zig");
const Expressions = ast.Expressions;
const Statements = ast.Statements;

pub const std_options: std.Options = .{ .log_level = .debug, .logFn = ChromaLogger.log };

// pub fn main() !void {
//     var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
//     defer arena.deinit();

//     var repl = REPL.init(arena.allocator());
//     defer repl.deinit();

//     try repl.start();
// }

const Lexer = @import("lexer/lexer.zig");
const Parser = @import("parser/parser.zig");
const chroma = @import("chroma");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const source_code = [_][]const u8{
        "\"Line 1\\nLine 2\\nLine 3;",
        "\"",
        "'",
        \\"How about
        \\multi line
        \\string
        \\ string
        \\ string
        \\ string
        \\ string
        \\ string
        \\ string
        ,
        \\"this one is fine but..."
        ,
        \\ ;
        \\ ;
        \\ ;
        \\ ;
        \\ ;
        \\ ;
        \\ ;
        \\ ;
        \\ ;
        \\ ;
        \\ ;
        \\"How about
        \\Very very very
        \\Very very very
        \\Very very very
        \\Very very very
        \\Very very very
        \\Very very very
        \\Very very very
        \\Very very very
        \\          very
        \\          very
        \\          very
        \\long multi line
        \\strings
        // ,
        // \\ "My github is adia-dev
        // ,
        // \\  hmmm       '111111111111' Hello
        // ,
        // \\ Multi line
        // \\ "Diagnostic
        // ,
        // "'abc",
        // "'abc'",
        // \\ 'a
        // \\  b
        // \\  c
        // \\  d
        // \\  e
    };

    for (source_code) |code| {
        var lexer = try Lexer.init(arena.allocator(), code);
        defer lexer.deinit();

        var parser = Parser.init(arena.allocator(), &lexer) catch {
            continue;
        };
        defer parser.deinit();

        var program = parser.parse() catch |err| {
            std.debug.print("{}\n", .{err});
            continue;
        };
        defer program.deinit();

        //         for (program.statements.items) |stmt| {
        //             std.debug.print(chroma.format("{241}{}\n"), .{stmt});
        //         }
    }
}
