const std = @import("std");

fn relativePath() []const u8 {
    comptime var src: std.builtin.SourceLocation = @src();
    return std.fs.path.dirname(src.file).? ++ std.fs.path.sep_str;
}

pub fn build(b : *std.build.Builder, target : std.zig.CrossTarget) *std.build.LibExeObjStep {
    comptime var path = relativePath();
    var cimgui = b.addStaticLibrary("cimgui", null);
    cimgui.linkLibCpp();

    var cFlags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer cFlags.deinit();

    if (target.isLinux()) {
        cimgui.linkSystemLibrary("gl");
    }

    cFlags.append("-DIMGUI_IMPL_API=extern \"C\"")   catch unreachable;
    cFlags.append("-DIMGUI_IMPL_OPENGL_LOADER_GLAD") catch unreachable;

    cimgui.addIncludeDir(path ++ "src");
    cimgui.addIncludeDir(path ++ "src/imgui");
    cimgui.addIncludeDir(path ++ "include");
    cimgui.addIncludeDir(path ++ "include/backend");
    cimgui.addIncludeDir(path ++ "../GLFW/include");

    cimgui.addCSourceFiles(&.{
        path ++ "src/imgui/imgui_demo.cpp",
        path ++ "src/imgui/imgui_draw.cpp",
        path ++ "src/imgui/imgui_tables.cpp",
        path ++ "src/imgui/imgui_widgets.cpp",
        path ++ "src/imgui/imgui.cpp",
        path ++ "src/backend/imgui_impl_glfw.cpp",
        path ++ "src/backend/imgui_impl_opengl3.cpp",
        path ++ "src/cimgui.cpp",
    }, cFlags.items);

    return cimgui;
}