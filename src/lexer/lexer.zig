pub const Token = @import("token.zig");
const std = @import("std");
const Self = @This();

line: usize = 1,
position: usize = 0,
next_position: usize = 0,
start_line_position: usize = 0,
c: u8 = 0,
allocator: std.mem.Allocator,
source_code: []const u8,

// TODO: change this to be statically initialized
keywords: std.StringHashMap(Token.Keyword) = undefined,

pub fn init(allocator: std.mem.Allocator, source_code: []const u8) !Self {
    var lexer = Self{ .allocator = allocator, .source_code = source_code };

    try lexer.init_keywords();

    lexer.advance();

    return lexer;
}

fn init_keywords(self: *Self) !void {
    self.keywords = std.StringHashMap(Token.Keyword).init(self.allocator);

    try self.keywords.put("async", .@"async");
    try self.keywords.put("await", .@"await");
    try self.keywords.put("break", .@"break");
    try self.keywords.put("const", .@"const");
    try self.keywords.put("continue", .@"continue");
    try self.keywords.put("else", .@"else");
    try self.keywords.put("enum", .@"enum");
    try self.keywords.put("fn", .@"fn");
    try self.keywords.put("for", .@"for");
    try self.keywords.put("if", .@"if");
    try self.keywords.put("pub", .@"pub");
    try self.keywords.put("return", .@"return");
    try self.keywords.put("struct", .@"struct");
    try self.keywords.put("try", .@"try");
    try self.keywords.put("union", .@"union");
    try self.keywords.put("while", .@"while");
    try self.keywords.put("as", .as);
    try self.keywords.put("do", .do);
    try self.keywords.put("false", .false);
    try self.keywords.put("in", .in);
    try self.keywords.put("let", .let);
    try self.keywords.put("loop", .loop);
    try self.keywords.put("match", .match);
    try self.keywords.put("priv", .priv);
    try self.keywords.put("self", .self);
    try self.keywords.put("static", .static);
    try self.keywords.put("super", .super);
    try self.keywords.put("trait", .trait);
    try self.keywords.put("true", .true);
    try self.keywords.put("type", .type);
    try self.keywords.put("typeof", .typeof);
    try self.keywords.put("use", .use);
    try self.keywords.put("where", .where);
    try self.keywords.put("yield", .yield);
}

pub fn scan(self: *Self) !Token {
    self.skip_whitespace();
    var token = Token{ .line = self.line, .row = self.position - self.start_line_position, .type = .illegal };

    switch (self.c) {
        0 => {
            token.type = .eof;
            return token;
        },
        'a'...'z', 'A'...'Z' => {
            const identifier = self.scan_identifier();
            if (self.keywords.get(identifier)) |kw| {
                token.type = .{ .keyword = kw };
            } else {
                token.type = .{ .identifier = identifier };
            }

            token.lexeme = identifier;
            token.literal = identifier;

            return token;
        },
        '0'...'9' => {
            const number = self.scan_number();
            token.type = .{ .number = number };
            token.lexeme = number;
            token.literal = number;

            return token;
        },
        '.' => {
            token.type = .dot;
        },
        ',' => {
            token.type = .comma;
        },
        ';' => {
            token.type = .semi;
        },
        ':' => {
            token.type = .semi;
        },
        '(' => {
            token.type = .lparen;
        },
        ')' => {
            token.type = .rparen;
        },
        '{' => {
            token.type = .lbrace;
        },
        '}' => {
            token.type = .rbrace;
        },
        '[' => {
            token.type = .lbracket;
        },
        ']' => {
            token.type = .rbracket;
        },
        '&' => {
            token.type = .@"and";
        },
        '|' => {
            token.type = .@"or";
        },
        '-' => {
            token.type = .minus;
        },
        '+' => {
            token.type = .plus;
        },
        '*' => {
            token.type = .star;
        },
        '/' => {
            token.type = .slash;
        },
        '!' => {
            token.type = .not;
        },
        '<' => {
            token.type = .lt;
        },
        '>' => {
            token.type = .gt;
        },
        '=' => {
            token.type = .eq;
        },
        '\'' => {
            token.type = .quote;
        },
        '"' => {
            token.type = .doublequote;
        },
        else => {},
    }

    const lexeme = self.source_code[self.position..self.next_position];
    token.lexeme = lexeme;
    token.literal = lexeme;

    self.advance();

    return token;
}

fn advance(self: *Self) void {
    if (self.next_position >= self.source_code.len) {
        self.c = 0;
    } else {
        self.c = self.source_code[self.next_position];
    }
    self.position = self.next_position;
    self.next_position += 1;
}

fn scan_identifier(self: *Self) []const u8 {
    const position = self.position;

    while (true) {
        switch (self.c) {
            'a'...'z', 'A'...'Z', '0'...'9', '_' => {
                self.advance();
            },
            else => break,
        }
    }

    return self.source_code[position..self.position];
}

fn scan_number(self: *Self) []const u8 {
    const position = self.position;

    while (true) {
        switch (self.c) {
            '0'...'9', '.', '_', 'e' => {
                self.advance();
            },
            else => break,
        }
    }

    return self.source_code[position..self.position];
}

fn skip_whitespace(self: *Self) void {
    while (true) {
        switch (self.c) {
            '\n' => {
                self.line += 1;
                self.start_line_position = self.position;
            },
            '\r', '\t', ' ' => {},
            else => break,
        }
        self.advance();
    }
}
