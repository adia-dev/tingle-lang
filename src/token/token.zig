const std = @import("std");
const Self = @This();
const _TokenType = @import("token_type.zig");
pub const TokenType = _TokenType.TokenType;
pub const Keyword = _TokenType.Keyword;

type: TokenType,
line: usize = 1,
row: usize = 1,
lexeme: []const u8 = "",

pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;
    try std.fmt.format(writer, "Token {{ type: {}, line: {d}, row: {d}, lexeme: \"{s}\" }}", .{ self.type, self.line, self.row, self.lexeme });
}
