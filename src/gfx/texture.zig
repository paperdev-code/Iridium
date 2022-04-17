// Iridium Shader
// OpenGL Basic Texture
// Paperdev-code (c) 2022
const c = @import("c.zig");
const std = @import("std");

const Self = @This();

/// Allocator
m_allocator : std.mem.Allocator,
/// Sprite data (RGB)
m_data   : []f32,
/// Sprite width
m_width  : i32,
/// Sprite height
m_height : i32,
/// Internal
m_tex2d  : u32,

const log = std.log.scoped(.IridiumTexture);
pub const IridiumTextureErrors = error {
    IridiumTextureSizeMismatch,
};

/// Use the texture
pub fn bind(self : *Self) void {
    c.glBindTexture(c.GL_TEXTURE_2D, self.m_tex2d);
}

/// Update the texture data
/// Data length must match existing data length
/// When `data` is `null`, simply reuploads the buffer.
/// (Binds the texture)
pub fn update(self : *Self, data : ?[]const f32) !void {
    if (data) |d| {
        if (d.len != self.m_width * self.m_height * 4) {
            log.err("Texture size mismatch", .{});
            return error.IridiumTextureSizeMismatch;
        }
        std.mem.copy(f32, self.m_data, d);
    }
    c.glBindTexture(c.GL_TEXTURE_2D, self.m_tex2d);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGBA32F, self.m_width, self.m_height, 0, c.GL_RGBA, c.GL_FLOAT, self.m_data.ptr);
}

/// Delete the texture
pub fn delete(self : *Self) void {
    self.m_allocator.free(self.m_data);
    c.glDeleteTextures(1, &self.m_tex2d);
    log.info("Deleted {d}x{d} RGBA texture.", .{self.m_width, self.m_height});
}

/// Create the texture
pub fn create(allocator : std.mem.Allocator, width : i32, height : i32) !Self {
    var tex2d : u32 = 0;

    //c.glPixelStorei(c.GL_UNPACK_ALIGNMENT, 4);
    c.glGenTextures(1, &tex2d);
    c.glBindTexture(c.GL_TEXTURE_2D, tex2d);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);

    var data = try allocator.alloc(f32, @intCast(u32, width * height * 4));
    std.mem.set(f32, data, 0.0);

    c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGBA32F, width, height, 0, c.GL_RGBA, c.GL_FLOAT, data.ptr);

    log.info("Created {d}x{d} RGBA texture.", .{width, height});

    return Self {
        .m_allocator = allocator,
        .m_tex2d  = tex2d,
        .m_data   = data,
        .m_width  = width,
        .m_height = height
    };
}