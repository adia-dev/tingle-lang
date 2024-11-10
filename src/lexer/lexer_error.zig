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

pub const PathLines = enum {
    /// ─ (U+2500): Horizontal
    horizontal,
    /// │ (U+2502): Vertical
    vertical,
    /// ┌ (U+250C): Corner top left
    corner_top_left,
    /// ┐ (U+2510): Corner top right
    corner_top_right,
    /// └ (U+2514): Corner bottom left
    corner_bottom_left,
    /// ┘ (U+2518): Corner bottom right
    corner_bottom_right,
    /// ├ (U+251C): Tee pointing right
    tee_right,
    /// ┤ (U+2524): Tee pointing left
    tee_left,
    /// ┴ (U+2534): Tee pointing up
    tee_up,
    /// ┬ (U+252C): Tee pointing down
    tee_down,
    /// ┼ (U+253C): Cross
    cross,

    pub fn to_string(self: PathLines) []const u8 {
        return switch (self) {
            .horizontal => "─",
            .vertical => "│",
            .corner_top_left => "┌",
            .corner_top_right => "┐",
            .corner_bottom_left => "└",
            .corner_bottom_right => "┘",
            .tee_right => "├",
            .tee_left => "┤",
            .tee_up => "┴",
            .tee_down => "┬",
            .cross => "┼",
        };
    }

    pub fn format(self: PathLines, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options; // autofix
        _ = fmt; // autofix
        try std.fmt.format(writer, "{s}", .{self.to_string()});
    }
};

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

        const allocator = std.heap.page_allocator;

        const formatter = ErrorFormatter{ .writer = writer };
        const line_nbr = self.lexer.line;
        const col_nbr = self.lexer.position - self.lexer.start_line_position;
        const path = "src/main.zig";
        const anchor_line_nbr = self.lexer.anchor_line;
        const lexeme = try std.fmt.allocPrint(allocator, "{s}", .{self.lexer.current_token.lexeme});
        defer allocator.free(lexeme);

        try std.fmt.format(writer, chroma.format("{red,bold}error[E{d:0>5}]{reset}: "), .{@intFromEnum(self.code)});

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
                if (self.lexer.get_line(anchor_line_nbr)) |line| {
                    var last_line_len: usize = 0;

                    try formatter.write("Character is too long '{s}' at {d}:{d}.\n", .{ payload.char, line_nbr + 1, col_nbr });
                    try formatter.trace(path, line_nbr + 1, col_nbr);
                    try formatter.vertical_line();

                    var char_start: usize = 0;
                    while (char_start < line.len and line[char_start] != '\'') : (char_start += 1) {}

                    var char_end: usize = char_start + 1;
                    while (char_end < line.len and line[char_end] != '\'') : (char_end += 1) {}

                    const char_len = char_end - char_start;

                    try formatter.vertical_line_with_number(anchor_line_nbr + 1, false);
                    try formatter.pad(char_start);
                    try formatter.write(chroma.format("{241}{s}{red}{s}\n"), .{ line[char_start..(char_start + 2)], line[char_start + 2 .. char_end + 1] });

                    try formatter.inline_vertical_line();
                    for (0..char_end + 1) |i| {
                        if (i > char_start + 1 and i < char_start + char_len) {
                            try formatter.write(chroma.format("{red}^"), .{});
                        } else {
                            try formatter.pad(1);
                        }
                    }

                    last_line_len = line.len - 1;

                    try formatter.ln();
                    try formatter.write(chroma.format("{green,bold}help{reset}: maybe you meant to write a `{magenta,italic,underline}string{reset}` at {blue,italic,underline}{s}:{d}:{d}\n"), .{ path, line_nbr + 1, col_nbr });
                    try formatter.vertical_line();

                    try formatter.vertical_line_with_number(anchor_line_nbr + 1, false);
                    try formatter.pad(char_start);
                    try formatter.write(chroma.format("{green}\"{s}\"{241}\n"), .{line[(char_start + 1)..(char_end)]});
                    try formatter.vertical_line();
                }
            },
            .overflowing_literal => |payload| {
                _ = payload; // autofix
            },
            .unexpected_end_of_file => {
                try std.fmt.format(writer, "Unexpected eof at {d}:{d}\n", .{ self.lexer.line, self.lexer.position + 1 });
            },
            .unmatched_delimiter => |payload| {
                var diagnostics = std.AutoHashMap(usize, []const ErrorFormatter.LineDiagnostic).init(allocator);
                defer diagnostics.deinit();

                try formatter.write(chroma.format("Unmatched delimiter, expected: `{241}{s}{reset}`, got: `{241}{s}{reset}`\n"), .{ payload.expected_delimiter, lexeme });
                try formatter.trace(path, line_nbr, col_nbr);
                try formatter.vertical_line();

                var buf: [1024]u8 = undefined;
                var message: []u8 = undefined;
                message = try std.fmt.bufPrint(buf[0..], chroma.format("{red}Unclosed delimiter"), .{});

                try diagnostics.put(
                    line_nbr,
                    &.{
                        .{
                            .line = line_nbr,
                            .col = col_nbr,
                            .message = message,
                            .underline = chroma.format("{red}^"),
                        },
                    },
                );

                if (self.lexer.get_lines(anchor_line_nbr - 1, null)) |lines| {
                    try formatter.code_block(anchor_line_nbr, lines, &diagnostics);
                }

                try formatter.vertical_line();
            },
            .unsupported_character_encoding => |payload| {
                _ = payload; // autofix
            },
        }

        // try std.fmt.format(writer, chroma.format("\n{red}tingle-lang{reset}: Program could not compile due to previous errors\n"), .{});
    }
};

