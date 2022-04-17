// Iridium Input
// Powered by GLFW
// Get the singleton instance with `Input.get()`
// Paperdev-code (c) 2021
const c = @import("c.zig");
const std = @import("std");

pub usingnamespace @import("singleton").Type(Self);
const Self = @This();

/// Mouse buttons
pub const Mb = enum(i32) {
    Left = 0,
    Middle,
    Right,
    _Count,
    Undefined
};

/// Keyboard keys
pub const Key = enum(i32) {
    Q = 0,
    _Count,
    Undefined,
};

/// Possible states of key/mb
pub const State = enum(i32) {
    Up,
    Pressed,
    Down,
    Released
};

const Window = @import("window.zig");

/// Internal
m_keystates : [@enumToInt(Key._Count)]State = [1]State{State.Up} ** @enumToInt(Key._Count),
/// Internal
m_mbstates  : [@enumToInt(Mb._Count)]State = [1]State{State.Up} ** @enumToInt(Mb._Count),
/// Cursor position x
m_cursor_x  : f32 = 0,
/// Cursor position y
m_cursor_y  : f32 = 0,
/// Cursor entered window
m_cursor_on_window : bool = false,

const log = std.log.scoped(.IridiumInput);
pub const IridiumInputErrors = error {
    IridiumInputWindowNull,
};

/// Initialize Iridium input handler
/// Triggered by `iridium.init()`
pub fn init(self : *Self) IridiumInputErrors!void {
    _ = self;
    if (Window.get().m_handle) |handle| {
        _ = c.glfwSetKeyCallback(handle, glfwKeyCallback);
        _ = c.glfwSetCursorPosCallback(handle, glfwCursorPosCallback);
        _ = c.glfwSetMouseButtonCallback(handle, glfwMouseButtonCallback);
        _ = c.glfwSetCursorEnterCallback(handle, glfwCursorEnterCallback);
        _ = c.glfwSetScrollCallback(handle, glfwScrollCallback);
        _ = c.glfwSetCharCallback(handle, glfwCharCallback);
        log.info("Callbacks set!", .{});
    }
    else {
        log.err("IridiumWindow has not been initialized", .{});
        return error.IridiumInputWindowNull;
    }
}

/// For completeness, but can be omitted
pub fn deinit(self : *Self) void {
    _ = self;
}

/// Boolean expression for checking keyboard key state
pub fn keyIs(self : *Self, key : Key, state : State) bool {
    return (self.m_keystates[@intCast(usize, @enumToInt(key))] == state);
}

/// Boolean expresssion for checking mouse button state
pub fn mbIs(self : *Self, mb : Mb, state : State) bool {
    return (self.m_mbstates[@intCast(usize, @enumToInt(mb))] == state);
}

/// Update keys and buttons
pub fn update(self : *Self) void {
    for (self.m_keystates) |state, i| {
        self.m_keystates[i] = switch(state) {
            State.Pressed => State.Down,
            State.Released => State.Up,
            else => self.m_keystates[i]
        };
    }

    for (self.m_mbstates) |state, i| {
        self.m_mbstates[i] = switch(state) {
            State.Pressed => State.Down,
            State.Released => State.Up,
            else => self.m_mbstates[i]
        };
    }
}

/// Internal
fn newState(current_key_state : State, action : i32) State {
    return switch (current_key_state) {
        State.Up, State.Released =>
            if (action == c.GLFW_PRESS)
                State.Pressed
            else current_key_state
        ,
        State.Down, State.Pressed =>
            if (action == c.GLFW_RELEASE)
                State.Released
            else
                current_key_state
    };
}

/// Internal
fn setKeyState(self : *Self, key : i32, action : i32) void {
    var current_key = switch (key) {
        c.GLFW_KEY_Q => Key.Q,
        else => Key.Undefined
    };

    if (current_key == Key.Undefined)
        return;
    
    var current_key_index = @intCast(usize, @enumToInt(current_key));
    var current_key_state = self.m_keystates[current_key_index];

    var new_state = newState(current_key_state, action);
    self.m_keystates[current_key_index] = new_state;
}

/// Internal
fn setMbState(self : *Self, mb : i32, action : i32) void {
    var current_mb = switch(mb) {
        c.GLFW_MOUSE_BUTTON_LEFT => Mb.Left,
        c.GLFW_MOUSE_BUTTON_RIGHT => Mb.Right,
        c.GLFW_MOUSE_BUTTON_MIDDLE => Mb.Middle,
        else => Mb.Undefined
    };

    if (current_mb == Mb.Undefined)
        return;
    
    var current_mb_index = @intCast(usize, @enumToInt(current_mb));
    var current_mb_state = self.m_mbstates[current_mb_index];

    var new_state = newState(current_mb_state, action);
    self.m_mbstates[current_mb_index] = new_state;
}

/// Static GLFW callback
fn glfwKeyCallback(w : ?*c.GLFWwindow, key : i32, scancode : i32, action : i32, mods : i32) callconv(.C) void {
    var instance = Self.get();
    instance.setKeyState(key, action);
    c.ImGui_ImplGlfw_KeyCallback(w, key, scancode, action, mods);
}

/// Static GLFW callback
fn glfwMouseButtonCallback(w : ?*c.GLFWwindow, button : i32, action : i32, mods : i32) callconv(.C) void {
    var instance = Self.get();
    instance.setMbState(button, action);
    c.ImGui_ImplGlfw_MouseButtonCallback(w, button, action, mods);
}

/// Static GLFW callback
fn glfwCursorPosCallback(w : ?*c.GLFWwindow, x : f64, y : f64) callconv(.C) void {
    var instance = Self.get();
    instance.m_cursor_x = @floatCast(f32, x);
    instance.m_cursor_y = @floatCast(f32, y);
    c.ImGui_ImplGlfw_CursorPosCallback(w, x, y);
}

fn glfwScrollCallback(w : ?*c.GLFWwindow, xoffset : f64, yoffset : f64) callconv(.C) void {
    c.ImGui_ImplGlfw_ScrollCallback(w, xoffset, yoffset);
}

fn glfwCharCallback(w : ?*c.GLFWwindow, char : u32) callconv(.C) void {
    c.ImGui_ImplGlfw_CharCallback(w, char);
}

fn glfwCursorEnterCallback(w : ?*c.GLFWwindow, entered : i32) callconv(.C) void {
    var instance = Self.get();
    instance.m_cursor_on_window = (entered == 1);
    c.ImGui_ImplGlfw_CursorEnterCallback(w, entered);
}