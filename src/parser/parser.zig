const std = @import("std");
const ast = @import("../ast/ast.zig");
const Token = @import("../token/token.zig");
const Lexer = @import("../lexer/lexer.zig");
const TokenType = Token.TokenType;
const TokenTypeTag = Token.TokenTypeTag;
const ParserError = @import("parser_error.zig").ParserError;

const Precedence = @import("precedence.zig").Precedence;

const Expressions = ast.Expressions;
const Expression = Expressions.Expression;
const IdentifierExpression = Expressions.IdentifierExpression;
const NumberLiteralExpression = Expressions.NumberLiteralExpression;
const UnaryExpression = Expressions.UnaryExpression;

const Statements = ast.Statements;
const Statement = Statements.Statement;
const Program = Statements.Program;
const LetStatement = Statements.LetStatement;
const ReturnStatement = Statements.ReturnStatement;
const ExpressionStatement = Statements.ExpressionStatement;

const Self = @This();
const UnaryFn = *const fn (self: *Self) anyerror!Expression;
const BinaryFn = *const fn (self: *Self) anyerror!Expression;

lexer: *Lexer,
current_token: Token = undefined,
next_token: Token = undefined,
arena: std.heap.ArenaAllocator,

// parser functions
unary_fns: std.AutoHashMap(TokenTypeTag, UnaryFn) = undefined,
binary_fns: std.AutoHashMap(TokenTypeTag, BinaryFn) = undefined,

pub fn init(allocator: std.mem.Allocator, lexer: *Lexer) !Self {
    var parser = Self{ .arena = std.heap.ArenaAllocator.init(allocator), .lexer = lexer };

    parser.unary_fns = std.AutoHashMap(TokenTypeTag, UnaryFn).init(allocator);
    parser.binary_fns = std.AutoHashMap(TokenTypeTag, BinaryFn).init(allocator);

    try parser.init_unary_fns();
    try parser.init_binary_fns();

    try parser.advance();
    try parser.advance();

    return parser;
}

fn init_unary_fns(self: *Self) !void {
    try self.unary_fns.put(.identifier, Self.parse_identifier);
    try self.unary_fns.put(.number, Self.parse_number_literal);

    try self.unary_fns.put(.not, Self.parse_unary_expression);
    try self.unary_fns.put(.minus, Self.parse_unary_expression);
    try self.unary_fns.put(.minusminus, Self.parse_unary_expression);
    try self.unary_fns.put(.plusplus, Self.parse_unary_expression);
}

fn init_binary_fns(self: *Self) !void {
    _ = self;
}

pub fn deinit(self: *Self) void {
    defer self.arena.deinit();
    self.unary_fns.deinit();
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

fn parse_expression(self: *Self, precedence: Precedence) !?Expression {
    _ = precedence; // autofix

    if (self.unary_fns.get(self.current_token.type)) |unary_fn| {
        const left_exp = try unary_fn(self);
        return left_exp;
    } else {
        return null;
    }
}

fn parse_unary_expression(self: *Self) !Expression {
    var unary_expr = try self.arena.allocator().create(UnaryExpression);
    unary_expr.* = .{ .operator = self.current_token };

    try self.advance();

    if (try self.parse_expression(.unary)) |expression| {
        unary_expr.expression = expression;
    }

    return Expression{ .unary = unary_expr };
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
        else => return try self.parse_expression_statement(),
    }
}

fn parse_expression_statement(self: *Self) !Statement {
    var expr_stmt = try self.arena.allocator().create(ExpressionStatement);
    const current_token = self.current_token;

    expr_stmt.* = .{};
    expr_stmt.token = current_token;

    if (try self.parse_expression(.lowest)) |expression| {
        expr_stmt.expression = expression;
    }

    if (self.next_token_is(.semi)) {
        try self.advance();
    }

    return Statement{ .expression_statement = expr_stmt };
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
    stmt.identifier = IdentifierExpression{ .token = self.current_token, .value = self.current_token.lexeme };

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

fn parse_identifier(self: *Self) !Expression {
    var expr = try self.arena.allocator().create(IdentifierExpression);
    expr.* = .{};
    expr.token = self.current_token;
    expr.value = self.current_token.type.identifier;

    return Expression{ .identifier = expr };
}

fn parse_number_literal(self: *Self) !Expression {
    const expr = try self.arena.allocator().create(NumberLiteralExpression);
    expr.* = .{};

    expr.value = switch (self.current_token.type.number.type) {
        .int => .{ .int = try std.fmt.parseInt(i32, self.current_token.type.number.literal, 10) },
        .float => .{ .float = try std.fmt.parseFloat(f32, self.current_token.type.number.literal) },
    };

    return Expression{ .number = expr };
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
