const std = @import("std");
const Token = @import("../token/token.zig");
const Lexer = @import("../lexer/lexer.zig");
const chroma = @import("chroma");

// ─ (U+2500): Horizontal
// │ (U+2502): Vertical
// ┌ (U+250C): Corner top left
// ┐ (U+2510): Corner top right
// └ (U+2514): Corner bottom left
// ┘ (U+2518): Corner bottom right
// ├ (U+251C): Tee pointing right
// ┤ (U+2524): Tee pointing left
// ┴ (U+2534): Tee pointing up
// ┬ (U+252C): Tee pointing down
// ┼ (U+253C): Cross

pub const LexerErrorCodeTag = enum(u16) {
    illegal_character = 1_000,
    invalid_escaped_sequence,
    invalid_number_format,
    invalid_char_size,
    overflowing_literal,
    unexpected_end_of_file,
    unmatched_delimiter,
    unsupported_character_encoding,
};

pub const LexerErrorCode = union(LexerErrorCodeTag) {
    illegal_character: struct { char: u21 },
    invalid_escaped_sequence: struct { sequence: []const u8 },
    invalid_number_format: struct { number: []const u8 },
    invalid_char_size: struct { char: []const u8 },
    overflowing_literal: struct { literal: []const u8 },
    unexpected_end_of_file,
    unmatched_delimiter: struct { expected_delimiter: []const u8 },
    /// Example Output:
    /// error[[E01006]]: Unmatched delimiter, expected to find `"`.
    ///   → src/main.zig:16:7
    /// 14 ┌ "How about very
    /// 15 │ very very very
    /// 16 │ very very very
    /// ...│
    /// 25 │ long multi line
    /// 26 │ strings`"`
    ///    │        ┬
    ///    └────────┘
    /// help: try inserting a `"` at src/main.zig:16:7
    unsupported_character_encoding: struct { char: u8 },
};

pub const LexerError = struct {
    @"error": anyerror,
    from: ?*LexerError = null,
    code: LexerErrorCode,
    lexer: *Lexer,

    pub fn err(self: LexerError) !void {
        return self.@"error";
    }

    pub fn format(self: LexerError, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        _ = fmt;

        const formatter = ErrorFormatter{ .writer = writer };
        const line_nbr = self.lexer.line;
        const col_nbr = self.lexer.position - self.lexer.start_line_position;

        try std.fmt.format(writer, chroma.format("{red}error[E{d:0>5}]{reset}: "), .{@intFromEnum(self.code)});

        switch (self.code) {
            .illegal_character => |payload| {
                try std.fmt.format(writer, "Illegal token found `{u}` at {d}:{d}.\n", .{ payload.char, self.lexer.line, self.lexer.position + 1 });
            },
            .invalid_escaped_sequence => |payload| {
                try std.fmt.format(writer, "Invalid escaped sequence found: `{s}` at {d}:{d}.\n", .{ payload.sequence, self.lexer.line, self.lexer.position + 1 });
            },
            .invalid_number_format => |payload| {
                try std.fmt.format(writer, "Invalid number format found: `{s}` at {d}:{d}.\n", .{ payload.number, self.lexer.line, self.lexer.position + 1 });
            },
            .invalid_char_size => |payload| {
                try std.fmt.format(writer, "Character is too long '{s}' at {d}:{d}.\n", .{ payload.char, self.lexer.line, self.lexer.position + 1 });
            },
            .overflowing_literal => |payload| {
                _ = payload; // autofix
            },
            .unexpected_end_of_file => {
                try std.fmt.format(writer, "Unexpected eof at {d}:{d}\n", .{ self.lexer.line, self.lexer.position + 1 });
            },
            .unmatched_delimiter => |payload| {
                const path = "src/main.zig";
                const anchor_line_nbr = self.lexer.anchor_line;
                const distance = line_nbr - anchor_line_nbr;
                // this is the threshold to reach before showing ellipsis
                const max_lines_to_display = 3;
                var last_line_len: usize = 0;

                try formatter.text(chroma.format("Unmatched delimiter, expected to find `{241}{s}{reset}`.\n"), .{payload.expected_delimiter});
                try formatter.trace(path, line_nbr + 1, col_nbr);
                try formatter.vertical_line();
                try formatter.inline_vertical_line();

                if (self.lexer.get_line(anchor_line_nbr)) |line| {
                    if (distance <= 1) {
                        try formatter.text(chroma.format("{green}┌{241}{s}{green}{s}\n"), .{ line, payload.expected_delimiter });
                        last_line_len = line.len - 1;
                    } else {
                        try formatter.text(chroma.format("{green}┌{241}{s}\n"), .{line});
                    }
                }

                const from = anchor_line_nbr + 1;
                const to = @min(anchor_line_nbr + max_lines_to_display, line_nbr + 1);
                for (from..to) |i| {
                    if (self.lexer.get_line(i)) |line| {
                        try formatter.vertical_line_with_number(anchor_line_nbr + i + 1, false);
                        try formatter.text(chroma.format("{green}│"), .{});
                        // + 1 because we start counting lines at 0                       ^^^^^

                        if (distance < max_lines_to_display and i == to - 1) {
                            try formatter.text(chroma.format("{241} {s}{green}{s}\n"), .{ line, payload.expected_delimiter });
                        } else {
                            try formatter.text(chroma.format("{241} {s}\n"), .{line});
                        }
                        if (line.len > 0) {
                            last_line_len = line.len;
                        }
                    }
                }

                if (distance > max_lines_to_display) {
                    try formatter.vertical_line_with_label("...", false);
                    try formatter.text(chroma.format("{green}│\n"), .{});

                    for ((line_nbr - max_lines_to_display)..line_nbr) |i| {
                        if (self.lexer.get_line(i)) |line| {
                            // + 1 because we start counting lines at 0
                            try formatter.vertical_line_with_number(anchor_line_nbr + i + 1, false);
                            try formatter.text(chroma.format("{green}│"), .{});
                            if (i == line_nbr - 1) {
                                try formatter.text(chroma.format("{241} {s}{green}{s}\n"), .{ line, payload.expected_delimiter });
                            } else {
                                try formatter.text(chroma.format("{241} {s}\n"), .{line});
                            }
                            if (line.len > 0) {
                                last_line_len = line.len;
                            }
                        }
                    }
                }

                try formatter.inline_vertical_line();
                try formatter.text(chroma.format("{green}│"), .{});
                for (0..last_line_len + 1) |_| {
                    try formatter.text(chroma.format(" "), .{});
                }
                try formatter.text(chroma.format("{green}┬\n"), .{});
                try formatter.inline_vertical_line();
                try formatter.text(chroma.format("{green}└"), .{});
                for (0..last_line_len + 1) |_| {
                    try formatter.text(chroma.format("{green}─"), .{});
                }
                try formatter.text(chroma.format("{green}┘"), .{});
                try formatter.text("\n", .{});

                try formatter.text(chroma.format("{green}help{reset}: try inserting a `{green}{s}{reset}` at {blue}{s}:{d}:{d}\n"), .{ payload.expected_delimiter, path, line_nbr + 1, col_nbr });
                try formatter.empty();
            },
            .unsupported_character_encoding => |payload| {
                _ = payload; // autofix
            },
        }

        try std.fmt.format(writer, chroma.format("\n{red}tingle-lang{reset}: Program could not compile due to previous errors\n"), .{});
    }
};

