const std = @import("std");
const Self = @This();

pub const Keyword = enum {
    as,
    @"async",
    @"await",
    @"break",
    @"const",
    @"continue",
    do,
    @"else",
    @"enum",
    false,
    @"fn",
    @"for",
    @"if",
    in,
    let,
    loop,
    match,
    priv,
    @"pub",
    @"return",
    self,
    static,
    @"struct",
    super,
    trait,
    true,
    @"try",
    type,
    typeof,
    @"union",
    use,
    where,
    @"while",
    yield,

    pub fn format(self: Keyword, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer, "keyword({s})", .{@tagName(self)});
    }
};

pub const TokenType = union(enum) {
    // Keyword
    keyword: Keyword, // e.g: for, while, if, defer

    // Identifier
    identifier: []const u8, // e.g: name, age, users

    // Literals
    character: u8, // ''
    string: []const u8, // ""
    raw_string: []const u8, // ~r""
    byte: u8, // b{value} (integer coercible)
    byte_string: []const u8, // ~b""
    raw_byte_string: []const u8, // ~rb""

    // Punctuations
    plus, // +	Plus
    minus, // -	Minus
    star, // *	Star
    slash, // /	Slash
    slashslash, // //	SlashSlash
    percent, // %
    caret, // ^	Caret
    not, // !	Not
    @"and", // &
    @"or", // |	Or
    andand, // &&
    oror, // ||	OrOr
    shl, // <<	Shl
    shr, // >>	Shr
    pluseq, // +=
    minuseq, // -=
    stareq, // *=
    slasheq, // /=
    percenteq, // %=
    careteq, // ^=
    andeq, // &=
    oreq, // |=	OrEq
    shleq, // <<=
    shreq, // >>=
    eq, // =	Eq
    eqeq, // ==	EqEq
    ne, // !=	Ne
    gt, // >	Gt
    lt, // <	Lt
    ge, // >=	Ge
    le, // <=	Le
    at, // @	At
    underscore, // _
    dot, // .	Dot
    dotdot, // ..
    dotdotdot, // ...
    dotdoteq, // ..=
    comma, // ,	Comma
    semi, // ;	Semi
    colon, // :	Colon
    pathsep, // ::
    rarrow, // ->
    fatarrow, // =>
    pound, // #	Pound
    dollar, // $
    question, // ?
    tilde, // ~	Tilde

    // Delimiters
    lparen, // ( 	Parentheses
    rparen, // )	Parentheses
    lbrackets, // [ 	brackets
    rbrackets, // ]	brackets
    lbraces, // { 	braces
    rbraces, // }	braces

    pub fn format(self: TokenType, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        switch (self) {
            .byte => |byte| try std.fmt.format(writer, "b({b})", .{byte}),
            .character => |char| try std.fmt.format(writer, "char('{c}')", .{char}),
            .keyword => |kw| try kw.format(fmt, options, writer),
            .identifier => |ident| try std.fmt.format(writer, "{s}({{ {s} }})", .{ @tagName(self), ident }),
            .string, .byte_string, .raw_string, .raw_byte_string => |string| try std.fmt.format(writer, "{s}(\"{s}\")", .{ @tagName(self), string }),
            else => |token_type| try std.fmt.format(writer, "{s}", .{@tagName(token_type)}),
        }
    }
};
