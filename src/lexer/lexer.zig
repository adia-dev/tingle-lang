pub const LexerError = @import("lexer_errors.zig").LexerError;

const Token = @import("../token/token.zig");
const TokenType = Token.TokenType;
const TokenNumberType = Token.TokenNumberType;
const std = @import("std");
const chroma = @import("chroma");
const Self = @This();

line: usize = 1,
position: usize = 0,
next_position: usize = 0,
start_line_position: usize = 0,
c: u8 = 0,
current_token: ?*Token = null,

allocator: std.mem.Allocator,
source_code: []const u8,
source_code_lines: std.ArrayList([]const u8) = undefined,
errors: std.ArrayList(LexerError),

// TODO: change this to be statically initialized
keywords: std.StringHashMap(Token.Keyword) = undefined,

pub fn init(allocator: std.mem.Allocator, source_code: []const u8) !Self {
    var lexer = Self{ .allocator = allocator, .source_code = source_code, .errors = std.ArrayList(LexerError).init(allocator) };

    try lexer.init_keywords();
    try lexer.init_source_code_lines();

    lexer.advance();

    return lexer;
}

pub fn deinit(self: *Self) void {
    self.keywords.deinit();
    self.errors.deinit();
    self.source_code_lines.deinit();
}

fn init_source_code_lines(self: *Self) !void {
    self.source_code_lines = std.ArrayList([]const u8).init(self.allocator);

    var i: usize = 0;
    var last_line_position: usize = 0;
    while (i < self.source_code.len) : (i += 1) {
        switch (self.source_code[i]) {
            '\n', 0 => {
                if (i != last_line_position) {
                    try self.source_code_lines.append(self.source_code[last_line_position..i]);
                    last_line_position = i + 1;
                    i += 1;
                }
            },
            else => {},
        }
    }

    if (i != last_line_position) {
        try self.source_code_lines.append(self.source_code[last_line_position..i]);
        last_line_position = i + 1;
        i += 1;
    }

    std.debug.print("Source Code:\n", .{});
    for (self.source_code_lines.items) |line| {
        std.debug.print(comptime chroma.format("{241}{s}\n"), .{line});
    }
}

fn init_keywords(self: *Self) !void {
    self.keywords = std.StringHashMap(Token.Keyword).init(self.allocator);

    //NOTE: zig metaprogramming is so gooooood
    inline for (@typeInfo(Token.Keyword).Enum.fields) |f| {
        try self.keywords.put(f.name, @field(Token.Keyword, f.name));
    }
}

