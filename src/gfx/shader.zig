// Iridium Shader
// Compile GLSL shaders for OpenGL
// Use the create function to create shader from files.
// Paperdev-code (c) 2022
const c = @import("c.zig");
const std = @import("std");

const Self = @This();

/// Uniform types
const Uniforms = enum {
    uniform4f,
    uniform2f,
    uniformi,
};

const Uniform = union(Uniforms) {
    uniform4f : [4]f32,
    uniform2f : [2]f32,
    uniformi  : i32,
};

/// Internal
m_name    : [64]u8 = [1]u8{0} ** 64,
m_program : u32,

const log = std.log.scoped(.IridiumShader);
pub const IridiumShaderErrors = error {
    IridiumShaderOpen,
    IridiumShaderRead,
    IridiumShaderCompile,
    IridiumShaderLink
};

/// Set a uniform of a shader
pub fn setUniform(self : *Self, name : []const u8, uniform : Uniform) void {
    var location = c.glGetUniformLocation(self.m_program, name.ptr);
    switch (uniform) {
        .uniform4f => |u| c.glUniform4f(location, u[0], u[1], u[2], u[3]),
        .uniform2f => |u| c.glUniform2f(location, u[0], u[1]),
        .uniformi  => |u| c.glUniform1i(location, u),
    }
}

/// Use the shader
pub fn use(self : *Self) void {
    c.glUseProgram(self.m_program);
}

/// Delete the shader
pub fn delete(self : *Self) void {
    log.info("'{s}' deleted!", .{self.m_name});
    c.glDeleteProgram(self.m_program);
}

/// Create the shader
/// Opens a frag and vert shader file and creates a program.
pub fn create(allocator : std.mem.Allocator, shader_name : []const u8) !Self {
    var info   : [512]u8 = [1]u8{0} ** 512;
    const shader_dir = "shaders";

    var success : i32 = 0;
    var file : std.fs.File = undefined;
    var stat : std.fs.File.Stat = undefined;
    var code : []u8 = undefined;
    var exe_path = try std.fs.selfExeDirPathAlloc(allocator);
    defer allocator.free(exe_path);

    var vert = c.glCreateShader(c.GL_VERTEX_SHADER);
    var frag = c.glCreateShader(c.GL_FRAGMENT_SHADER);

    var vert_path = try std.mem.concat(allocator, u8, &[_][]const u8 {
        exe_path, std.fs.path.sep_str, shader_dir, std.fs.path.sep_str, shader_name, ".vert"});

    file = std.fs.openFileAbsolute(vert_path, .{}) catch return error.IridiumShaderOpen;
    stat = file.stat() catch return error.IridiumShaderRead;
    code = try allocator.alloc(u8, stat.size + 1);
    code[stat.size] = 0;
    _ = try file.readAll(code);

    // Compile vertex shader
    log.debug("Compiling vertex shader '{s}'", .{vert_path});
    c.glShaderSource(vert, 1, &code.ptr, 0);
    c.glCompileShader(vert);

    file.close();
    allocator.free(code);
    allocator.free(vert_path);

    success = 0;
    c.glGetShaderiv(vert, c.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        c.glGetShaderInfoLog(vert, 512, 0, &info[0]);
        log.err("Compilation failed.", .{});
        log.debug("{s}", .{info});
        return error.IridiumShaderCompile;
    }

    var frag_path = try std.mem.concat(allocator, u8, &[_][]const u8 {
        exe_path, std.fs.path.sep_str, shader_dir, std.fs.path.sep_str, shader_name, ".frag"});
    
    file = std.fs.openFileAbsolute(frag_path, .{}) catch return error.IridiumShaderOpen;
    code = try allocator.alloc(u8, stat.size + 1);
    code[stat.size] = 0;
    _ = try file.readAll(code);

    // Compile fragment shader
    log.debug("Compiling fragment shader '{s}'", .{frag_path});
    c.glShaderSource(frag, 1, &code.ptr, 0);
    c.glCompileShader(frag);

    file.close();
    allocator.free(code);
    allocator.free(frag_path);

    success = 0;
    c.glGetShaderiv(frag, c.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        c.glGetShaderInfoLog(frag, 512, 0, &info[0]);
        log.err("Compilation failed.", .{});
        log.debug("{s}", .{info});

        // Delete previously compiled vertex shader.
        c.glDeleteShader(vert);
        
        return error.IridiumShaderCompile;
    }

    var program = c.glCreateProgram();
    c.glAttachShader(program, vert);
    c.glAttachShader(program, frag);
    c.glLinkProgram(program);

    success = 0;
    c.glGetProgramiv(program, c.GL_LINK_STATUS, &success);
    if (success == 0) {
        c.glGetProgramInfoLog(program, 512, 0, &info[0]);
        log.err("Linking failed.", .{});
        log.debug("{s}", .{info});
        c.glDeleteShader(vert);
        c.glDeleteShader(frag);
        return error.IridiumShaderLink;
    }

    c.glDeleteShader(vert);
    c.glDeleteShader(frag);
    log.info("'{s}' created!", .{shader_name});

    var shader = Self {
        .m_program = program
    };
    std.mem.copy(u8, &shader.m_name, shader_name);

    return shader;
}