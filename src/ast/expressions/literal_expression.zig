const std = @import("std");
const Expression = @import("expressions.zig").Expression;
const Token = @import("../../token/token.zig");

pub const LiteralExpression = union(enum) {
    boolean: BooleanLiteralExpression,
    string: StringLiteralExpression,
    byte: ByteLiteralExpression,
    number: NumberLiteralExpression,

    pub fn format(self: LiteralExpression, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        switch (self) {
            inline else => |literal| {
                try literal.format(fmt, options, writer);
            },
        }
    }
};

pub const BooleanLiteralExpression = struct {
    value: bool,

    pub fn format(self: BooleanLiteralExpression, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer, "{s}", .{if (self.value) "true" else "false"});
    }
};

pub const StringLiteralExpression = struct {
    value: []const u8,

    pub fn format(self: StringLiteralExpression, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer, "{s}", .{self.value});
    }
};

pub const NumberLiteralExpression = struct {
    value: i32,

    pub fn format(self: NumberLiteralExpression, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer, "{d}", .{self.value});
    }
};

pub const ByteLiteralExpression = struct {
    value: u8,

    pub fn format(self: ByteLiteralExpression, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer, "{d}", .{self.value});
    }
};
