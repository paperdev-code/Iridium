// Iridium Rendering Functions
// Paperdev-code (c) 2022
const c = @import("c.zig");
const std = @import("std");

const Window  = @import("../window.zig");
const Texture = @import("texture.zig");
const Shader  = @import("shader.zig");

const log = std.log.scoped(.IridiumRender);

pub fn clear(color : struct {
    r : f32,
    g : f32,
    b : f32
}) void {
    c.glClearColor(color.r, color.g, color.b, 1.0);
    c.glClear(c.GL_COLOR_BUFFER_BIT);
}

/// Draw a texture on a simple rectangle
pub fn texturedRect(texture : *Texture, shader : *Shader, rect : struct {
    x : f32,
    y : f32,
    x_scale : f32,
    y_scale : f32,
}) void {
    // Made static inside function for simplicity.
    // Downside is this cannot be cleaned up neatly.
    // TODO a mesh.zig, or vao, vbo.zig, etc.
    // TODO A proper renderer while we're at it.
    const Static = struct {
        var rect_initialized : bool = false;
        var rect_vao  : u32 = 0;
        var rect_vbo  : u32 = 0;
        var rect_mesh = [_]f32 {
        //   Vertices      Tex Coords
            -1.0,  1.0,    0.0, 0.0,
             1.0,  1.0,    1.0, 0.0,
             1.0, -1.0,    1.0, 1.0,
             1.0, -1.0,    1.0, 1.0,
            -1.0, -1.0,    0.0, 1.0,
            -1.0,  1.0,    0.0, 0.0,
        };
    };

    if (!Static.rect_initialized) {
        c.glGenVertexArrays(1, &Static.rect_vao);
        c.glBindVertexArray(Static.rect_vao);

        c.glGenBuffers(1, &Static.rect_vbo);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, Static.rect_vbo);
        c.glBufferData(c.GL_ARRAY_BUFFER, @intCast(c_long, @sizeOf(f32) * Static.rect_mesh.len), &Static.rect_mesh[0], c.GL_STATIC_DRAW);
        
        // Vertex X, Y
        c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 4 * @sizeOf(f32), @intToPtr(?*const anyopaque, 0 * @sizeOf(f32)));
        c.glEnableVertexAttribArray(0);

        // TexCoord X, Y
        c.glVertexAttribPointer(1, 2, c.GL_FLOAT, c.GL_FALSE, 4 * @sizeOf(f32), @intToPtr(?*const anyopaque, 2 * @sizeOf(f32)));
        c.glEnableVertexAttribArray(1);
        
        Static.rect_initialized = true;
        log.debug("Initialized Textured Rect VAO and VBO", .{});
    }

    shader.use();
    shader.setUniform("quadTransform", .{.uniform4f = .{rect.x, rect.y, rect.x_scale, rect.y_scale}});
    
    texture.bind();
    c.glBindVertexArray(Static.rect_vao);

    c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);
    c.glEnable(c.GL_BLEND);
    c.glDrawArrays(c.GL_TRIANGLES, 0, @intCast(c_int, Static.rect_mesh.len / 2));
}