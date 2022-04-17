// Iridium GUI
// Powered by Dear ImGui (cimgui)
// Get the singleton instance with `Gui.get()`
// Paperdev-code (c) 2022
const c = @import("c.zig");
const std = @import("std");

pub usingnamespace @import("singleton").Type(Self);
const Self = @This();

const Window = @import("window.zig");

/// Internal
m_io : *c.ImGuiIO = undefined,

const log = std.log.scoped(.IridiumGui);

/// Initialize GUI systems
pub fn init(self : *Self) !void {
    self.m_io = c.igGetIO();

    // Disable ini output
    self.m_io.IniFilename = null;
}

/// Deinitialize GUI systems, can be omitted.
pub fn deinit(self : *Self) void {
    _ = self;
}

/// Draw the GUI
pub fn draw(self : *Self) void {
    _ = self;
    var window = Window.get();
    var show_demo : bool = true;

    c.ImGui_ImplOpenGL3_NewFrame();
    c.ImGui_ImplGlfw_NewFrame(window.m_handle);
    c.igNewFrame();

    c.igShowDemoWindow(&show_demo);

    c.igRender();

    c.ImGui_ImplOpenGL3_RenderDrawData(c.igGetDrawData());
}