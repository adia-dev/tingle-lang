const std = @import("std");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const AutoHashMap = std.AutoHashMap;

const Lexer = @import("../lexer/lexer.zig");
const LexerError = Lexer.LexerError;
const Token = @import("../token/token.zig");
const TokenType = Token.TokenType;
const Keyword = Token.Keyword;

pub const Expressions = @import("expressions/expressions.zig");
pub const Statements = @import("statements/statements.zig");
const Expression = Expressions.Expression;
const Statement = Statements.Statement;

pub const Node = union(enum) {
    expression: Expression,
    statement: Statement,

    pub fn format(self: Node, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        switch (self) {
            inline else => |node| {
                try node.format(fmt, options, writer);
            },
        }
    }
};
