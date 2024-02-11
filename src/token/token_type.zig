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
    ///End of File
    eof,
    ///Illegal, most likely a non printable character
    illegal,
    ///Keyword
    keyword: Keyword, // e.g: for, while, if, defer

    ///Identifier
    identifier: []const u8, // e.g: name, age, users

    ///Literals
    ///Single byte, more likely ASCII
    character: u8, // ''
    ///Number, either int or float
    number: struct { literal: []const u8, type: TokenNumberType = .int }, // ""
    ///String, sequence of bytes
    string: []const u8, // ""
    ///Raw String, no need to escape characters
    raw_string: []const u8, // ~r""
    ///Single byte, used to represent character
    byte: u8, // b{value} (integer coercible)
    ///A string represented as a sequence of byte
    byte_string: []const u8, // ~b""
    ///A string of raw byte characters
    raw_byte_string: []const u8, // ~rb""

    // specials
    ///Inline comment, represented with: //
    inline_comment,
    ///Multi line comment, represented with: /* ... */
    multi_line_comment,

    // Punctuations
    ///&
    @"and",
    ///|   Or
    @"or",
    ///&&
    andand,
    ///&=
    andeq,
    ///@   At
    at,
    ///`
    backtick,
    ///^   Caret
    caret,
    ///^=
    careteq,
    ///:   Colon
    colon,
    ///,   Comma
    comma,
    ///$
    dollar,
    ///.   Dot
    dot,
    ///..
    dotdot,
    ///...
    dotdotdot,
    ///..=
    dotdoteq,
    ///"
    doublequote,
    ///=   Eq
    eq,
    ///==  EqEq
    eqeq,
    ///=>
    fatarrow,
    ///>=  Ge
    ge,
    ///>   Gt
    gt,
    ///<=  Le
    le,
    ///<   Lt
    lt,
    ///-   Minus
    minus,
    ///-- MinusMinus
    minusminus,
    ///-=
    minuseq,
    ///!=  Ne
    ne,
    ///!   Not
    not,
    ///|=  OrEq
    oreq,
    ///||  OrOr
    oror,
    ///::
    pathsep,
    ///%
    percent,
    ///%=
    percenteq,
    ///+   Plus
    plus,
    ///++ PlusPlus
    plusplus,
    ///+=
    pluseq,
    ///|>
    piped,
    ///#   Pound
    pound,
    ///?
    question,
    ///'
    quote,
    ///->
    rarrow,
    ///;   Semi
    semi,
    ///<<  Shl
    shl,
    ///<<=
    shleq,
    ///>>  Shr
    shr,
    ///>>=
    shreq,
    ///\/   Slash
    slash,
    ///\/=
    slasheq,
    ///*   Star
    star,
    ///**  StarStar
    starstar,
    ///*=
    stareq,
    ///~   Tilde
    tilde,
    ///_
    underscore,

    // Delimiters
    ///(   Parentheses
    lparen,
    ///)   Parentheses
    rparen,
    ///[   brackets
    lbracket,
    ///]   brackets
    rbracket,
    ///{   braces
    lbrace,
    ///}   braces
    rbrace,

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
    ///End of File
    eof,
    ///Illegal, most likely a non printable character
    illegal,
    ///Keyword
    ///e.g: for, while, if, defer
    keyword,

    // Identifier
    identifier, // e.g: name, age, users

    // Literals
    ///Single byte, more likely ASCII
    character,
    ///""
    number,
    ///""
    string,
    ///~r""
    raw_string,
    ///b{value} (integer coercible)
    byte,
    ///~b""
    byte_string,
    ///~rb""
    raw_byte_string,

    // specials
    inline_comment,
    multi_line_comment,

    // Punctuations
    ///&
    @"and",
    ///|   Or
    @"or",
    ///&&
    andand,
    ///&=
    andeq,
    ///@   At
    at,
    ///`
    backtick,
    ///^   Caret
    caret,
    ///^=
    careteq,
    ///:   Colon
    colon,
    ///,   Comma
    comma,
    ///$
    dollar,
    ///.   Dot
    dot,
    ///..
    dotdot,
    ///...
    dotdotdot,
    ///..=
    dotdoteq,
    ///"
    doublequote,
    ///=   Eq
    eq,
    ///==  EqEq
    eqeq,
    ///=>
    fatarrow,
    ///>=  Ge
    ge,
    ///>   Gt
    gt,
    ///<=  Le
    le,
    ///<   Lt
    lt,
    ///-   Minus
    minus,
    ///-- MinusMinus
    minusminus,
    ///-=
    minuseq,
    ///!=  Ne
    ne,
    ///!   Not
    not,
    ///|=  OrEq
    oreq,
    ///||  OrOr
    oror,
    ///::
    pathsep,
    ///%
    percent,
    ///%=
    percenteq,
    ///+   Plus
    plus,
    ///++ PlusPlus
    plusplus,
    ///+=
    pluseq,
    ///|>
    piped,
    ///#   Pound
    pound,
    ///?
    question,
    ///'
    quote,
    ///->
    rarrow,
    ///;   Semi
    semi,
    ///<<  Shl
    shl,
    ///<<=
    shleq,
    ///>>  Shr
    shr,
    ///>>=
    shreq,
    ///\/   Slash
    slash,
    ///\/=
    slasheq,
    ///*   Star
    star,
    ///**  StarStar
    starstar,
    ///*=
    stareq,
    ///~   Tilde
    tilde,
    ///_
    underscore,

    // Delimiters
    ///(   Parentheses
    lparen,
    ///)   Parentheses
    rparen,
    ///[   brackets
    lbracket,
    ///]   brackets
    rbracket,
    ///{   braces
    lbrace,
    ///}   braces
    rbrace,
};
