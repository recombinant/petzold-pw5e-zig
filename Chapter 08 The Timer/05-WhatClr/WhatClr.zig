// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/buffer2.html
//
// Chapter 8 - WhatClr
//
// The original source code copyright:
//
// ------------------------------------------
//  WHATCLR.C -- Displays Color Under Cursor
//               (c) Charles Petzold, 1998
// ------------------------------------------
pub const UNICODE = true;

const std = @import("std");

const WINAPI = std.os.windows.WINAPI;

const win32 = struct {
    usingnamespace @import("win32").zig;
    usingnamespace @import("win32").system.library_loader;
    usingnamespace @import("win32").system.system_information;
    usingnamespace @import("win32").foundation;
    usingnamespace @import("win32").ui.windows_and_messaging;
    usingnamespace @import("win32").ui.input.keyboard_and_mouse;
    usingnamespace @import("win32").graphics.gdi;
    usingnamespace @import("win32").globalization;
};
const HINSTANCE = win32.HINSTANCE;
const HWND = win32.HWND;
const HDC = win32.HDC;
const WPARAM = win32.WPARAM;
const LPARAM = win32.LPARAM;
const LRESULT = win32.LRESULT;
const TCHAR = win32.TCHAR;
const POINT = win32.POINT;
const RECT = win32.RECT;
const BOOL = win32.BOOL;
const TRUE = win32.TRUE;
const FALSE = win32.FALSE;
const L = win32.L;

const windowsx = @import("windowsx").windowsx;

pub export fn wWinMain(
    hInstance: HINSTANCE,
    hPrevInstance: ?HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
    _ = hPrevInstance;
    _ = pCmdLine;

    const szAppName = L("WhatClr");

    var wndclassex = win32.WNDCLASSEX{
        .cbSize = @sizeOf(win32.WNDCLASSEX),
        .style = win32.WNDCLASS_STYLES.initFlags(.{ .HREDRAW = 1, .VREDRAW = 1 }),
        .lpfnWndProc = WndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hInstance,
        .hIcon = @ptrCast(win32.HICON, win32.LoadImage(null, win32.IDI_APPLICATION, win32.IMAGE_ICON, 0, 0, win32.IMAGE_FLAGS.initFlags(.{ .SHARED = 1, .DEFAULTSIZE = 1 }))),
        .hCursor = @ptrCast(win32.HCURSOR, win32.LoadImage(null, win32.IDC_ARROW, win32.IMAGE_CURSOR, 0, 0, win32.IMAGE_FLAGS.initFlags(.{ .SHARED = 1, .DEFAULTSIZE = 1 }))),
        .hbrBackground = windowsx.GetStockBrush(win32.WHITE_BRUSH),
        .lpszMenuName = null,
        .lpszClassName = szAppName,
        .hIconSm = null,
    };

    const atom: u16 = win32.RegisterClassEx(&wndclassex);
    if (0 == atom) {
        std.debug.print("failed RegisterClassEx()", .{});
        return 0; // premature exit
    }

    // If a memory align panic occurs then the CreateWindowExW() Zig declaration
    // needs to have align(1) added to the lpClassName parameter.
    //   lpClassName: ?[*:0]align(1) const u16,
    //                      ^^^^^^^^
    // https://github.com/marlersoft/zigwin32gen/issues/9
    const lpClassName = @intToPtr([*:0]align(1) const u16, atom);

    var cxWindow: i32 = undefined;
    var cyWindow: i32 = undefined;
    FindWindowSize(&cxWindow, &cyWindow);

    const hwnd = win32.CreateWindowEx(
        // https://docs.microsoft.com/en-us/windows/win32/winmsg/extended-window-styles
        win32.WINDOW_EX_STYLE.initFlags(.{}),
        lpClassName,
        L("What Color"),
        win32.WINDOW_STYLE.initFlags(.{
            .TILEDWINDOW = 1, // .OVERLAPPEDWINDOW equivalent
            .SYSMENU = 1,
            .CAPTION = 1,
            .BORDER = 1,
        }),
        win32.CW_USEDEFAULT, // initial x position
        win32.CW_USEDEFAULT, // initial y position
        cxWindow,
        cyWindow,
        null, // parent window handle
        null, // window menu handle
        win32.GetModuleHandle(null),
        null,
    );

    if (null == hwnd) {
        std.debug.print("failed CreateWindowEx(), error {}", .{win32.GetLastError()});
        return 0; // premature exit
    }

    _ = win32.ShowWindow(hwnd, @intToEnum(win32.SHOW_WINDOW_CMD, nCmdShow));
    if (0 == win32.UpdateWindow(hwnd)) {
        std.debug.print("failed UpdateWindow()", .{});
        return 0; // premature exit
    }

    var msg: win32.MSG = undefined;
    var ret: BOOL = win32.GetMessage(&msg, null, 0, 0); // three states: -1, 0 or non-zero

    while (0 != ret) {
        if (-1 == ret) {
            // handle the error and/or exit
            // for error call GetLastError();
            std.debug.print("failed message loop, error {}", .{win32.GetLastError()});
            return 0;
        } else {
            _ = win32.TranslateMessage(&msg);
            _ = win32.DispatchMessage(&msg);
        }
        ret = win32.GetMessage(&msg, null, 0, 0);
    }

    // Normal exit
    return @bitCast(c_int, @truncate(c_uint, msg.wParam)); // WM_QUIT
}

