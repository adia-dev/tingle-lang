const std = @import("std");
const Token = @import("../token/token.zig");
const Lexer = @import("../lexer/lexer.zig");

pub const LexerErrorPayloadTag = enum(u16) {
    illegal_character = 1,
    invalid_escaped_sequence,
    invalid_number_format,
    invalid_char_size,
    overflowing_literal,
    unexpected_end_of_file,
    unmatched_delimiter,
    unsupported_character_encoding,
};

pub const LexerErrorPayload = union(LexerErrorPayloadTag) {
    illegal_character: struct { char: u21 },
    invalid_escaped_sequence: struct { sequence: []const u8 },
    invalid_number_format: struct { number: []const u8 },
    invalid_char_size: struct { char: []const u8 },
    overflowing_literal: struct { literal: []const u8 },
    unexpected_end_of_file,
    unmatched_delimiter: struct { expected_delimiter: []const u8 },
    unsupported_character_encoding: struct { char: u8 },
};

pub const LexerError = struct {
    @"error": anyerror,
    from: ?*LexerError = null,
    trace: LexerErrorPayload,
    lexer: *Lexer,

    pub fn err(self: LexerError) !void {
        return self.@"error";
    }

    pub fn format(self: LexerError, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer, "compile_error[{d:0>5}]: ", .{@intFromEnum(self.trace)});
        switch (self.trace) {
            .illegal_character => |payload| {
                try std.fmt.format(writer, "Illegal token found `{u}` at {d}:{d}.\n", .{ payload.char, self.lexer.current_token.?.line, self.lexer.current_token.?.col });
            },
            .invalid_escaped_sequence => |payload| {
                try std.fmt.format(writer, "Invalid escaped sequence found: `{s}` at {d}:{d}.\n", .{ payload.sequence, self.lexer.current_token.?.line, self.lexer.current_token.?.col });
            },
            .invalid_number_format => |payload| {
                try std.fmt.format(writer, "Invalid number format found: `{s}` at {d}:{d}.\n", .{ payload.number, self.lexer.current_token.?.line, self.lexer.current_token.?.col });
            },
            .invalid_char_size => |payload| {
                try std.fmt.format(writer, "Character is too long '{s}' at {d}:{d}.\n", .{ payload.char, self.lexer.current_token.?.line, self.lexer.current_token.?.col });
            },
            .overflowing_literal => |payload| {
                _ = payload; // autofix
            },
            .unexpected_end_of_file => {
                try std.fmt.format(writer, "Unexpected eof at {d}:{d}\n", .{ self.lexer.current_token.?.line, self.lexer.current_token.?.col });
            },
            .unmatched_delimiter => |payload| {
                try std.fmt.format(writer, "Unmatched delimiter encountered at {d}:{d}, expected: {s}.\n", .{ self.lexer.current_token.?.line, self.lexer.current_token.?.col, payload.expected_delimiter });
            },
            .unsupported_character_encoding => |payload| {
                _ = payload; // autofix
            },
        }
    }
};
