const std = @import("std");

fn relativePath() []const u8 {
    comptime var src: std.builtin.SourceLocation = @src();
    return std.fs.path.dirname(src.file).? ++ std.fs.path.sep_str;
}

pub fn build(b : *std.build.Builder, target : std.zig.CrossTarget) *std.build.LibExeObjStep {
    comptime var path = relativePath();
    var glfw = b.addStaticLibrary("glfw", null);
    glfw.linkLibC();

    var cFlags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer cFlags.deinit();

    glfw.addIncludeDir(path ++ "include");

    if (target.isLinux()) {
        glfw.subsystem = .Posix;
        // Crashes randomly without this. Linux, stay off!
        cFlags.append("-fno-sanitize=undefined")    catch unreachable;
        cFlags.append("-D_GLFW_X11")                catch unreachable;

        glfw.linkSystemLibrary("rt");
        glfw.linkSystemLibrary("m");
        glfw.linkSystemLibrary("x11");

        // Posix, linux implementation.
        glfw.addCSourceFiles(&.{
            path ++ "src/posix_time.c",
            path ++ "src/posix_thread.c",
            path ++ "src/posix_module.c",
        }, cFlags.items);

        // X11 Related code.
        glfw.addCSourceFiles(&.{
            path ++ "src/x11_init.c",
            path ++ "src/x11_monitor.c",
            path ++ "src/x11_window.c",
            path ++ "src/xkb_unicode.c",
            path ++ "src/glx_context.c",
        }, cFlags.items);

        // Joystick implementation of Linux
        glfw.addCSourceFiles(&.{
            path ++ "src/linux_joystick.c",
        }, cFlags.items);
    }

    // These are included regardless of operating system.
    glfw.addCSourceFiles(&.{
        path ++ "src/osmesa_context.c",
        path ++ "src/egl_context.c",
        path ++ "src/context.c",
        path ++ "src/init.c",
        path ++ "src/input.c",
        path ++ "src/monitor.c",
        path ++ "src/vulkan.c",
        path ++ "src/window.c",
        path ++ "src/platform.c",
        path ++ "src/null_monitor.c",
        path ++ "src/null_window.c",
        path ++ "src/null_joystick.c",
        path ++ "src/null_init.c",
    }, cFlags.items);

    return glfw;
}