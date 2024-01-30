const std = @import("std");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const AutoHashMap = std.AutoHashMap;
const testing = std.testing;

const Lexer = @import("lexer.zig");
const Token = @import("../token/token.zig");
const TokenType = Token.TokenType;
const Keyword = Token.Keyword;

test "Lexer - Recognize keyword tokens" {
    const ta = testing.allocator;
    const source_code: []const u8 =
        \\ async await break
        \\ const continue else
        \\ enum fn for
        \\ if pub return
        \\ struct try union
        \\ while as do
        \\ false in let
        \\ loop match priv
        \\ self static super
        \\ trait true type
        \\ typeof use where
        \\ yield
    ;

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    var expected_tokens = ArrayList(struct { key: []const u8, value: Keyword }).init(ta);
    defer expected_tokens.deinit();

    try expected_tokens.append(.{ .key = "async", .value = .@"async" });
    try expected_tokens.append(.{ .key = "await", .value = .@"await" });
    try expected_tokens.append(.{ .key = "break", .value = .@"break" });
    try expected_tokens.append(.{ .key = "const", .value = .@"const" });
    try expected_tokens.append(.{ .key = "continue", .value = .@"continue" });
    try expected_tokens.append(.{ .key = "else", .value = .@"else" });
    try expected_tokens.append(.{ .key = "enum", .value = .@"enum" });
    try expected_tokens.append(.{ .key = "fn", .value = .@"fn" });
    try expected_tokens.append(.{ .key = "for", .value = .@"for" });
    try expected_tokens.append(.{ .key = "if", .value = .@"if" });
    try expected_tokens.append(.{ .key = "pub", .value = .@"pub" });
    try expected_tokens.append(.{ .key = "return", .value = .@"return" });
    try expected_tokens.append(.{ .key = "struct", .value = .@"struct" });
    try expected_tokens.append(.{ .key = "try", .value = .@"try" });
    try expected_tokens.append(.{ .key = "union", .value = .@"union" });
    try expected_tokens.append(.{ .key = "while", .value = .@"while" });
    try expected_tokens.append(.{ .key = "as", .value = .as });
    try expected_tokens.append(.{ .key = "do", .value = .do });
    try expected_tokens.append(.{ .key = "false", .value = .false });
    try expected_tokens.append(.{ .key = "in", .value = .in });
    try expected_tokens.append(.{ .key = "let", .value = .let });
    try expected_tokens.append(.{ .key = "loop", .value = .loop });
    try expected_tokens.append(.{ .key = "match", .value = .match });
    try expected_tokens.append(.{ .key = "priv", .value = .priv });
    try expected_tokens.append(.{ .key = "self", .value = .self });
    try expected_tokens.append(.{ .key = "static", .value = .static });
    try expected_tokens.append(.{ .key = "super", .value = .super });
    try expected_tokens.append(.{ .key = "trait", .value = .trait });
    try expected_tokens.append(.{ .key = "true", .value = .true });
    try expected_tokens.append(.{ .key = "type", .value = .type });
    try expected_tokens.append(.{ .key = "typeof", .value = .typeof });
    try expected_tokens.append(.{ .key = "use", .value = .use });
    try expected_tokens.append(.{ .key = "where", .value = .where });
    try expected_tokens.append(.{ .key = "yield", .value = .yield });

    for (expected_tokens.items) |expected| {
        const token = try lexer.scan();
        try testing.expectEqualStrings(token.lexeme, expected.key);
        try testing.expect(@intFromEnum(token.type.keyword) == @intFromEnum(expected.value));
    }
}
