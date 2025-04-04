// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 4 - SysMets.h
//
// -----------------------------------------------
//  SYSMETS.H -- System metrics display structure
// -----------------------------------------------

const win32 = @import("win32").ui.windows_and_messaging;

const SystemMetrics = struct {
    index: win32.SYSTEM_METRICS_INDEX,
    label: []const u8,
    description: []const u8,
};

pub const sysmetrics = [_]SystemMetrics{
    .{ .index = win32.SM_CXSCREEN, .label = "SM_CXSCREEN", .description = "Screen width in pixels" },
    .{ .index = win32.SM_CYSCREEN, .label = "SM_CYSCREEN", .description = "Screen height in pixels" },
    .{ .index = win32.SM_CXVSCROLL, .label = "SM_CXVSCROLL", .description = "Vertical scroll width" },
    .{ .index = win32.SM_CYHSCROLL, .label = "SM_CYHSCROLL", .description = "Horizontal scroll height" },
    .{ .index = win32.SM_CYCAPTION, .label = "SM_CYCAPTION", .description = "Caption bar height" },
    .{ .index = win32.SM_CXBORDER, .label = "SM_CXBORDER", .description = "Window border width" },
    .{ .index = win32.SM_CYBORDER, .label = "SM_CYBORDER", .description = "Window border height" },
    .{ .index = win32.SM_CXFIXEDFRAME, .label = "SM_CXFIXEDFRAME", .description = "Dialog window frame width" },
    .{ .index = win32.SM_CYFIXEDFRAME, .label = "SM_CYFIXEDFRAME", .description = "Dialog window frame height" },
    .{ .index = win32.SM_CYVTHUMB, .label = "SM_CYVTHUMB", .description = "Vertical scroll thumb height" },
    .{ .index = win32.SM_CXHTHUMB, .label = "SM_CXHTHUMB", .description = "Horizontal scroll thumb width" },
    .{ .index = win32.SM_CXICON, .label = "SM_CXICON", .description = "Icon width" },
    .{ .index = win32.SM_CYICON, .label = "SM_CYICON", .description = "Icon height" },
    .{ .index = win32.SM_CXCURSOR, .label = "SM_CXCURSOR", .description = "Cursor width" },
    .{ .index = win32.SM_CYCURSOR, .label = "SM_CYCURSOR", .description = "Cursor height" },
    .{ .index = win32.SM_CYMENU, .label = "SM_CYMENU", .description = "Menu bar height" },
    .{ .index = win32.SM_CXFULLSCREEN, .label = "SM_CXFULLSCREEN", .description = "Full screen client area width" },
    .{ .index = win32.SM_CYFULLSCREEN, .label = "SM_CYFULLSCREEN", .description = "Full screen client area height" },
    .{ .index = win32.SM_CYKANJIWINDOW, .label = "SM_CYKANJIWINDOW", .description = "Kanji window height" },
    .{ .index = win32.SM_MOUSEPRESENT, .label = "SM_MOUSEPRESENT", .description = "Mouse present flag" },
    .{ .index = win32.SM_CYVSCROLL, .label = "SM_CYVSCROLL", .description = "Vertical scroll arrow height" },
    .{ .index = win32.SM_CXHSCROLL, .label = "SM_CXHSCROLL", .description = "Horizontal scroll arrow width" },
    .{ .index = win32.SM_DEBUG, .label = "SM_DEBUG", .description = "Debug version flag" },
    .{ .index = win32.SM_SWAPBUTTON, .label = "SM_SWAPBUTTON", .description = "Mouse buttons swapped flag" },
    .{ .index = win32.SM_CXMIN, .label = "SM_CXMIN", .description = "Minimum window width" },
    .{ .index = win32.SM_CYMIN, .label = "SM_CYMIN", .description = "Minimum window height" },
    .{ .index = win32.SM_CXSIZE, .label = "SM_CXSIZE", .description = "Min/Max/Close button width" },
    .{ .index = win32.SM_CYSIZE, .label = "SM_CYSIZE", .description = "Min/Max/Close button height" },
    .{ .index = win32.SM_CXSIZEFRAME, .label = "SM_CXSIZEFRAME", .description = "Window sizing frame width" },
    .{ .index = win32.SM_CYSIZEFRAME, .label = "SM_CYSIZEFRAME", .description = "Window sizing frame height" },
    .{ .index = win32.SM_CXMINTRACK, .label = "SM_CXMINTRACK", .description = "Minimum window tracking width" },
    .{ .index = win32.SM_CYMINTRACK, .label = "SM_CYMINTRACK", .description = "Minimum window tracking height" },
    .{ .index = win32.SM_CXDOUBLECLK, .label = "SM_CXDOUBLECLK", .description = "Double click x tolerance" },
    .{ .index = win32.SM_CYDOUBLECLK, .label = "SM_CYDOUBLECLK", .description = "Double click y tolerance" },
    .{ .index = win32.SM_CXICONSPACING, .label = "SM_CXICONSPACING", .description = "Horizontal icon spacing" },
    .{ .index = win32.SM_CYICONSPACING, .label = "SM_CYICONSPACING", .description = "Vertical icon spacing" },
    .{ .index = win32.SM_MENUDROPALIGNMENT, .label = "SM_MENUDROPALIGNMENT", .description = "Left or right menu drop" },
    .{ .index = win32.SM_PENWINDOWS, .label = "SM_PENWINDOWS", .description = "Pen extensions installed" },
    .{ .index = win32.SM_DBCSENABLED, .label = "SM_DBCSENABLED", .description = "Double-Byte Char Set enabled" },
    .{ .index = win32.SM_CMOUSEBUTTONS, .label = "SM_CMOUSEBUTTONS", .description = "Number of mouse buttons" },
    .{ .index = win32.SM_SECURE, .label = "SM_SECURE", .description = "Security present flag" },
    .{ .index = win32.SM_CXEDGE, .label = "SM_CXEDGE", .description = "3-D border width" },
    .{ .index = win32.SM_CYEDGE, .label = "SM_CYEDGE", .description = "3-D border height" },
    .{ .index = win32.SM_CXMINSPACING, .label = "SM_CXMINSPACING", .description = "Minimized window spacing width" },
    .{ .index = win32.SM_CYMINSPACING, .label = "SM_CYMINSPACING", .description = "Minimized window spacing height" },
    .{ .index = win32.SM_CXSMICON, .label = "SM_CXSMICON", .description = "Small icon width" },
    .{ .index = win32.SM_CYSMICON, .label = "SM_CYSMICON", .description = "Small icon height" },
    .{ .index = win32.SM_CYSMCAPTION, .label = "SM_CYSMCAPTION", .description = "Small caption height" },
    .{ .index = win32.SM_CXSMSIZE, .label = "SM_CXSMSIZE", .description = "Small caption button width" },
    .{ .index = win32.SM_CYSMSIZE, .label = "SM_CYSMSIZE", .description = "Small caption button height" },
    .{ .index = win32.SM_CXMENUSIZE, .label = "SM_CXMENUSIZE", .description = "Menu bar button width" },
    .{ .index = win32.SM_CYMENUSIZE, .label = "SM_CYMENUSIZE", .description = "Menu bar button height" },
    .{ .index = win32.SM_ARRANGE, .label = "SM_ARRANGE", .description = "How minimized windows arranged" },
    .{ .index = win32.SM_CXMINIMIZED, .label = "SM_CXMINIMIZED", .description = "Minimized window width" },
    .{ .index = win32.SM_CYMINIMIZED, .label = "SM_CYMINIMIZED", .description = "Minimized window height" },
    .{ .index = win32.SM_CXMAXTRACK, .label = "SM_CXMAXTRACK", .description = "Maximum draggable width" },
    .{ .index = win32.SM_CYMAXTRACK, .label = "SM_CYMAXTRACK", .description = "Maximum draggable height" },
    .{ .index = win32.SM_CXMAXIMIZED, .label = "SM_CXMAXIMIZED", .description = "Width of maximized window" },
    .{ .index = win32.SM_CYMAXIMIZED, .label = "SM_CYMAXIMIZED", .description = "Height of maximized window" },
    .{ .index = win32.SM_NETWORK, .label = "SM_NETWORK", .description = "Network present flag" },
    .{ .index = win32.SM_CLEANBOOT, .label = "SM_CLEANBOOT", .description = "How system was booted" },
    .{ .index = win32.SM_CXDRAG, .label = "SM_CXDRAG", .description = "Avoid drag x tolerance" },
    .{ .index = win32.SM_CYDRAG, .label = "SM_CYDRAG", .description = "Avoid drag y tolerance" },
    .{ .index = win32.SM_SHOWSOUNDS, .label = "SM_SHOWSOUNDS", .description = "Present sounds visually" },
    .{ .index = win32.SM_CXMENUCHECK, .label = "SM_CXMENUCHECK", .description = "Menu check-mark width" },
    .{ .index = win32.SM_CYMENUCHECK, .label = "SM_CYMENUCHECK", .description = "Menu check-mark height" },
    .{ .index = win32.SM_SLOWMACHINE, .label = "SM_SLOWMACHINE", .description = "Slow processor flag" },
    .{ .index = win32.SM_MIDEASTENABLED, .label = "SM_MIDEASTENABLED", .description = "Hebrew and Arabic enabled flag" },
    .{ .index = win32.SM_MOUSEWHEELPRESENT, .label = "SM_MOUSEWHEELPRESENT", .description = "Mouse wheel present flag" },
    .{ .index = win32.SM_XVIRTUALSCREEN, .label = "SM_XVIRTUALSCREEN", .description = "Virtual screen x origin" },
    .{ .index = win32.SM_YVIRTUALSCREEN, .label = "SM_YVIRTUALSCREEN", .description = "Virtual screen y origin" },
    .{ .index = win32.SM_CXVIRTUALSCREEN, .label = "SM_CXVIRTUALSCREEN", .description = "Virtual screen width" },
    .{ .index = win32.SM_CYVIRTUALSCREEN, .label = "SM_CYVIRTUALSCREEN", .description = "Virtual screen height" },
    .{ .index = win32.SM_CMONITORS, .label = "SM_CMONITORS", .description = "Number of monitors" },
    .{ .index = win32.SM_SAMEDISPLAYFORMAT, .label = "SM_SAMEDISPLAYFORMAT", .description = "Same color format flag" },
};

// Precompute maximum buffer sizes.
// The strings are ASCII so the buffer size required will be the string length.
pub const buffer_sizes = blk: {
    var label_size: usize = 0;
    var description_size: usize = 0;
    for (sysmetrics) |metric| {
        label_size = @max(label_size, metric.label.len);
        description_size = @max(description_size, metric.description.len);
    }
    break :blk .{
        .label = label_size + 1,
        .description = description_size + 1,
    };
};

pub const num_lines: i32 = @intCast(sysmetrics.len);
