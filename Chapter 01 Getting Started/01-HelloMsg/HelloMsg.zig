// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 1 - HelloMsg
//
// The original source code copyright:
//
// --------------------------------------------------------------
//  HelloMsg.c -- Displays "Hello, Windows 98!" in a message box
//                (c) Charles Petzold, 1998
// --------------------------------------------------------------
const std = @import("std");

pub const UNICODE = true; // used by zigwin32
const mod_root = @import("win32");
const win32 = struct {
    const L = mod_root.zig.L;
    const HINSTANCE = std.os.windows.HINSTANCE;
    const MB_OK = mod_root.ui.windows_and_messaging.MB_OK;
    const MessageBox = mod_root.ui.windows_and_messaging.MessageBox;
};

pub export fn wWinMain(
    hInstance: win32.HINSTANCE,
    _: ?win32.HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(.winapi) c_int {
    _ = hInstance;
    _ = pCmdLine;
    _ = nCmdShow;

    // MessageBox() can only return IDOK when using MB_OK
    _ = win32.MessageBox(null, win32.L("Hello, Windows 98!"), win32.L("HelloMsg"), win32.MB_OK);

    return 0;
}
