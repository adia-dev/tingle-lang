const std = @import("std");
const Self = @This();
const _TokenType = @import("token_type.zig");
pub const TokenType = _TokenType.TokenType;
pub const Keyword = _TokenType.Keyword;

type: TokenType,
line: usize,
row: usize,
lexeme: []const u8 = "",
literal: ?[]const u8 = null,

pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;
    try std.fmt.format(writer, "Token {{ type: {}, line: {d}, row: {d}, lexeme: \"{s}\", literal: {?s} }}", .{ self.type, self.line, self.row, self.lexeme, self.literal });
}
