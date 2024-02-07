const std = @import("std");
const ast = @import("../ast/ast.zig");
const Token = @import("../token/token.zig");
const Lexer = @import("../lexer/lexer.zig");
const Parser = @import("parser.zig");
const ParserError = @import("parser_error.zig");

const TokenType = Token.TokenType;
const Expressions = ast.Expressions;
const Statements = ast.Statements;

const Statement = Statements.Statement;

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
