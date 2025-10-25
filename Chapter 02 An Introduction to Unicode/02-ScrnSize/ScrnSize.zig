// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 2 - ScrnSize
//
// The original source code copyright:
//
// -----------------------------------------------------
//  ScrnSize.c -- Displays screen size in a message box
//                (c) Charles Petzold, 1998
// -----------------------------------------------------
const std = @import("std");

pub const UNICODE = true; // used by zigwin32
const mod_root = @import("win32");
const win32 = struct {
    const L = mod_root.zig.L;
    const HINSTANCE = std.os.windows.HINSTANCE;
    const MB_OK = mod_root.ui.windows_and_messaging.MB_OK;
    const MESSAGEBOX_RESULT = mod_root.ui.windows_and_messaging.MESSAGEBOX_RESULT;
    const SM_CXSCREEN = mod_root.ui.windows_and_messaging.SM_CXSCREEN;
    const SM_CYSCREEN = mod_root.ui.windows_and_messaging.SM_CYSCREEN;
    const GetSystemMetrics = mod_root.ui.windows_and_messaging.GetSystemMetrics;
    const MessageBox = mod_root.ui.windows_and_messaging.MessageBox;
};

fn MessageBoxPrintf(
    comptime caption: []const u8,
    comptime fmt: []const u8,
    args: anytype,
) win32.MESSAGEBOX_RESULT {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // catch unreachable to panic on any errors.
    const buffer = std.fmt.allocPrint(allocator, fmt, args) catch unreachable;
    const string = std.unicode.utf8ToUtf16LeAllocZ(allocator, buffer) catch unreachable;

    defer {
        allocator.free(string);
        allocator.free(buffer);
    }

    // MessageBox() always returns IDOK with MB_OK
    return win32.MessageBox(null, string, win32.L(caption), win32.MB_OK);
}

pub export fn wWinMain(
    hInstance: win32.HINSTANCE,
    _: ?win32.HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(.winapi) c_int {
    _ = hInstance;
    _ = pCmdLine;
    _ = nCmdShow;

    const cxScreen = win32.GetSystemMetrics(win32.SM_CXSCREEN);
    const cyScreen = win32.GetSystemMetrics(win32.SM_CYSCREEN);

    _ = MessageBoxPrintf(
        "ScrnSize",
        "The screen is {d} pixels wide by {d} pixels high.",
        .{ cxScreen, cyScreen },
    );

    return 0;
}