const ErrorFormatter = struct {
    writer: std.io.AnyWriter,
    padding: usize = 4,

    pub fn init(writer: std.io.AnyWriter) ErrorFormatter {
        return .{
            .writer = writer,
        };
    }

    pub fn empty(self: ErrorFormatter) !void {
        try std.fmt.format(self.writer, "\n", .{});
    }

    pub fn text(self: ErrorFormatter, comptime fmt: []const u8, args: anytype) !void {
        try std.fmt.format(self.writer, fmt, args);
    }

    pub fn trace(self: ErrorFormatter, path: []const u8, line: usize, column: usize) !void {
        try std.fmt.format(self.writer, chroma.format("{blue} → {s}:{d}:{d}\n"), .{ path, line, column });
    }

    pub fn vertical_line(self: ErrorFormatter) !void {
        try std.fmt.format(self.writer, chroma.format("{blue}{s: >5} \n"), .{"│"});
    }

    pub fn inline_vertical_line(self: ErrorFormatter) !void {
        try std.fmt.format(self.writer, chroma.format("{blue}{s: >5} "), .{"│"});
    }

    pub fn vertical_line_with_number(self: ErrorFormatter, number: anytype, new_line: bool) !void {
        try std.fmt.format(self.writer, chroma.format("{blue}{d: <4}│ {s}"), .{ number, if (new_line) "\n" else "" });
    }

    pub fn vertical_line_with_label(self: ErrorFormatter, label: []const u8, new_line: bool) !void {
        try std.fmt.format(self.writer, chroma.format("{blue}{s: <4}│ {s}"), .{ label, if (new_line) "\n" else "" });
    }

    // // Formats the error header.
    // pub fn header(self: ErrorFormatter, code: LexerErrorCode) void {
    // self.writer.print(chroma.format("{red}error[{d}]: {reset}"), .{code}).catch unreachable;
    // }

    // // Formats a snippet of code with an indicator.
    // pub fn codeSnippet(self: ErrorFormatter, lineContent: []const u8, position: usize, indicator: []const u8) void {
    // self.writer.print("{s}\n{s: >{}}{s}\n", .{lineContent, position + 1, indicator}).catch unreachable;
    // }

    // // Formats a suggestion for fixing the error.
    // pub fn suggestion(self: ErrorFormatter, message: []const u8, path: []const u8, line: usize, position: usize) void {
    // self.writer.print(chroma.format("{blue}help: {s} at {s}:{d}:{d}\n"), .{message, path, line, position}).catch unreachable;
    // }

    // // Formats the error footer.
    // pub fn footer(self: ErrorFormatter) void {
    // self.writer.print(chroma.format("{red}tingle-lang: Program could not compile due to previous errors\n{reset}"), .{}).catch unreachable;
    // }
};
