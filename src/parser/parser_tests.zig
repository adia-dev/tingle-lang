const std = @import("std");
const ast = @import("../ast/ast.zig");
const Token = @import("../token/token.zig");
const Lexer = @import("../lexer/lexer.zig");
const Parser = @import("parser.zig");
const ParserError = @import("parser_error.zig");

const TokenType = Token.TokenType;
const Expressions = ast.Expressions;
const Statements = ast.Statements;

const StatementTag = Statements.StatementTag;
const Statement = Statements.Statement;

const ExpressionTag = Expressions.ExpressionTag;
const Identifier = Expressions.Identifier;

const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const AutoHashMap = std.AutoHashMap;
const testing = std.testing;

const Keyword = Token.Keyword;

fn assert_identifier(identifier: *Identifier, expected_name: []const u8) !void {
    try testing.expect(identifier.token.type.is(.identifier));
    try testing.expectEqualStrings(expected_name, identifier.token.type.identifier);
    try testing.expectEqualStrings(expected_name, identifier.value);
}

fn assert_let_statement(stmt: *Statement, expected_name: []const u8) !void {
    switch (stmt.*) {
        .let => |let_stmt| {
            if (let_stmt) |let| {
                if (let.token.type.is(.keyword)) {
                    try testing.expectEqual(.let, let.token.type.keyword);
                    try testing.expectEqualStrings("let", let.token.lexeme);
                    try assert_identifier(&let.identifier, expected_name);

                    return;
                }
            }
        },
        else => {},
    }
    return error.InvalidStatement;
}

fn assert_return_statement(stmt: *Statement) !void {
    switch (stmt.*) {
        .@"return" => |return_stmt| {
            if (return_stmt) |let| {
                if (let.token.type.is(.keyword)) {
                    try testing.expectEqual(.@"return", let.token.type.keyword);
                    try testing.expectEqualStrings("return", let.token.lexeme);

                    return;
                }
            }
        },
        else => {},
    }
    return error.InvalidStatement;
}

fn assert_expression_statement(stmt: *Statement, expected_expression_tag: ExpressionTag) !void {
    switch (stmt.*) {
        .expression_statement => |expression_statement| {
            if (expression_statement) |expr_stmt| {
                try testing.expectEqual(@intFromEnum(expected_expression_tag), @intFromEnum(@as(ExpressionTag, expr_stmt.expression)));
                return;
            }
        },
        else => {},
    }
    return error.InvalidStatement;
}

test "Parser - Parse let statements" {
    const ta = testing.allocator;
    const source_code: []const u8 =
        \\ let x = 5;
        \\ let name = "Abdoulaye Dia";
        \\ let foobar = 3.14;
    ;

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    var parser = try Parser.init(ta, &lexer);
    defer parser.deinit();

    var program = try parser.parse();
    defer program.deinit();

    try testing.expectEqual(3, program.statements.items.len);

    var expected = ArrayList([]const u8).init(ta);
    defer expected.deinit();

    try expected.append("x");
    try expected.append("name");
    try expected.append("foobar");

    for (expected.items, 0..) |e, i| {
        var stmt = program.statements.items[i];
        try assert_let_statement(&stmt, e);
    }
}

test "Parser - Parse let statements - Unexpected Token" {
    const ta = testing.allocator;
    const source_code: []const u8 =
        \\ let x 5;
    ;

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    var parser = try Parser.init(ta, &lexer);
    defer parser.deinit();

    try testing.expectError(error.UnexpectedToken, parser.parse());
}

test "Parser - Parse return statements" {
    const ta = testing.allocator;
    const source_code: []const u8 =
        \\ return true;
        \\ return;
        \\ return 1 / 2;
    ;

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    var parser = try Parser.init(ta, &lexer);
    defer parser.deinit();

    var program = try parser.parse();
    defer program.deinit();

    try testing.expectEqual(3, program.statements.items.len);

    var expected = ArrayList([]const u8).init(ta);
    defer expected.deinit();

    try expected.append("");
    try expected.append("");
    try expected.append("");

    for (expected.items, 0..) |_, i| {
        var stmt = program.statements.items[i];
        try assert_return_statement(&stmt);
    }
}

test "Parser - Parse return statements - Unexpected Eof" {
    const ta = testing.allocator;
    const source_code: []const u8 =
        \\ return 
    ;

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    var parser = try Parser.init(ta, &lexer);
    defer parser.deinit();

    try testing.expectError(error.UnexpectedEof, parser.parse());
}

test "Parser - Parse identifier expressions" {
    const ta = testing.allocator;
    const source_code: []const u8 =
        \\ foobar; 
        \\ foo; 
        \\ bar; 
    ;

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    var parser = try Parser.init(ta, &lexer);
    defer parser.deinit();

    var program = try parser.parse();
    defer program.deinit();

    try testing.expectEqual(3, program.statements.items.len);

    var expected = ArrayList([]const u8).init(ta);
    defer expected.deinit();

    try expected.append("foobar");
    try expected.append("foo");
    try expected.append("bar");

    for (expected.items, 0..) |_, i| {
        var stmt = program.statements.items[i];
        try assert_expression_statement(&stmt, .identifier);
    }
}

test "Parser - Parse number literal expressions" {
    const ta = testing.allocator;
    const source_code: []const u8 =
        \\ 5; 
        \\ 3.14; 
        \\ 10_000_000; 
    ;

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    var parser = try Parser.init(ta, &lexer);
    defer parser.deinit();

    var program = try parser.parse();
    defer program.deinit();

    try testing.expectEqual(3, program.statements.items.len);

    var expected = ArrayList(i32).init(ta);
    defer expected.deinit();

    try expected.append(5);
    try expected.append(3);
    try expected.append(10_000_000);

    for (expected.items, 0..) |e, i| {
        var stmt = program.statements.items[i];
        try assert_expression_statement(&stmt, .literal);
        try testing.expectEqual(e, stmt.expression_statement.?.expression.literal.?.number.value);
    }
}
