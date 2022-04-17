// Iridium Window
// Powered by GLFW
// Get the singleton instance with `Window.get()`
// Paperdev-code (c) 2022
const c = @import("c.zig");
const std = @import("std");

pub usingnamespace @import("singleton").Type(Self);
const Self = @This();

m_imgui   : ?*c.ImGuiContext = null,
m_handle  : ?*c.GLFWwindow = null,
m_width   : i32 = 0,
m_height  : i32 = 0,
m_focused : bool = false,

const log = std.log.scoped(.IridiumWindow);
pub const IridiumWindowErrors = error {
    IridiumWindowInit,
    IridiumWindowCreate,
    IridiumGlLoad,
    IridiumImguiInit,
    IridiumImguiContext,
    IridiumImguiOpenGL
};

pub fn init(self : *Self, width : i32, height : i32, title : []const u8) IridiumWindowErrors!void {
    if (c.glfwInit() == 0) {
        log.err("GLFW could not initialize", .{});
        return error.IridiumWindowInit;
    }
    log.info("Initialized GLFW", .{});

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 4);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 6);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    c.glfwWindowHint(c.GLFW_TRANSPARENT_FRAMEBUFFER, c.GLFW_TRUE);
    //c.glfwWindowHint(c.GLFW_RESIZABLE, c.GLFW_FALSE);
    
    if (c.glfwCreateWindow(width, height, title.ptr, null, null)) |handle| {
        log.info("Created window", .{});

        _ = c.glfwSetFramebufferSizeCallback(handle, glfwFramebufferSizeCallback);
        _ = c.glfwSetMonitorCallback(c.ImGui_ImplGlfw_MonitorCallback);
        _ = c.glfwSetWindowFocusCallback(handle, glfwWindowFocusCallback);
        log.info("Callbacks set!", .{});

        c.glfwMakeContextCurrent(handle);
        c.glfwSwapInterval(1); // Vsync

        if (c.gladLoadGL(@ptrCast(c.GLADloadfunc, c.glfwGetProcAddress)) == 0) {
            log.err("Could not initialize OpenGL (GLAD)", .{});
            c.glfwDestroyWindow(handle);
            c.glfwTerminate();
            return error.IridiumGlLoad;
        }
        var renderer : [*c]const u8 = c.glGetString(c.GL_RENDERER);
        var version  : [*c]const u8 = c.glGetString(c.GL_VERSION);
        log.info("Initialized OpenGL (GLAD)", .{});
        log.info("Renderer: {s}", .{renderer});
        log.info("OpenGL version: {s}", .{version});

        if (c.igCreateContext(null)) |imgui| {
            if (!c.ImGui_ImplGlfw_InitForOpenGL(handle, false)) {
                log.err("Could not initialize Dear ImGui", .{});
                c.igDestroyContext(imgui);
                c.glfwDestroyWindow(handle);
                c.glfwTerminate();
                return error.IridiumImguiInit;
            }

            if (!c.ImGui_ImplOpenGL3_Init("#version 130")) {
                log.err("Could not initialize Dear ImGui OpenGL3 backend", .{});
                c.igDestroyContext(imgui);
                c.glfwDestroyWindow(handle);
                c.glfwTerminate();
                return error.IridiumImguiOpenGL;
            }
            log.info("Initialized Dear Imgui", .{});

            self.m_imgui  = imgui;
            self.m_width  = width;
            self.m_height = height;
            self.m_handle = handle;
            return;
        }

        log.err("Could not create Dear ImGui context", .{});
        c.glfwDestroyWindow(handle);
        c.glfwTerminate();
        return error.IridiumImguiContext;
    }
    else {
        log.err("Failed to create GLFW window", .{});
        c.glfwTerminate();
        return error.IridiumWindowCreate;
    }
}

pub fn deinit(self : *Self) void {
    c.ImGui_ImplGlfw_Shutdown();
    c.igDestroyContext(self.m_imgui);
    c.glfwDestroyWindow(self.m_handle);
    c.glfwTerminate();
    log.info("Terminated window", .{});
}

pub fn update(self : *Self) void {
    c.glfwSwapBuffers(self.m_handle);
    c.glfwPollEvents();
    c.glViewport(0, 0, self.m_width, self.m_height);
}

pub fn shouldClose(self : *Self) bool {
    return (c.glfwWindowShouldClose(self.m_handle) == c.GLFW_TRUE);
}

pub fn tellToClose(self : *Self) void {
    c.glfwSetWindowShouldClose(self.m_handle, c.GLFW_TRUE);
}

pub fn setTitle(self : *Self, title : []const u8) void {
    c.glfwSetWindowTitle(self.m_handle, title.ptr);
}

fn glfwFramebufferSizeCallback(w : ?*c.GLFWwindow, width : i32, height : i32) callconv(.C) void {
    _ = w;
    var instance = Self.get();
    instance.m_width  = width;
    instance.m_height = height;
}

fn glfwWindowFocusCallback(w : ?*c.GLFWwindow, focused : i32) callconv(.C) void {
    var instance = Self.get();
    instance.m_focused = true;
    c.ImGui_ImplGlfw_WindowFocusCallback(w, focused);
}