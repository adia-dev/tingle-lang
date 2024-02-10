const std = @import("std");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const AutoHashMap = std.AutoHashMap;
const testing = std.testing;

const Lexer = @import("lexer.zig");
const LexerError = Lexer.LexerError;
const Token = @import("../token/token.zig");
const TokenType = Token.TokenType;
const Keyword = Token.Keyword;

test "Lexer - Scans keyword tokens" {
    const ta = testing.allocator;
    const source_code: []const u8 =
        \\ async await break
        \\ const continue else
        \\ enum fn for
        \\ if pub return
        \\ struct try union
        \\ while as do
        \\ false in let
        \\ loop null match priv
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
    try expected_tokens.append(.{ .key = "null", .value = .null });
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

test "Lexer - Illegal character" {
    const ta = testing.allocator;
    const source_code: []const u8 = "非";

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    try testing.expectError(error.IllegalCharacter, lexer.scan());
    try testing.expectEqual(1, lexer.errors.items.len);
    try testing.expectError(error.IllegalCharacter, lexer.errors.items[0].err());
}

test "Lexer - Unmatched delimiters" {
    const ta = testing.allocator;
    const source_code: []const u8 = "\"This string never ends...";

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    try testing.expectError(error.UnmatchedDelimiter, lexer.scan());
    try testing.expectEqual(1, lexer.errors.items.len);
    try testing.expectError(error.UnmatchedDelimiter, lexer.errors.items[0].err());
    try testing.expectEqualStrings("\"", lexer.errors.items[0].trace.unmatched_delimiter.expected_delimiter);
}

test "Lexer - Invalid number format" {
    const ta = testing.allocator;
    const source_code: []const u8 = "12.34.56";

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    try testing.expectError(error.InvalidNumberFormat, lexer.scan());
    try testing.expectEqual(1, lexer.errors.items.len);
    try testing.expectError(error.InvalidNumberFormat, lexer.errors.items[0].err());
}

test "Lexer - Invalid escaped sequence on string" {
    const ta = testing.allocator;
    const source_code: []const u8 = "\"This is \\invalid\"";

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    try testing.expectError(error.InvalidEscapedSequence, lexer.scan());
    try testing.expectEqual(1, lexer.errors.items.len);
    try testing.expectError(error.InvalidEscapedSequence, lexer.errors.items[0].err());
    try testing.expectEqualStrings("\\i", lexer.errors.items[0].trace.invalid_escaped_sequence.sequence);
}

test "Lexer - Invalid escaped sequence on char" {
    const ta = testing.allocator;
    const source_code: []const u8 = "\'\\l\'";

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    try testing.expectError(error.InvalidEscapedSequence, lexer.scan());
    try testing.expectEqual(1, lexer.errors.items.len);
    try testing.expectError(error.InvalidEscapedSequence, lexer.errors.items[0].err());
    try testing.expectEqualStrings("\\l", lexer.errors.items[0].trace.invalid_escaped_sequence.sequence);
}

test "Lexer - Unexpected end of file" {
    const ta = testing.allocator;
    const source_code: []const u8 = "/* Comment without an end";

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    try testing.expectError(error.UnmatchedDelimiter, lexer.scan());
    try testing.expectEqual(1, lexer.errors.items.len);
    try testing.expectError(error.UnmatchedDelimiter, lexer.errors.items[0].err());
    try testing.expectEqualStrings("*/", lexer.errors.items[0].trace.unmatched_delimiter.expected_delimiter);
}

test "Lexer - Invalid character size" {
    const ta = testing.allocator;
    const source_code: []const u8 = "'ab'";

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    try testing.expectError(error.InvalidCharSize, lexer.scan());
    try testing.expectEqual(1, lexer.errors.items.len);
    try testing.expectError(error.InvalidCharSize, lexer.errors.items[0].err());
}
test "Lexer - Unsupported character encoding" {
    const ta = testing.allocator;
    const source_code: []const u8 = "这是中文";

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    // TODO: the error should be, error.UnsupportedCharacterEncoding, but it
    // is currently not implemented
    try testing.expectError(error.IllegalCharacter, lexer.scan());
    try testing.expectEqual(1, lexer.errors.items.len);
    try testing.expectError(error.IllegalCharacter, lexer.errors.items[0].err());
}

test "Lexer - Empty input" {
    const ta = testing.allocator;
    const source_code: []const u8 = "";

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    const token = try lexer.scan();
    try testing.expectEqual(0, lexer.errors.items.len);
    try testing.expectEqual(TokenType.eof, token.type);
}

test "Lexer - White space handling" {
    const ta = testing.allocator;
    const source_code: []const u8 = "   \n\tconst";

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    const token = try lexer.scan();
    try testing.expectEqualStrings(token.lexeme, "const");
}

test "Lexer - Comment handling" {
    const ta = testing.allocator;
    const source_code: []const u8 = "// This is a comment\nlet x: u32 = 10;";

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    _ = try lexer.scan();

    var expected_tokens = ArrayList(struct { key: []const u8, value: TokenType }).init(ta);
    defer expected_tokens.deinit();

    try expected_tokens.append(.{ .key = "let", .value = .{ .keyword = .let } });
    try expected_tokens.append(.{ .key = "x", .value = .{ .identifier = "x" } });
    try expected_tokens.append(.{ .key = ":", .value = .colon });
    try expected_tokens.append(.{ .key = "u32", .value = .{ .identifier = "u32" } });
    try expected_tokens.append(.{ .key = "=", .value = .eq });
    try expected_tokens.append(.{ .key = "10", .value = .{ .number = .{ .literal = "10" } } });
    try expected_tokens.append(.{ .key = ";", .value = .semi });

    for (expected_tokens.items) |expected| {
        const token = try lexer.scan();
        try testing.expectEqualStrings(token.lexeme, expected.key);
        try testing.expect(@intFromEnum(token.type) == @intFromEnum(expected.value));
    }
}

test "Lexer - String literal" {
    const ta = testing.allocator;
    const source_code: []const u8 = "\"Hello, World!\"";

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    const token = try lexer.scan();
    try testing.expectEqual(@intFromEnum(token.type), @intFromEnum(TokenType.string));
    try testing.expectEqualStrings(token.type.string, "Hello, World!");
}

test "Lexer - Numeric literal" {
    const ta = testing.allocator;
    const source_code: []const u8 = "42 3.14";

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    var token = try lexer.scan();
    try testing.expectEqual(@intFromEnum(token.type), @intFromEnum(TokenType.number));
    try testing.expectEqualStrings(token.type.number.literal, "42");

    token = try lexer.scan();
    try testing.expectEqual(@intFromEnum(token.type), @intFromEnum(TokenType.number));
    try testing.expectEqualStrings(token.type.number.literal, "3.14");
}

// src/lexer/lexer_tests.zig

test "Lexer - Identifiers" {
    const ta = testing.allocator;
    const source_code: []const u8 = "identifier _underscore mixedCase123";

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    var expected_tokens = ArrayList(struct { key: []const u8, value: TokenType }).init(ta);
    defer expected_tokens.deinit();

    try expected_tokens.append(.{ .key = "identifier", .value = .{ .identifier = "identifier" } });
    try expected_tokens.append(.{ .key = "_underscore", .value = .{ .identifier = "_underscore" } });
    try expected_tokens.append(.{ .key = "mixedCase123", .value = .{ .identifier = "mixedCase123" } });

    for (expected_tokens.items) |expected| {
        const token = try lexer.scan();
        try testing.expectEqualStrings(token.lexeme, expected.key);
        try testing.expect(@intFromEnum(token.type) == @intFromEnum(expected.value));
    }
}

test "Lexer - Numeric literals" {
    const ta = testing.allocator;
    const source_code: []const u8 = "42 3.14 123_456_789";

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    var expected_tokens = ArrayList(struct { key: []const u8, value: TokenType }).init(ta);
    defer expected_tokens.deinit();

    try expected_tokens.append(.{ .key = "42", .value = .{ .number = .{ .literal = "42" } } });
    try expected_tokens.append(.{ .key = "3.14", .value = .{ .number = .{ .literal = "3.14" } } });
    try expected_tokens.append(.{ .key = "123_456_789", .value = .{ .number = .{ .literal = "123_456_789" } } });

    // TODO: Implemented those cases
    // try expected_tokens.append(.{ .key = "0xFF", .value = .{ .number = "0xFF" } });
    // try expected_tokens.append(.{ .key = "b1010", .value = .{ .number = "b1010" } });
    // try expected_tokens.append(.{ .key = "0o755", .value = .{ .number = "0o755" } });

    for (expected_tokens.items) |expected| {
        const token = try lexer.scan();
        try testing.expectEqualStrings(token.lexeme, expected.key);
        try testing.expect(@intFromEnum(token.type) == @intFromEnum(expected.value));
    }
}

test "Lexer - String literals" {
    const ta = testing.allocator;
    const source_code: []const u8 = "\"string\" \"escaped\\nnewline\" \"empty\"";

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    var expected_tokens = ArrayList(struct { key: []const u8, value: TokenType }).init(ta);
    defer expected_tokens.deinit();

    try expected_tokens.append(.{ .key = "\"string\"", .value = .{ .string = "string" } });
    try expected_tokens.append(.{ .key = "\"escaped\\nnewline\"", .value = .{ .string = "escaped\\nnewline" } });
    try expected_tokens.append(.{ .key = "\"empty\"", .value = .{ .string = "empty" } });

    for (expected_tokens.items) |expected| {
        const token = try lexer.scan();
        try testing.expectEqualStrings(token.type.string, expected.value.string);
        try testing.expect(@intFromEnum(token.type) == @intFromEnum(expected.value));
    }
}

test "Lexer - Punctuation" {
    const ta = testing.allocator;
    const source_code: []const u8 = ",;(){}[]";

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    var expected_tokens = ArrayList(struct { key: []const u8, value: TokenType }).init(ta);
    defer expected_tokens.deinit();

    try expected_tokens.append(.{ .key = ",", .value = .comma });
    try expected_tokens.append(.{ .key = ";", .value = .semi });
    try expected_tokens.append(.{ .key = "(", .value = .lparen });
    try expected_tokens.append(.{ .key = ")", .value = .rparen });
    try expected_tokens.append(.{ .key = "{", .value = .lbrace });
    try expected_tokens.append(.{ .key = "}", .value = .rbrace });
    try expected_tokens.append(.{ .key = "[", .value = .lbracket });
    try expected_tokens.append(.{ .key = "]", .value = .rbracket });

    for (expected_tokens.items) |expected| {
        const token = try lexer.scan();
        try testing.expectEqualStrings(token.lexeme, expected.key);
        try testing.expect(@intFromEnum(token.type) == @intFromEnum(expected.value));
    }
}

test "Lexer - All Punctuation Tokens" {
    const ta = testing.allocator;
    const source_code: []const u8 =
        \\ & | && &= @ ` 
        \\ ^ ^= : , $ 
        \\ . .. ... ..= 
        \\ = == => >= > <= < 
        \\ - -- -= != ! |= || 
        \\ :: % %= + ++ += |> 
        \\ # ? -> ; 
        \\ << <<= >> >>= 
        \\ / /= * ** *= ~ _
    ;

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    var expected_tokens = ArrayList(struct { key: []const u8, value: TokenType }).init(ta);
    defer expected_tokens.deinit();

    try expected_tokens.append(.{ .key = "&", .value = .@"and" });
    try expected_tokens.append(.{ .key = "|", .value = .@"or" });
    try expected_tokens.append(.{ .key = "&&", .value = .andand });
    try expected_tokens.append(.{ .key = "&=", .value = .andeq });
    try expected_tokens.append(.{ .key = "@", .value = .at });
    try expected_tokens.append(.{ .key = "`", .value = .backtick });
    try expected_tokens.append(.{ .key = "^", .value = .caret });
    try expected_tokens.append(.{ .key = "^=", .value = .careteq });
    try expected_tokens.append(.{ .key = ":", .value = .colon });
    try expected_tokens.append(.{ .key = ",", .value = .comma });
    try expected_tokens.append(.{ .key = "$", .value = .dollar });
    try expected_tokens.append(.{ .key = ".", .value = .dot });
    try expected_tokens.append(.{ .key = "..", .value = .dotdot });
    try expected_tokens.append(.{ .key = "...", .value = .dotdotdot });
    try expected_tokens.append(.{ .key = "..=", .value = .dotdoteq });
    try expected_tokens.append(.{ .key = "=", .value = .eq });
    try expected_tokens.append(.{ .key = "==", .value = .eqeq });
    try expected_tokens.append(.{ .key = "=>", .value = .fatarrow });
    try expected_tokens.append(.{ .key = ">=", .value = .ge });
    try expected_tokens.append(.{ .key = ">", .value = .gt });
    try expected_tokens.append(.{ .key = "<=", .value = .le });
    try expected_tokens.append(.{ .key = "<", .value = .lt });
    try expected_tokens.append(.{ .key = "-", .value = .minus });
    try expected_tokens.append(.{ .key = "--", .value = .minusminus });
    try expected_tokens.append(.{ .key = "-=", .value = .minuseq });
    try expected_tokens.append(.{ .key = "!=", .value = .ne });
    try expected_tokens.append(.{ .key = "!", .value = .not });
    try expected_tokens.append(.{ .key = "|=", .value = .oreq });
    try expected_tokens.append(.{ .key = "||", .value = .oror });
    try expected_tokens.append(.{ .key = "::", .value = .pathsep });
    try expected_tokens.append(.{ .key = "%", .value = .percent });
    try expected_tokens.append(.{ .key = "%=", .value = .percenteq });
    try expected_tokens.append(.{ .key = "+", .value = .plus });
    try expected_tokens.append(.{ .key = "++", .value = .plusplus });
    try expected_tokens.append(.{ .key = "+=", .value = .pluseq });
    try expected_tokens.append(.{ .key = "|>", .value = .piped });
    try expected_tokens.append(.{ .key = "#", .value = .pound });
    try expected_tokens.append(.{ .key = "?", .value = .question });
    try expected_tokens.append(.{ .key = "->", .value = .rarrow });
    try expected_tokens.append(.{ .key = ";", .value = .semi });
    try expected_tokens.append(.{ .key = "<<", .value = .shl });
    try expected_tokens.append(.{ .key = "<<=", .value = .shleq });
    try expected_tokens.append(.{ .key = ">>", .value = .shr });
    try expected_tokens.append(.{ .key = ">>=", .value = .shreq });
    try expected_tokens.append(.{ .key = "/", .value = .slash });
    try expected_tokens.append(.{ .key = "/=", .value = .slasheq });
    try expected_tokens.append(.{ .key = "*", .value = .star });
    try expected_tokens.append(.{ .key = "**", .value = .starstar });
    try expected_tokens.append(.{ .key = "*=", .value = .stareq });
    try expected_tokens.append(.{ .key = "~", .value = .tilde });
    try expected_tokens.append(.{ .key = "_", .value = .underscore });

    for (expected_tokens.items) |expected| {
        const token = try lexer.scan();
        try testing.expectEqualStrings(token.lexeme, expected.key);
        try testing.expect(@intFromEnum(token.type) == @intFromEnum(expected.value));
    }
}
