const std = @import("std");

/// Application Name for program
const app_name = "iridium_app";

fn relativePath() []const u8 {
    comptime var src: std.builtin.SourceLocation = @src();
    return std.fs.path.dirname(src.file).? ++ std.fs.path.sep_str;
}

fn addLibs(b : *std.build.Builder, exe : *std.build.LibExeObjStep, target : std.zig.CrossTarget) void {
    comptime var path = relativePath();

    const glfw = @import("lib/GLFW/libbuild.zig");
    exe.linkLibrary(glfw.build(b, target));
    exe.addIncludeDir(path ++ "lib/GLFW/include");

    const glad = @import("lib/glad/libbuild.zig");
    exe.linkLibrary(glad.build(b, target));
    exe.addIncludeDir(path ++ "lib/glad/include");

    const cimgui = @import("lib/cimgui/libbuild.zig");
    exe.linkLibrary(cimgui.build(b, target));
    exe.addIncludeDir(path ++ "lib/cimgui");
    exe.addIncludeDir(path ++ "lib/cimgui/backend");
}

pub fn addIridium(b : *std.build.Builder, exe : *std.build.LibExeObjStep, target : std.zig.CrossTarget) void {
    comptime var path = relativePath();
    
    addLibs(b, exe, target);

    const c = std.build.Pkg {
        .name = "c.zig",
        .path = .{.path = path ++ "lib/c.zig"}
    };

    const singleton = std.build.Pkg {
        .name = "singleton",
        .path = .{.path = path ++ "lib/singleton.zig"}
    };

    exe.addPackage(.{
        .name = "iridium",
        .path = .{.path = path ++ "src/pkg.zig"},
        .dependencies = &[_]std.build.Pkg {c, singleton}
    });
}

pub fn build(b: *std.build.Builder) void {

    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable(app_name, "app/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    addIridium(b, exe, target);
    exe.install();
    copyResourcesToBuild(b) catch unreachable;

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

const copyErrors = error {ZigOutInvalid, CannotOpenDir, CannotMakeDir, WalkError, PathMirrorFail, CopyFail};
fn copyResourcesToBuild(b : *std.build.Builder) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    // Zig output folder
    // Find a way to extract this from the bin dir.
    const output_folder   : []const u8 = "zig-out/bin";
    const resource_folder : []const u8 = "res";

    var absolute_install_path = b.getInstallPath(std.build.InstallDir.bin, "");
    var project_path_begin = std.mem.indexOf(u8, absolute_install_path, output_folder);
    if (project_path_begin == null) return error.ZigOutInvalid;
    var project_path = absolute_install_path[0..project_path_begin.?];
    var install_path = absolute_install_path[project_path_begin.?..];

    var project_dir = std.fs.openDirAbsolute(project_path, .{}) catch return error.CannotOpenDir;

    var resources_dir = project_dir.openDir(resource_folder, .{.iterate = true}) catch project_dir.makeOpenPath(resource_folder, .{.iterate = true}) catch return error.CannotMakeDir;
    var install_dir = project_dir.openDir(install_path, .{}) catch project_dir.makeOpenPath(install_path, .{}) catch return error.CannotMakeDir;

    defer project_dir.close();
    defer resources_dir.close();
    defer install_dir.close();

    var resources = try resources_dir.walk(allocator);
    defer resources.deinit();
    while (resources.next() catch return error.WalkError) |resource| {
        if (resource.kind == .File) {
            std.log.debug("Copying {s}", .{resource.path});
            var resource_dir_path = std.fs.path.dirname(resource.path).?;
            install_dir.makePath(resource_dir_path) catch return error.PathMirrorFail;
            std.fs.Dir.copyFile(resources_dir, resource.path, install_dir, resource.path, .{}) catch return error.CopyFail;
        }
    }
}