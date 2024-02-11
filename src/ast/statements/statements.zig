const std = @import("std");

pub const Program = @import("program.zig");
pub const LetStatement = @import("let_statement.zig");
pub const ExpressionStatement = @import("expression_statement.zig");
pub const ReturnStatement = @import("return_statement.zig");

pub const StatementTag = enum {
    program,
    let,
    @"return",
    expression_statement,
};

pub const Statement = union(StatementTag) {
    program: ?*Program,
    let: ?*LetStatement,
    @"return": ?*ReturnStatement,
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

    pub fn downcast(self: Statement, comptime T: type) ?*T {
        inline for (@typeInfo(Statement).Union.fields) |field| {
            if (field.type == ?*T) {
                return @field(self, field.name);
            }
        }
        return null;
    }
};
