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
const ExpressionStatement = Statements.ExpressionStatement;

const ExpressionTag = Expressions.ExpressionTag;
const IdentifierExpression = Expressions.IdentifierExpression;
const NumberLiteralExpression = Expressions.NumberLiteralExpression;
const UnaryExpression = Expressions.UnaryExpression;
const BinaryExpression = Expressions.BinaryExpression;

const NumberLiteralValue = NumberLiteralExpression.NumberLiteralValue;

const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const AutoHashMap = std.AutoHashMap;
const testing = std.testing;

const Keyword = Token.Keyword;

fn assert_identifier_expression(identifier: *IdentifierExpression, expected_name: []const u8) !void {
    try testing.expect(identifier.token.type.is(.identifier));
    try testing.expectEqualStrings(expected_name, identifier.token.type.identifier);
    try testing.expectEqualStrings(expected_name, identifier.value);
}

fn assert_number_literal(number: *NumberLiteralExpression, expected_value: NumberLiteralValue) !void {
    try testing.expectEqual(number.value, expected_value);
}

fn assert_let_statement(stmt: *Statement, expected_name: []const u8) !void {
    switch (stmt.*) {
        .let => |let_stmt| {
            if (let_stmt) |let| {
                if (let.token.type.is(.keyword)) {
                    try testing.expectEqual(.let, let.token.type.keyword);
                    try testing.expectEqualStrings("let", let.token.lexeme);
                    try assert_identifier_expression(&let.identifier, expected_name);

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

    var expected = ArrayList(NumberLiteralValue).init(ta);
    defer expected.deinit();

    try expected.append(.{ .int = 5 });
    try expected.append(.{ .float = 3.14 });
    try expected.append(.{ .int = 10_000_000 });

    for (expected.items, 0..) |e, i| {
        var stmt = program.statements.items[i];
        try assert_expression_statement(&stmt, .number);
        if (stmt.downcast(ExpressionStatement)) |expr_stmt| {
            if (expr_stmt.expression.downcast(NumberLiteralExpression)) |number| {
                try assert_number_literal(number, e);
            }
        }
    }
}

test "Parser - NumberLiteralExpression - downcast" {
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

    var expected = ArrayList(NumberLiteralValue).init(ta);
    defer expected.deinit();

    try expected.append(.{ .int = 5 });
    try expected.append(.{ .float = 3.14 });
    try expected.append(.{ .int = 10_000_000 });

    for (expected.items, 0..) |e, i| {
        var stmt = program.statements.items[i];
        try assert_expression_statement(&stmt, .number);
        if (stmt.downcast(ExpressionStatement)) |expr_stmt| {
            if (expr_stmt.expression.downcast(NumberLiteralExpression)) |number| {
                try assert_number_literal(number, e);
            }
        }
    }
}

test "Parser - Parse UnaryExpression" {
    const ta = testing.allocator;
    const source_code: []const u8 =
        \\ !5; 
        \\ -3.14;
    ;

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    var parser = try Parser.init(ta, &lexer);
    defer parser.deinit();

    var program = try parser.parse();
    defer program.deinit();

    try testing.expectEqual(2, program.statements.items.len);

    var expected = ArrayList(struct { []const u8, []const u8, NumberLiteralValue }).init(ta);
    defer expected.deinit();

    try expected.append(.{ "!5", "!", .{ .int = 5 } });
    try expected.append(.{ "-3.14", "-", .{ .float = 3.14 } });

    for (expected.items, 0..) |e, i| {
        var stmt = program.statements.items[i];
        if (stmt.downcast(ExpressionStatement)) |expr_stmt| {
            if (expr_stmt.expression.downcast(UnaryExpression)) |unary| {
                try testing.expectEqualStrings(e[1], unary.operator.lexeme);
                if (unary.expression.downcast(NumberLiteralExpression)) |number| {
                    try assert_number_literal(number, e[2]);
                }
            }
        }
    }
}

test "Parser - Parse BinaryExpression" {
    const ta = testing.allocator;
    const source_code: []const u8 =
        \\ 3.14 + 3.14;
        \\ 10 * 2;
        \\ 5 - 5;
        \\ 5 * 5;
        \\ 5 ** 5;
        \\ 5 / 5;
        \\ 5 > 5;
        \\ 5 < 5;
        \\ 5 == 5;
        \\ 5 != 5;
    ;

    var lexer = try Lexer.init(ta, source_code);
    defer lexer.deinit();

    var parser = try Parser.init(ta, &lexer);
    defer parser.deinit();

    var program = try parser.parse();
    defer program.deinit();

    var expected = ArrayList(struct { NumberLiteralValue, []const u8, NumberLiteralValue }).init(ta);
    defer expected.deinit();

    try expected.append(.{ .{ .float = 3.14 }, "+", .{ .float = 3.14 } });
    try expected.append(.{ .{ .int = 10 }, "*", .{ .int = 2 } });
    try expected.append(.{ .{ .int = 5 }, "-", .{ .int = 5 } });
    try expected.append(.{ .{ .int = 5 }, "*", .{ .int = 5 } });
    try expected.append(.{ .{ .int = 5 }, "**", .{ .int = 5 } });
    try expected.append(.{ .{ .int = 5 }, "/", .{ .int = 5 } });
    try expected.append(.{ .{ .int = 5 }, ">", .{ .int = 5 } });
    try expected.append(.{ .{ .int = 5 }, "<", .{ .int = 5 } });
    try expected.append(.{ .{ .int = 5 }, "==", .{ .int = 5 } });
    try expected.append(.{ .{ .int = 5 }, "!=", .{ .int = 5 } });

    for (expected.items, 0..) |e, i| {
        var stmt = program.statements.items[i];
        if (stmt.downcast(ExpressionStatement)) |expr_stmt| {
            if (expr_stmt.expression.downcast(BinaryExpression)) |binary| {
                if (binary.left.downcast(NumberLiteralExpression)) |number| {
                    try assert_number_literal(number, e[0]);
                }

                try testing.expectEqualStrings(e[1], binary.operator.lexeme);

                if (binary.right.downcast(NumberLiteralExpression)) |number| {
                    try assert_number_literal(number, e[2]);
                }
            }
        }
    }
}
