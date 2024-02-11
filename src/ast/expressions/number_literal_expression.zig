const std = @import("std");
const Self = @This();

value: NumberLiteralValue = undefined,

pub const NumberLiteralValue = union(enum) {
    int: i32,
    float: f32,

    pub fn format(self: NumberLiteralValue, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        switch (self) {
            .int => |value| try std.fmt.format(writer, "{d}", .{value}),
            .float => |value| try std.fmt.format(writer, "{d:.2}", .{value}),
        }
    }
};

pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;
    try std.fmt.format(writer, "{}", .{self.value});
}