const ErrorFormatter = struct {
    writer: std.io.AnyWriter,
    padding: usize = 4,
    max_lines_to_display: usize = 10,
    skipped_lines_to_display: usize = 3,

    pub fn init(writer: std.io.AnyWriter) ErrorFormatter {
        return .{
            .writer = writer,
        };
    }

    pub const LineDiagnostic = struct {
        line: usize = 0,
        col: usize = 0,
        anchor: ?[]const u8 = null,
        message: ?[]const u8 = null,
        underline: ?[]const u8 = null,

        pub fn write(self: LineDiagnostic, formatter: ErrorFormatter) !void {
            try formatter.inline_vertical_line();
            try formatter.pad(self.col);
            if (self.underline) |underline| {
                try formatter.write_many("{s}", 1, .{underline});
            }
            if (self.message) |message| {
                try formatter.write(" {s}", .{message});
            }
            try formatter.ln();
        }
    };

    pub const CodeBlockOptions = struct {
        borders: bool = false,
        border_style: enum { fancy, default } = .fancy,
        from: ?struct { line: usize = 0, col: usize = 0 } = .{ .line = 0, .col = 0 },
        to: ?struct { line: usize = 0, col: usize = 0 },
    };

    pub fn ln(self: ErrorFormatter) !void {
        try std.fmt.format(self.writer, "\n", .{});
    }

    pub fn write(self: ErrorFormatter, comptime fmt: []const u8, args: anytype) !void {
        try std.fmt.format(self.writer, fmt, args);
    }

    pub fn write_many(self: ErrorFormatter, comptime fmt: []const u8, count: usize, args: anytype) !void {
        for (0..count) |_| {
            try std.fmt.format(self.writer, fmt, args);
        }
    }

    pub fn trace(self: ErrorFormatter, path: []const u8, line: usize, column: usize) !void {
        try std.fmt.format(self.writer, chroma.format("{blue} → {s}:{d}:{d}\n"), .{ path, line, column });
    }

    pub fn vertical_line(self: ErrorFormatter) !void {
        try std.fmt.format(self.writer, chroma.format("{blue}{s: >5} \n"), .{PathLines.vertical.to_string()});
    }

    pub fn inline_vertical_line(self: ErrorFormatter) !void {
        try std.fmt.format(self.writer, chroma.format("{blue}{s: >5} "), .{PathLines.vertical.to_string()});
    }

    pub fn vertical_line_with_number(self: ErrorFormatter, number: anytype, new_line: bool) !void {
        try std.fmt.format(self.writer, chroma.format("{blue}{d: <4}│ {s}"), .{ number, if (new_line) "\n" else "" });
    }

    pub fn vertical_line_with_label(self: ErrorFormatter, label: []const u8, new_line: bool) !void {
        try std.fmt.format(self.writer, chroma.format("{blue}{s: <4}│ {s}"), .{ label, if (new_line) "\n" else "" });
    }

    pub fn pad(self: ErrorFormatter, count: usize) !void {
        for (0..count) |_| {
            try std.fmt.format(self.writer, " ", .{});
        }
    }

    pub fn code_block(self: ErrorFormatter, start_line: usize, lines: [][]const u8, diagnostics: *std.AutoHashMap(usize, []const LineDiagnostic)) !void {
        const should_skip_content = lines.len >= self.max_lines_to_display;
        for (lines, 0..) |line, i| {
            if (should_skip_content and i >= self.skipped_lines_to_display) {
                break;
            }
            try self.vertical_line_with_number(start_line + i, false);
            try self.write(chroma.format("{241}{s}\n"), .{line});
            if (diagnostics.get(start_line + i)) |line_diagnostics| {
                for (line_diagnostics) |*diagnostic| {
                    try diagnostic.write(self);
                }
                _ = diagnostics.remove(start_line + i);
            }
        }

        if (should_skip_content) {
            try self.write(chroma.format("{blue}... │\n"), .{});
            for (lines[lines.len - self.skipped_lines_to_display ..], 0..) |line, i| {
                try self.vertical_line_with_number(start_line + lines.len - self.skipped_lines_to_display + i, false);
                try self.write(chroma.format("{241}{s}\n"), .{line});
                if (diagnostics.get(start_line + lines.len - self.skipped_lines_to_display + i)) |line_diagnostics| {
                    for (line_diagnostics) |*diagnostic| {
                        try diagnostic.write(self);
                    }
                    _ = diagnostics.remove(start_line + lines.len - self.skipped_lines_to_display + i);
                }
            }
        }

        var it = diagnostics.valueIterator();
        while (it.next()) |line_diagnostics| {
            for (line_diagnostics.*) |diagnostic| {
                try diagnostic.write(self);
            }
        }
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
