const std = @import("std");
const Lexer = @import("lexer/lexer.zig");
const Token = Lexer.Token;
const TokenType = Token.TokenType;

const source_code = @embedFile("./examples/main.tl");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    var lexer = Lexer.init(arena.allocator(), source_code) catch |err| {
        std.debug.print("Failed to initialize the lexer: {}", .{err});
        return;
    };

    var token = try lexer.scan();

    while (true) {
        if (token.type == .eof or token.type == .illegal) {
            break;
        }
        std.debug.print("{}\n", .{token});
        token = try lexer.scan();
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
