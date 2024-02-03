const std = @import("std");

pub const Program = @import("program.zig");
pub const LetStatement = @import("let_statement.zig");
pub const ExpressionStatement = @import("expression_statement.zig");

pub const Statement = union(enum) {
    program: ?*Program,
    let: ?*LetStatement,
    expression_statement: ?*ExpressionStatement,

    pub fn format(self: Statement, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        switch (self) {
            inline else => |statement| {
                if (statement) |stmt| {
                    try stmt.format(fmt, options, writer);
                }
            },
        }
    }
};
