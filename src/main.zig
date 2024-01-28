const std = @import("std");
const Lexer = @import("lexer/lexer.zig");
const Token = Lexer.Token;
const TokenType = Token.TokenType;

pub fn main() !void {
    std.debug.print("{}\n", .{Token{ .type = .{ .raw_byte_string = "name" }, .line = 10, .row = 34, .lexeme = "name" }});
    std.debug.print("{}\n", .{Token{ .type = .{ .keyword = .as }, .line = 10, .row = 34, .lexeme = "as" }});
    std.debug.print("{}\n", .{Token{ .type = .{ .character = 'c' }, .line = 10, .row = 34, .lexeme = "c" }});
    std.debug.print("{}\n", .{Token{ .type = .{ .byte = 9 }, .line = 10, .row = 34, .lexeme = "b9" }});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
