const std = @import("std");
const Lexer = @import("lexer/lexer.zig");
const Token = @import("token/token.zig");
const Logger = @import("core/logger.zig");
const TokenType = Token.TokenType;

const source_files = [_][]const u8{ "main.tl", "punctuation.tl", "token.tl", "strings.tl" };

pub const std_options = struct {
    pub const log_level = .debug;
    pub const logFn = Logger.log;
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    const source_code = @embedFile("examples/" ++ source_files[3]);
    var lexer = Lexer.init(arena.allocator(), source_code) catch |err| {
        std.debug.print("Failed to initialize the lexer: {}", .{err});
        return;
    };

    var token = try lexer.scan();

    while (true) {
        if (token.type == .eof or token.type == .illegal) {
            std.log.err("Error {}", .{token});
            token = try lexer.scan();
            if (token.type == .eof)
                break;
            continue;
        }
        std.log.debug("{}", .{token});
        token = try lexer.scan();
    }
}
