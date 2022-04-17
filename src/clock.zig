// Iridium Clock
// Keeps track of delta time accurately
// Get deltaTime, and frames per second
// Paperdev-code (c) 2022
const std = @import("std");

const Self = @This();

const sample_count = 24;

/// Delta time in seconds
m_delta_time : f32,
/// FPS
m_frames_per_second : f32,
m_prev_fps : []f32,
m_fps_index : u32,
m_allocator : std.mem.Allocator,
m_begin : f64,
m_end : f64,

const log = std.log.scoped(.IridiumClock);

/// Tick the clock
/// Calculates `delta_time` and `frames_per_second`
pub fn tick(self : *Self) void {
    self.m_end   = @intToFloat(f64, @truncate(i64, std.time.nanoTimestamp())) / std.time.ns_per_s;

    self.m_delta_time = @floatCast(f32, self.m_end - self.m_begin);
    self.m_prev_fps[self.m_fps_index] = 1 / self.m_delta_time;
    self.m_fps_index = (self.m_fps_index + 1) % sample_count;

    self.m_frames_per_second = 0;
    for (self.m_prev_fps) |fps| self.m_frames_per_second += fps;
    self.m_frames_per_second /= sample_count;

    self.m_begin = @intToFloat(f64, @truncate(i64, std.time.nanoTimestamp())) / std.time.ns_per_s;
}

/// Create a clock
pub fn create(allocator : std.mem.Allocator) !Self {
    var prev_fps = try allocator.alloc(f32, sample_count);
    std.mem.set(f32, prev_fps, 0.0);

    return Self {
        .m_delta_time = 0.0,
        .m_frames_per_second = 0.0,
        .m_prev_fps = prev_fps,
        .m_fps_index = 0,
        .m_allocator = allocator,
        .m_begin = 0.0,
        .m_end = 0.0
    };
}

/// Delete a clock
pub fn delete(self : *Self) void {
    self.m_allocator.free(self.m_prev_fps);
}