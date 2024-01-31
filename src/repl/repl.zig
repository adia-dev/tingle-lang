const std = @import("std");
const Lexer = @import("../lexer/lexer.zig");
const Logger = @import("../core/logger.zig");
const c = @cImport({
    @cInclude("readline/readline.h");
    @cInclude("readline/history.h");
    @cInclude("stdlib.h");
    @cInclude("memory.h");
});

const Self = @This();

i: usize = 1,
input: []const u8 = undefined,
c_input: [*c]u8 = undefined,
is_running: bool = true,
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) Self {
    return .{ .allocator = allocator };
}

pub fn deinit(self: *Self) void {
    _ = self;
}

pub fn start(self: *Self) !void {
    std.debug.print("\n", .{});
    while (self.is_running) {
        defer c.free(self.c_input);

        try self.read();
        try self.eval();
    }
}

pub fn read(self: *Self) !void {
    var prompt_buf: [1024]u8 = undefined;
    @memset(prompt_buf[0..], 0);
    _ = try std.fmt.bufPrint(prompt_buf[0..], "tingle({d})> ", .{self.i});

    self.c_input = c.readline(prompt_buf[0..]);
    self.input = std.mem.span(self.c_input);

    if (self.input.len > 0) {
        _ = c.add_history(self.c_input);
    }

    self.i += 1;
}

pub fn eval(self: *Self) !void {
    var lexer = try Lexer.init(self.allocator, self.input);

    while (true) {
        const token = lexer.scan() catch |err| {
            std.debug.print("A syntax error has been found: {}\n", .{err});
            break;
        };
        if (token.type == .eof or token.type == .illegal) {
            break;
        }
        std.debug.print("{}\n", .{token});
    }
}
