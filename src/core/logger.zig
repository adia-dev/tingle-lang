const std = @import("std");
const Time = @import("../time/time.zig").Time;
const Color = @import("../color/ansi.zig");

pub fn log(comptime level: std.log.Level, comptime scope: @Type(.EnumLiteral), comptime message: []const u8, args: anytype) void {
    _ = scope;

    const timestamp = std.time.timestamp();
    const time = Time.from_unix_timestamp(timestamp + @as(i64, 3600));

    std.debug.getStderrMutex().lock();
    defer std.debug.getStderrMutex().unlock();
    const stderr = std.io.getStdErr().writer();

    // TODO: search if it is possible to merge these into a single print call
    const formatted_timestamp = comptime Color.AnsiColor.format(.gray, "{d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2} ");
    nosuspend stderr.print(formatted_timestamp, .{ time.year, time.month, time.day, time.hour, time.minute, time.second }) catch return;
    nosuspend stderr.print("{s} ", .{level_to_string(level)}) catch return;
    nosuspend stderr.print(message ++ "\n", args) catch return;
}

fn level_to_string(comptime level: std.log.Level) []const u8 {
    return switch (level) {
        .err => Color.AnsiColor.format(.red, "ERROR"),
        .warn => Color.AnsiColor.format(.yellow, "WARN"),
        .info => Color.AnsiColor.format(.blue, "INFO"),
        .debug => Color.AnsiColor.format(.magenta, "DEBUG"),
    };
}
