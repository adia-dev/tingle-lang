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

pub const TokenType = union(enum) {
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
    number: []const u8, // ""
    string: []const u8, // ""
    raw_string: []const u8, // ~r""
    byte: u8, // b{value} (integer coercible)
    byte_string: []const u8, // ~b""
    raw_byte_string: []const u8, // ~rb""

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
    slashslash, // //	SlashSlash
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
            .number => |number| try std.fmt.format(writer, "{s}(\"{s}\")", .{ @tagName(self), number }),
            .string, .byte_string, .raw_string, .raw_byte_string => |string| try std.fmt.format(writer, "{s}(\"{s}\")", .{ @tagName(self), string }),
            else => |token_type| try std.fmt.format(writer, "{s}", .{@tagName(token_type)}),
        }
    }
};
