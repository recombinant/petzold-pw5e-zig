// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 8 - DigClock
//
// The original source code copyright:
//
// --------------------------------------
//  TYPER.C -- Typing Program
//             (c) Charles Petzold, 1998
// --------------------------------------
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
const POINT = win32.POINT;
const BOOL = win32.BOOL;
const L = win32.L;
const SYSTEM_FONT = win32.SYSTEM_FONT;

const windowsx = @import("windowsx");

pub export fn wWinMain(
    hInstance: HINSTANCE,
    hPrevInstance: ?HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
    _ = hPrevInstance;
    _ = pCmdLine;

    const szAppName = L("Typer");

    var wndclassex = win32.WNDCLASSEX{
        .cbSize = @sizeOf(win32.WNDCLASSEX),
        .style = win32.WNDCLASS_STYLES{ .HREDRAW = 1, .VREDRAW = 1 },
        .lpfnWndProc = WndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hInstance,
        .hIcon = @ptrCast(win32.LoadImage(null, win32.IDI_APPLICATION, win32.IMAGE_ICON, 0, 0, win32.IMAGE_FLAGS{ .SHARED = 1, .DEFAULTSIZE = 1 })),
        .hCursor = @ptrCast(win32.LoadImage(null, win32.IDC_ARROW, win32.IMAGE_CURSOR, 0, 0, win32.IMAGE_FLAGS{ .SHARED = 1, .DEFAULTSIZE = 1 })),
        .hbrBackground = windowsx.GetStockBrush(win32.WHITE_BRUSH),
        .lpszMenuName = null,
        .lpszClassName = szAppName,
        .hIconSm = null,
    };

    const atom: u16 = win32.RegisterClassEx(&wndclassex);
    if (0 == atom) {
        std.log.err("failed RegisterClassEx()", .{});
        return 0; // premature exit
    }

    // If a memory align panic occurs with CreateWindowExW() lpClassName then look at:
    // https://github.com/marlersoft/zigwin32gen/issues/9

    const hwnd = win32.CreateWindowEx(
        // https://docs.microsoft.com/en-us/windows/win32/winmsg/extended-window-styles
        win32.WINDOW_EX_STYLE{},
        @ptrFromInt(atom),
        L("Typing Program"),
        win32.WS_OVERLAPPEDWINDOW,
        win32.CW_USEDEFAULT, // initial x position
        win32.CW_USEDEFAULT, // initial y position
        win32.CW_USEDEFAULT, // initial x size
        win32.CW_USEDEFAULT, // initial y size
        null, // parent window handle
        null, // window menu handle
        win32.GetModuleHandle(null),
        null,
    );

    if (null == hwnd) {
        std.log.err("failed CreateWindowEx(), error {}", .{win32.GetLastError()});
        return 0; // premature exit
    }

    _ = win32.ShowWindow(hwnd, @bitCast(nCmdShow));
    if (0 == win32.UpdateWindow(hwnd)) {
        std.log.err("failed UpdateWindow()", .{});
        return 0; // premature exit
    }

    var msg: win32.MSG = undefined;
    var ret: BOOL = win32.GetMessage(&msg, null, 0, 0); // three states: -1, 0 or non-zero

    while (0 != ret) {
        if (-1 == ret) {
            // handle the error and/or exit
            // for error call GetLastError();
            std.log.err("failed message loop, error {}", .{win32.GetLastError()});
            return 0;
        } else {
            _ = win32.TranslateMessage(&msg);
            _ = win32.DispatchMessage(&msg);
        }
        ret = win32.GetMessage(&msg, null, 0, 0);
    }

    // Normal exit
    return @bitCast(@as(c_uint, @truncate(msg.wParam))); // WM_QUIT
}

