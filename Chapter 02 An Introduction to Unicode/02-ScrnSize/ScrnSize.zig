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

const WINAPI = std.os.windows.WINAPI;

const win32 = struct {
    usingnamespace @import("win32").zig;
    usingnamespace @import("win32").foundation;
    usingnamespace @import("win32").ui.windows_and_messaging;
};
const L = win32.L;
const HINSTANCE = win32.HINSTANCE;

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
    return win32.MessageBox(null, string, L(caption), win32.MB_OK);
}

pub export fn wWinMain(
    hInstance: HINSTANCE,
    _: ?HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
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
