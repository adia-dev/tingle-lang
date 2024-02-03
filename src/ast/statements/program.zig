const std = @import("std");
const ArrayList = std.ArrayList;
const Self = @This();
const Token = @import("../../token/token.zig");
const Expression = @import("../expressions/expressions.zig").Expression;
const Statement = @import("statements.zig").Statement;

statements: ArrayList(Statement),

pub fn init(allocator: std.mem.Allocator) Self {
    const statements = ArrayList(Statement).init(allocator);
    return .{ .statements = statements };
}

pub fn deinit(self: *Self) void {
    self.statements.deinit();
}

pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;
    for (self.statements.items) |statement| {
        try std.fmt.format(writer, "{}\n", .{statement});
    }
}
