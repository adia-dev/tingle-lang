const std = @import("std");

pub const AnsiColor = struct {
    pub const RESET: *const [4:0]u8 = "\x1b[0m";

    pub const AnsiColorCode = enum {
        reset,
        black,
        red,
        green,
        yellow,
        blue,
        magenta,
        cyan,
        white,
        gray,
        bright_black,
        bright_red,
        bright_green,
        bright_yellow,
        bright_blue,
        bright_magenta,
        bright_cyan,
        bright_white,

        pub fn to_string(comptime code: AnsiColorCode) []const u8 {
            return switch (code) {
                .black => "\x1b[30m",
                .red => "\x1b[31m",
                .green => "\x1b[32m",
                .yellow => "\x1b[33m",
                .blue => "\x1b[34m",
                .magenta => "\x1b[35m",
                .cyan => "\x1b[36m",
                .white => "\x1b[37m",
                .gray => "\x1b[90m",
                .bright_black => "\x1b[90m",
                .bright_red => "\x1b[91m",
                .bright_green => "\x1b[92m",
                .bright_yellow => "\x1b[93m",
                .bright_blue => "\x1b[94m",
                .bright_magenta => "\x1b[95m",
                .bright_cyan => "\x1b[96m",
                .bright_white => "\x1b[97m",
                else => "",
            };
        }
    };

    pub fn format(comptime color: AnsiColorCode, comptime base_format: []const u8) []const u8 {
        return comptime color.to_string() ++ base_format ++ RESET;
    }
};
