const std = @import("std");

fn relativePath() []const u8 {
    comptime var src: std.builtin.SourceLocation = @src();
    return std.fs.path.dirname(src.file).? ++ std.fs.path.sep_str;
}

pub fn build(b : *std.build.Builder, target : std.zig.CrossTarget) *std.build.LibExeObjStep {
    comptime var path = relativePath();
    var glad = b.addStaticLibrary("glad", null);
    glad.linkLibC();

    var cFlags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer cFlags.deinit();

    if (target.isLinux()) {
        glad.linkSystemLibrary("gl");
    }

    glad.addIncludeDir(path ++ "include");
    glad.addCSourceFiles(&.{
        path ++ "src/gl.c",
    }, cFlags.items);

    return glad;
}