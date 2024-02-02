const std = @import("std");

pub const Statement = union(enum) {
    pub fn format(self: Statement, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        switch (self) {
            inline else => |node| {
                try node.format(fmt, options, writer);
            },
        }
    }
};
