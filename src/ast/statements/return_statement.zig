const std = @import("std");
const Self = @This();
const Token = @import("../../token/token.zig");
const Expression = @import("../expressions/expressions.zig").Expression;

token: Token = undefined,
return_value: ?Expression = null,

pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;
    try std.fmt.format(writer, "return {?};", .{self.return_value});
}