pub fn scan(self: *Self) !Token {
    self.skip_whitespace();
    var token = Token{ .line = self.line, .col = self.position - self.start_line_position + 1, .type = .illegal };

    self.current_token = &token;

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

            return token;
        },
        '0'...'9' => {
            // tuple containing the literal and the type (int or float)
            const number = try self.scan_number();
            token.type = .{ .number = .{ .literal = number[0], .type = number[1] } };
            token.lexeme = number[0];

            return token;
        },
        '.' => {
            if (self.advance_into(".=")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .dotdoteq;
                return token;
            } else if (self.advance_into("..")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .dotdotdot;
                return token;
            } else if (self.advance_into(".")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .dotdot;
                return token;
            }
            token.type = .dot;
        },
        ',' => {
            token.type = .comma;
        },
        ';' => {
            token.type = .semi;
        },
        ':' => {
            if (self.advance_into(":")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .pathsep;
                return token;
            }
            token.type = .colon;
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
        '@' => {
            token.type = .at;
        },
        '&' => {
            if (self.advance_into("&")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .andand;
                return token;
            } else if (self.advance_into("=")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .andeq;
                return token;
            }
            token.type = .@"and";
        },
        '|' => {
            if (self.advance_into("|")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .oror;
                return token;
            } else if (self.advance_into("=")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .oreq;
                return token;
            } else if (self.advance_into(">")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .piped;
                return token;
            }

            token.type = .@"or";
        },
        '-' => {
            if (self.advance_into("-")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .minusminus;
                return token;
            } else if (self.advance_into(">")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .rarrow;
                return token;
            } else if (self.advance_into("=")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .minuseq;
                return token;
            }
            token.type = .minus;
        },
        '+' => {
            if (self.advance_into("+")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .plusplus;
                return token;
            } else if (self.advance_into("=")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .pluseq;
                return token;
            }
            token.type = .plus;
        },
        '*' => {
            if (self.advance_into("*")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .starstar;
                return token;
            } else if (self.advance_into("=")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .stareq;
                return token;
            }
            token.type = .star;
        },
        '/' => {
            if (self.advance_into("/")) |lexeme| {
                try self.scan_inline_comment();
                token.lexeme = lexeme;
                token.type = .inline_comment;
                return token;
            } else if (self.advance_into("*")) |lexeme| {
                try self.scan_multi_line_comment();
                token.lexeme = lexeme;
                token.type = .multi_line_comment;
                return token;
            } else if (self.advance_into("=")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .slasheq;
                return token;
            }
            token.type = .slash;
        },
        '!' => {
            if (self.advance_into("=")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .ne;
                return token;
            }
            token.type = .not;
        },
        '<' => {
            if (self.advance_into("<=")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .shleq;
                return token;
            } else if (self.advance_into("<")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .shl;
                return token;
            } else if (self.advance_into("=")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .le;
                return token;
            }
            token.type = .lt;
        },
        '>' => {
            if (self.advance_into(">=")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .shreq;
                return token;
            } else if (self.advance_into(">")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .shr;
                return token;
            } else if (self.advance_into("=")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .ge;
                return token;
            }
            token.type = .gt;
        },
        '=' => {
            if (self.advance_into("=")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .eqeq;
                return token;
            } else if (self.advance_into(">")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .fatarrow;
                return token;
            }
            token.type = .eq;
        },
        '\'' => {
            self.advance();
            const byte_char = try self.scan_char();
            token.lexeme = byte_char;
            token.type = .{ .byte = if (byte_char.len > 0) byte_char[0] else 0 };
            self.advance();
            return token;
        },
        '"' => {
            self.advance();
            const string = try self.scan_string();
            token.lexeme = string;
            token.type = .{ .string = string };
            self.advance();
            return token;
        },
        '#' => {
            token.type = .pound;
        },
        '$' => {
            token.type = .dollar;
        },
        '%' => {
            if (self.advance_into("=")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .percenteq;
                return token;
            }
            token.type = .percent;
        },
        '^' => {
            if (self.advance_into("=")) |lexeme| {
                token.lexeme = lexeme;
                token.type = .careteq;
                return token;
            }
            token.type = .caret;
        },
        '`' => {
            token.type = .backtick;
        },
        '?' => {
            token.type = .question;
        },
        '_' => {
            switch (self.peek()) {
                'a'...'z', 'A'...'Z' => {
                    const identifier = self.scan_identifier();
                    token.type = .{ .identifier = identifier };
                    token.lexeme = identifier;
                    return token;
                },
                else => {
                    token.type = .underscore;
                },
            }
        },
        '~' => {
            if (self.advance_into("r\"")) |_| {
                const string = try self.scan_string();
                token.lexeme = string;
                token.type = .{ .raw_string = string };
                self.advance();
                return token;
            } else if (self.advance_into("b\"")) |_| {
                const string = try self.scan_string();
                token.lexeme = string;
                token.type = .{ .byte_string = string };
                self.advance();
                return token;
            } else if (self.advance_into("b'")) |_| {
                const byte_char = try self.scan_char();
                token.lexeme = byte_char;
                token.type = .{ .byte = byte_char[0] };
                self.advance();
                return token;
            } else if (self.advance_into("rb\"")) |_| {
                const string = try self.scan_string();
                token.lexeme = string;
                token.type = .{ .raw_byte_string = string };
                self.advance();
                return token;
            }
            token.type = .tilde;
        },
        else => {},
    }

    const lexeme = self.source_code[self.position..self.next_position];
    token.lexeme = lexeme;

    if (token.type == .illegal) {
        try self.errors.append(.{ .@"error" = error.IllegalCharacter, .lexer = self, .code = .{ .illegal_character = .{ .char = self.source_code[self.position] } } });
        return error.IllegalCharacter;
    }

    self.advance();

    self.current_token = null;

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

pub fn peek(self: *Self) u8 {
    if (self.next_position >= self.source_code.len) {
        return 0;
    } else {
        return self.source_code[self.next_position];
    }
}