fn FindWindowSize(pcxWindow: *i32, pcyWindow: *i32) void {
    var tm: win32.TEXTMETRIC = undefined;

    const hdcScreen = win32.CreateIC(L("DISPLAY"), null, null, null);
    _ = win32.GetTextMetrics(hdcScreen, &tm);
    _ = win32.DeleteDC(hdcScreen);

    pcxWindow.* = 2 * win32.GetSystemMetrics(win32.SM_CXBORDER) +
        12 * tm.tmAveCharWidth;

    pcyWindow.* = 2 * win32.GetSystemMetrics(win32.SM_CYBORDER) +
        win32.GetSystemMetrics(win32.SM_CYCAPTION) +
        2 * tm.tmHeight;
}

const Handler = struct {
    const ID_TIMER = 1;
    cr: windowsx.COLORREF = undefined,
    crLast: windowsx.COLORREF = undefined,
    hdcScreen: HDC = undefined,

    pub fn OnCreate(self: *Handler, hwnd: HWND, _: *win32.CREATESTRUCT) LRESULT {
        self.hdcScreen = win32.CreateDC(L("DISPLAY"), null, null, null);
        _ = win32.SetTimer(hwnd, ID_TIMER, 1000, null);
        return 0;
    }
    pub fn OnDisplayChange(self: *Handler, _: HWND, _: u32, _: u16, _: u16) void {
        _ = win32.DeleteDC(self.hdcScreen);
        self.hdcScreen = win32.CreateDC(L("DISPLAY"), null, null, null);
    }
    pub fn OnTimer(self: *Handler, hwnd: HWND, _: usize) void {
        var pt: POINT = undefined;
        _ = win32.GetCursorPos(&pt);
        self.cr = win32.GetPixel(self.hdcScreen, pt.x, pt.y);

        if (self.cr != self.crLast) {
            self.crLast = self.cr;
            _ = win32.InvalidateRect(hwnd, null, FALSE);
        }
    }
    pub fn OnPaint(self: *Handler, hwnd: HWND) void {
        var ps: win32.PAINTSTRUCT = undefined;
        const hdc: ?HDC = win32.BeginPaint(hwnd, &ps);
        defer _ = win32.EndPaint(hwnd, &ps);

        var rc: RECT = undefined;
        _ = win32.GetClientRect(hwnd, &rc);

        var buffer1: [16]u8 = undefined;
        const slice1 = std.fmt.bufPrint(
            buffer1[0..],
            "  {X:02} {X:02} {X:02}  ",
            .{
                windowsx.GetRValue(self.cr), windowsx.GetGValue(self.cr), windowsx.GetBValue(self.cr),
            },
        ) catch unreachable;

        var buffer2: [16:0]u16 = undefined;
        var len = @intCast(i32, std.unicode.utf8ToUtf16Le(&buffer2, slice1) catch unreachable);

        _ = win32.DrawTextEx(
            hdc,
            &buffer2,
            len,
            &rc,
            win32.DRAW_TEXT_FORMAT.initFlags(.{
                .SINGLELINE = 1,
                .CENTER = 1,
                .VCENTER = 1,
            }),
            null,
        );
    }
    pub fn OnDestroy(self: *Handler, hwnd: HWND) void {
        _ = win32.DeleteDC(self.hdcScreen);
        _ = win32.KillTimer(hwnd, ID_TIMER);
        win32.PostQuitMessage(0);
    }
};

var handler = Handler{};

const WM_CREATE = win32.WM_CREATE;
const WM_DISPLAYCHANGE = win32.WM_DISPLAYCHANGE;
const WM_TIMER = win32.WM_TIMER;
const WM_PAINT = win32.WM_PAINT;
const WM_DESTROY = win32.WM_DESTROY;
const HANDLE_WM_CREATE = windowsx.HANDLE_WM_CREATE;
const HANDLE_WM_DISPLAYCHANGE = windowsx.HANDLE_WM_DISPLAYCHANGE;
const HANDLE_WM_TIMER = windowsx.HANDLE_WM_TIMER;
const HANDLE_WM_PAINT = windowsx.HANDLE_WM_PAINT;
const HANDLE_WM_DESTROY = windowsx.HANDLE_WM_DESTROY;

fn WndProc(
    hwnd: HWND,
    message: u32,
    wParam: WPARAM,
    lParam: LPARAM,
) callconv(WINAPI) LRESULT {
    return switch (message) {
        WM_CREATE => HANDLE_WM_CREATE(hwnd, wParam, lParam, Handler, &handler),
        WM_DISPLAYCHANGE => HANDLE_WM_DISPLAYCHANGE(hwnd, wParam, lParam, Handler, &handler),
        WM_TIMER => HANDLE_WM_TIMER(hwnd, wParam, lParam, Handler, &handler),
        WM_PAINT => HANDLE_WM_PAINT(hwnd, wParam, lParam, Handler, &handler),
        WM_DESTROY => HANDLE_WM_DESTROY(hwnd, wParam, lParam, Handler, &handler),
        else => win32.DefWindowProc(hwnd, message, wParam, lParam),
    };
}
