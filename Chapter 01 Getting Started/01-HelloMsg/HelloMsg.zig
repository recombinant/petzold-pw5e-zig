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
pub const UNICODE = true;

const WINAPI = @import("std").os.windows.WINAPI;

const win32 = struct {
    usingnamespace @import("zigwin32").zig;
    usingnamespace @import("zigwin32").foundation;
    usingnamespace @import("zigwin32").ui.windows_and_messaging;
};
const L = win32.L;
const HINSTANCE = win32.HINSTANCE;

pub export fn wWinMain(
    hInstance: HINSTANCE,
    _: ?HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
    _ = hInstance;
    _ = pCmdLine;
    _ = nCmdShow;

    // MessageBox() can only return IDOK when using MB_OK
    _ = win32.MessageBox(null, L("Hello, Windows 98!"), L("HelloMsg"), win32.MB_OK);

    return 0;
}