pub fn advance_into(self: *Self, expected: []const u8) ?[]const u8 {
    const position = self.position;
    const next_position = self.next_position;
    for (expected, 0..) |c, i| {
        if (i >= self.source_code.len or c != self.peek()) {
            self.position = position;
            self.next_position = next_position;
            return null;
        }
        self.advance();
    }

    self.advance();

    return self.source_code[position..self.position];
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

fn scan_inline_comment(self: *Self) !void {
    while (true) : (self.advance()) {
        switch (self.c) {
            '\n', 0 => {
                break;
            },
            else => {},
        }
    }
}

fn scan_multi_line_comment(self: *Self) !void {
    while (true) : (self.advance()) {
        switch (self.c) {
            0 => {
                try self.errors.append(.{ .@"error" = error.UnmatchedDelimiter, .lexer = self, .code = .{ .unmatched_delimiter = .{ .expected_delimiter = "*/" } } });
                return error.UnmatchedDelimiter;
            },
            '*' => {
                if (self.peek() == '/') {
                    break;
                }
            },
            else => {},
        }
    }

    // skipping the */
    self.advance();
    self.advance();
}

fn scan_number(self: *Self) !struct { []const u8, TokenNumberType } {
    const position = self.position;
    var t: TokenNumberType = .int;

    var encountered_dots: usize = 0;
    while (true) {
        switch (self.c) {
            '0'...'9', '.', '_', 'e' => {
                if (self.c == '.') {
                    switch (self.peek()) {
                        'a'...'z', 'A'...'Z', '_' => {
                            // early returns, could be a function call
                            // e.g: 3.14.floor();
                            return .{ self.source_code[position..self.position], t };
                        },
                        else => {},
                    }
                    encountered_dots += 1;
                    t = .float;
                }
                self.advance();
            },
            else => break,
        }
    }

    if (encountered_dots > 1) {
        try self.errors.append(.{ .@"error" = error.InvalidNumberFormat, .lexer = self, .code = .{ .invalid_number_format = .{ .number = self.source_code[position..self.position] } } });
        return error.InvalidNumberFormat;
    }

    return .{ self.source_code[position..self.position], t };
}

fn scan_string(self: *Self) ![]const u8 {
    const position = self.position;

    while (self.c != '"') : (self.advance()) {
        if (self.is_eof()) {
            try self.errors.append(.{ .@"error" = error.UnmatchedDelimiter, .lexer = self, .code = .{ .unmatched_delimiter = .{ .expected_delimiter = "\"" } } });
            return error.UnmatchedDelimiter;
        }

        if (self.c == '\\') {
            try self.escape_sequence();
        }
    }

    return self.source_code[position..self.position];
}

fn scan_char(self: *Self) ![]const u8 {
    const position = self.position;

    var i: usize = 0;
    while (self.c != '\'') : (self.advance()) {
        if (self.is_eof()) {
            try self.errors.append(.{ .@"error" = error.UnmatchedDelimiter, .lexer = self, .code = .{ .unmatched_delimiter = .{ .expected_delimiter = "'" } } });
            return error.UnmatchedDelimiter;
        }

        if (self.c == '\\') {
            try self.escape_sequence();
        }

        i += 1;
    }

    if (i > 1) {
        try self.errors.append(.{ .@"error" = error.InvalidCharSize, .lexer = self, .code = .{ .invalid_char_size = .{ .char = self.source_code[position..self.position] } } });
        return error.InvalidCharSize;
    }

    return self.source_code[position..self.position];
}

fn escape_sequence(self: *Self) !void {
    switch (self.peek()) {
        'n', 't', 'v', 'b', 'r', 'f', 'a', '\\', '\'', '\"', '0' => {
            self.advance();
        },
        // TODO: check that the number after the escaped `x`
        // is an actual hex number
        'x' => {
            self.advance();
        },
        else => {
            try self.errors.append(.{ .@"error" = error.InvalidEscapedSequence, .lexer = self, .code = .{ .invalid_escaped_sequence = .{ .sequence = self.source_code[self.position..(self.next_position + 1)] } } });
            return error.InvalidEscapedSequence;
        },
    }
}

fn is_eof(self: *Self) bool {
    return self.c == 0;
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
