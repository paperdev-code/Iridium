const std = @import("std");

fn relativePath() []const u8 {
    comptime var src: std.builtin.SourceLocation = @src();
    return std.fs.path.dirname(src.file).? ++ std.fs.path.sep_str;
}

pub fn build(b : *std.build.Builder, target : std.zig.CrossTarget) *std.build.LibExeObjStep {
    _ = target;

    comptime var path = relativePath();
    var stb = b.addStaticLibrary("stb", null);
    stb.linkLibC();

    var cFlags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer cFlags.deinit();

    stb.addIncludeDir(path ++ "include");
    stb.addCSourceFiles(&.{
        path ++ "src/stb.c",
    }, cFlags.items);

    return stb;
}