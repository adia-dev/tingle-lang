const std = @import("std");
const Self = @This();

pub const Keyword = enum {
    @"async",
    @"await",
    @"break",
    @"const",
    @"continue",
    @"else",
    @"enum",
    @"fn",
    @"for",
    @"if",
    @"pub",
    @"return",
    @"struct",
    @"try",
    @"union",
    @"while",
    as,
    do,
    false,
    in,
    let,
    loop,
    null,
    match,
    priv,
    self,
    static,
    super,
    trait,
    true,
    type,
    typeof,
    use,
    where,
    yield,

    pub fn format(self: Keyword, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer, "keyword({s})", .{@tagName(self)});
    }
};

pub const TokenNumberType = enum {
    int,
    float,

    pub fn format(self: TokenNumberType, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer, "({s})", .{@tagName(self)});
    }
};

pub const TokenType = union(TokenTypeTag) {
    // End of File
    eof,
    // Illegal, most likely a non printable character
    illegal,
    // Keyword
    keyword: Keyword, // e.g: for, while, if, defer

    // Identifier
    identifier: []const u8, // e.g: name, age, users

    // Literals
    character: u8, // ''
    number: struct { literal: []const u8, type: TokenNumberType = .int }, // ""
    string: []const u8, // ""
    raw_string: []const u8, // ~r""
    byte: u8, // b{value} (integer coercible)
    byte_string: []const u8, // ~b""
    raw_byte_string: []const u8, // ~rb""

    // specials
    inline_comment,
    multi_line_comment,

    // Punctuations
    @"and", // &
    @"or", // |	Or
    andand, // &&
    andeq, // &=
    at, // @	At
    backtick, // `
    caret, // ^	Caret
    careteq, // ^=
    colon, // :	Colon
    comma, // ,	Comma
    dollar, // $
    dot, // .	Dot
    dotdot, // ..
    dotdotdot, // ...
    dotdoteq, // ..=
    doublequote, // "
    eq, // =	Eq
    eqeq, // ==	EqEq
    fatarrow, // =>
    ge, // >=	Ge
    gt, // >	Gt
    le, // <=	Le
    lt, // <	Lt
    minus, // -	Minus
    minusminus, // -- MinusMinus
    minuseq, // -=
    ne, // !=	Ne
    not, // !	Not
    oreq, // |=	OrEq
    oror, // ||	OrOr
    pathsep, // ::
    percent, // %
    percenteq, // %=
    plus, // +	Plus
    plusplus, // ++ PlusPlus
    pluseq, // +=
    piped, // |>
    pound, // #	Pound
    question, // ?
    quote, // '
    rarrow, // ->
    semi, // ;	Semi
    shl, // <<	Shl
    shleq, // <<=
    shr, // >>	Shr
    shreq, // >>=
    slash, // /	Slash
    slasheq, // /=
    star, // *	Star
    starstar, // **	StarStar
    stareq, // *=
    tilde, // ~	Tilde
    underscore, // _

    // Delimiters
    lparen, // ( 	Parentheses
    rparen, // )	Parentheses
    lbracket, // [ 	brackets
    rbracket, // ]	brackets
    lbrace, // { 	braces
    rbrace, // }	braces

    pub fn format(self: TokenType, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        switch (self) {
            .byte => |byte| try std.fmt.format(writer, "b({b})", .{byte}),
            .character => |char| try std.fmt.format(writer, "char('{c}')", .{char}),
            .keyword => |kw| try kw.format(fmt, options, writer),
            .identifier => |ident| try std.fmt.format(writer, "{s}(\"{s}\")", .{ @tagName(self), ident }),
            .number => |number| try std.fmt.format(writer, "{s}{s}(\"{s}\")", .{ @tagName(self), number.type, number.literal }),
            .string, .byte_string, .raw_string, .raw_byte_string => |string| try std.fmt.format(writer, "{s}(\"{s}\")", .{ @tagName(self), string }),
            else => |token_type| try std.fmt.format(writer, "{s}", .{@tagName(token_type)}),
        }
    }

    pub fn is(self: TokenType, tag: TokenTypeTag) bool {
        return @as(TokenTypeTag, self) == tag;
    }

    pub fn is_deep(self: TokenType, t: TokenType) bool {
        return self == t;
    }
};

pub const TokenTypeTag = enum {
    // End of File
    eof,
    // Illegal, most likely a non printable character
    illegal,
    // Keyword
    keyword, // e.g: for, while, if, defer

    // Identifier
    identifier, // e.g: name, age, users

    // Literals
    character, // ''
    number, // ""
    string, // ""
    raw_string, // ~r""
    byte, // b{value} (integer coercible)
    byte_string, // ~b""
    raw_byte_string, // ~rb""

    // specials
    inline_comment,
    multi_line_comment,

    // Punctuations
    @"and", // &
    @"or", // |	Or
    andand, // &&
    andeq, // &=
    at, // @	At
    backtick, // `
    caret, // ^	Caret
    careteq, // ^=
    colon, // :	Colon
    comma, // ,	Comma
    dollar, // $
    dot, // .	Dot
    dotdot, // ..
    dotdotdot, // ...
    dotdoteq, // ..=
    doublequote, // "
    eq, // =	Eq
    eqeq, // ==	EqEq
    fatarrow, // =>
    ge, // >=	Ge
    gt, // >	Gt
    le, // <=	Le
    lt, // <	Lt
    minus, // -	Minus
    minusminus, // -- MinusMinus
    minuseq, // -=
    ne, // !=	Ne
    not, // !	Not
    oreq, // |=	OrEq
    oror, // ||	OrOr
    pathsep, // ::
    percent, // %
    percenteq, // %=
    plus, // +	Plus
    plusplus, // ++ PlusPlus
    pluseq, // +=
    piped, // |>
    pound, // #	Pound
    question, // ?
    quote, // '
    rarrow, // ->
    semi, // ;	Semi
    shl, // <<	Shl
    shleq, // <<=
    shr, // >>	Shr
    shreq, // >>=
    slash, // /	Slash
    slasheq, // /=
    star, // *	Star
    starstar, // **	StarStar
    stareq, // *=
    tilde, // ~	Tilde
    underscore, // _

    // Delimiters
    lparen, // ( 	Parentheses
    rparen, // )	Parentheses
    lbracket, // [ 	brackets
    rbracket, // ]	brackets
    lbrace, // { 	braces
    rbrace, // }	braces
};
