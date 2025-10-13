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

pub const UNICODE = true; // used by zigwin32
const win32 = @import("win32").everything;

const L = win32.L;
const HINSTANCE = win32.HINSTANCE;

pub export fn wWinMain(
    hInstance: HINSTANCE,
    _: ?HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(.winapi) c_int {
    _ = hInstance;
    _ = pCmdLine;
    _ = nCmdShow;

    // MessageBox() can only return IDOK when using MB_OK
    _ = win32.MessageBoxW(null, L("Hello, Windows 98!"), L("HelloMsg"), win32.MB_OK);

    return 0;
}