const Handler = struct {
    dwCharSet: u32 = win32.DEFAULT_CHARSET,
    cxChar: i32 = undefined,
    cyChar: i32 = undefined,
    cxClient: i32 = undefined,
    cyClient: i32 = undefined,
    cxBuffer: i32 = undefined,
    cyBuffer: i32 = undefined,
    cxCaret: i32 = undefined,
    cyCaret: i32 = undefined,
    pBuffer: [20]i32 = undefined,

    inline fn BUFFER(handler: *Handler, x: i32, y: i32) i32 {
        _ = handler;
        _ = x;
        _ = y;
        @compileError("TODO: alloc/free pBuffer");
        // return handler.pBuffer[y * handler.cxBuffer + x];
    }

    pub fn OnCreate(self: *Handler, hwnd: HWND, _: *win32.CREATESTRUCT) LRESULT {
        _ = self;
        _ = hwnd;
    }
    pub fn OnSize(self: *Handler, _: HWND, _: u32, cxClient: i16, cyClient: i16) void {
        self.cxClient = cxClient;
        self.cyClient = cyClient;
    }
    pub fn OnSetFocus() void {}
    pub fn OnKillFocus() void {}
    pub fn OnKeyDown() void {}
    pub fn OnChar() void {}
    pub fn OnPaint(handler: *Handler, hwnd: HWND) void {
        var ps: win32.PAINTSTRUCT = undefined;
        const hdc: HDC = win32.BeginPaint(hwnd, &ps).?;
        defer _ = win32.EndPaint(hwnd, &ps);

        _ = windowsx.SelectFont(hdc, win32.CreateFont(0, 0, 0, 0, 0, 0, 0, 0, handler.dwCharSet, 0, 0, 0, win32.FIXED_PITCH, null));

        var y: i32 = 0;
        while (y < handler.cyBuffer) : (y += 1) {
            _ = win32.TextOut(hdc, 0, y * handler.cyChar, &BUFFER(0, y), handler.cxBuffer);
        }

        _ = windowsx.DeleteFont(windowsx.SelectFont(hdc, windowsx.GetStockFont(SYSTEM_FONT)));
    }
    pub fn OnDestroy(_: *Handler, hwnd: HWND) void {
        _ = hwnd;

        win32.PostQuitMessage(0);
    }
};

const WM_INPUTLANGCHANGE = win32.WM_INPUTLANGCHANGE;
const WM_CREATE = win32.WM_CREATE;
const WM_SIZE = win32.WM_SIZE;
const WM_SETFOCUS = win32.WM_SETFOCUS;
const WM_KILLFOCUS = win32.WM_KILLFOCUS;
const WM_KEYDOWN = win32.WM_KEYDOWN;
const WM_CHAR = win32.WM_CHAR;
const WM_PAINT = win32.WM_PAINT;
const WM_DESTROY = win32.WM_DESTROY;
const HANDLE_WM_INPUTLANGCHANGE = windowsx.WM_INPUTLANGCHANGE;
const HANDLE_WM_CREATE = windowsx.HANDLE_WM_CREATE;
const HANDLE_WM_SIZE = windowsx.HANDLE_WM_SIZE;
const HANDLE_WM_SETFOCUS = windowsx.HANDLE_WM_SETFOCUS;
const HANDLE_WM_KILLFOCUS = windowsx.HANDLE_WM_KILLFOCUS;
const HANDLE_WM_KEYDOWN = windowsx.HANDLE_WM_KEYDOWN;
const HANDLE_WM_CHAR = windowsx.HANDLE_WM_CHAR;
const HANDLE_WM_PAINT = windowsx.HANDLE_WM_PAINT;
const HANDLE_WM_DESTROY = windowsx.HANDLE_WM_DESTROY;

fn WndProc(
    hwnd: HWND,
    message: u32,
    wParam: WPARAM,
    lParam: LPARAM,
) callconv(WINAPI) LRESULT {
    const state = struct {
        var handler = Handler{};
    };

    return switch (message) {
        WM_CREATE => HANDLE_WM_CREATE(hwnd, wParam, lParam, Handler, &state.handler),
        WM_SIZE => HANDLE_WM_SIZE(hwnd, wParam, lParam, Handler, &state.handler),
        WM_SETFOCUS => HANDLE_WM_SETFOCUS(hwnd, wParam, lParam, Handler, &state.handler),
        WM_KILLFOCUS => HANDLE_WM_KILLFOCUS(hwnd, wParam, lParam, Handler, &state.handler),
        WM_KEYDOWN => HANDLE_WM_KEYDOWN(hwnd, wParam, lParam, Handler, &state.handler),
        WM_CHAR => HANDLE_WM_CHAR(hwnd, wParam, lParam, Handler, &state.handler),
        WM_PAINT => HANDLE_WM_PAINT(hwnd, wParam, lParam, Handler, &state.handler),
        WM_DESTROY => HANDLE_WM_DESTROY(hwnd, wParam, lParam, Handler, &state.handler),
        else => win32.DefWindowProc(hwnd, message, wParam, lParam),
    };
}
