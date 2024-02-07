const std = @import("std");
const ast = @import("../ast/ast.zig");
const Token = @import("../token/token.zig");
const Lexer = @import("../lexer/lexer.zig");
const TokenType = Token.TokenType;
const TokenTypeTag = Token.TokenTypeTag;
const ParserError = @import("parser_error.zig").ParserError;

const Expressions = ast.Expressions;
const Identifier = Expressions.Identifier;

const Statements = ast.Statements;
const Statement = Statements.Statement;
const Program = Statements.Program;
const LetStatement = Statements.LetStatement;
const ReturnStatement = Statements.ReturnStatement;

const Self = @This();

lexer: *Lexer,
current_token: Token = undefined,
next_token: Token = undefined,
arena: std.heap.ArenaAllocator,

pub fn init(allocator: std.mem.Allocator, lexer: *Lexer) !Self {
    var parser = Self{ .arena = std.heap.ArenaAllocator.init(allocator), .lexer = lexer };

    try parser.advance();
    try parser.advance();

    return parser;
}

pub fn deinit(self: *Self) void {
    self.arena.deinit();
}

pub fn parse(self: *Self) !Program {
    var program = Statements.Program.init(self.arena.allocator());

    while (self.current_token.type != .eof) {
        if (try self.parse_statement()) |statement| {
            try program.statements.append(statement);
        }
        try self.advance();
    }

    return program;
}

fn parse_statement(self: *Self) !?Statement {
    switch (self.current_token.type) {
        .keyword => |kw| {
            return switch (kw) {
                .let => try self.parse_let_statement(),
                .@"return" => try self.parse_return_statement(),
                else => return null,
            };
        },
        else => return null,
    }
}

fn parse_let_statement(self: *Self) !Statement {
    var stmt = try self.arena.allocator().create(LetStatement);
    const current_token = self.current_token;

    if (!self.next_token_is(.identifier)) {
        return error.UnexpectedToken;
    }
    try self.advance();

    stmt.* = .{};
    stmt.token = current_token;
    stmt.identifier = Identifier{ .token = self.current_token, .value = self.current_token.lexeme };

    if (!self.next_token_is(.eq)) {
        return error.UnexpectedToken;
    }
    try self.advance();

    while (!self.current_token_is(.semi)) : (try self.advance()) {
        if (self.current_token_is(.eof)) {
            return error.UnexpectedEof;
        }

        if (self.current_token_is(.illegal)) {
            return error.IllegalToken;
        }
    }

    return Statement{ .let = stmt };
}

fn parse_return_statement(self: *Self) !Statement {
    var stmt = try self.arena.allocator().create(ReturnStatement);
    stmt.* = .{};
    stmt.token = self.current_token;

    while (!self.current_token_is(.semi)) : (try self.advance()) {
        if (self.current_token_is(.eof)) {
            return error.UnexpectedEof;
        }

        if (self.current_token_is(.illegal)) {
            return error.IllegalToken;
        }
    }

    return Statement{ .@"return" = stmt };
}

fn advance(self: *Self) !void {
    self.current_token = self.next_token;
    self.next_token = try self.lexer.scan();
}

fn is_eof(self: *Self) bool {
    return self.current_token_is(.eof);
}

fn current_token_is(self: *Self, token_type_tag: TokenTypeTag) bool {
    return self.current_token.type.is(token_type_tag);
}

fn next_token_is(self: *Self, token_type_tag: TokenTypeTag) bool {
    return self.next_token.type.is(token_type_tag);
}
