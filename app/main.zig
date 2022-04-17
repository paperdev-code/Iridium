const iridium = @import("iridium");

const std = @import("std");
const log = std.log.scoped(.Main);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    const window = iridium.Window.get();
    const input  = iridium.Input.get();
    const gui = iridium.Gui.get();

    try window.init(640, 480, "Iridium Test");
    defer window.deinit();

    var window_title = try allocator.alloc(u8, 32);
    defer allocator.free(window_title);
    
    try input.init();
    defer input.deinit();

    try gui.init();
    defer gui.deinit();

    var clock = try iridium.Clock.create(allocator);
    defer clock.delete();

    const clear_color = .{.r = 0.3, .g = 0.6, .b = 0.3};

    log.info("Started main loop", .{});
    while (!window.shouldClose()) {
        const Key = iridium.Input.Key;
        const State = iridium.Input.State;

        if (input.keyIs(Key.Q, State.Pressed))
            window.tellToClose();

        iridium.Render.clear(clear_color);
        iridium.Gui.get().draw();

        input.update();
        window.update();
 
        clock.tick();
        window.setTitle(
            try std.fmt.bufPrintZ(window_title, "Iridium - {d:.0} FPS", .{clock.m_frames_per_second})
        );
    }

    log.info("Exiting", .{});
}