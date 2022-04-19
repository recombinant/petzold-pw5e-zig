// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 8 - Connect
//
// The original source code copyright:
//
// --------------------------------------------------
//  CONNECT.C -- Connect-the-Dots Mouse Demo Program
//               (c) Charles Petzold, 1998
// --------------------------------------------------
pub const UNICODE = true;

const std = @import("std");

const WINAPI = std.os.windows.WINAPI;

const win32 = struct {
    usingnamespace @import("win32").zig;
    usingnamespace @import("win32").system.library_loader;
    usingnamespace @import("win32").foundation;
    usingnamespace @import("win32").ui.windows_and_messaging;
    usingnamespace @import("win32").graphics.gdi;
};
const BOOL = win32.BOOL;
const FALSE = win32.FALSE;
const TRUE = win32.TRUE;
const L = win32.L;
const HINSTANCE = win32.HINSTANCE;
const MSG = win32.MSG;
const HWND = win32.HWND;
const HDC = win32.HDC;
const LPARAM = win32.LPARAM;
const WPARAM = win32.WPARAM;
const LRESULT = win32.LRESULT;
const POINT = win32.POINT;
const CW_USEDEFAULT = win32.CW_USEDEFAULT;
const WS_OVERLAPPEDWINDOW = @enumToInt(win32.WS_OVERLAPPEDWINDOW);
const WS_SYSMENU = @enumToInt(win32.WS_SYSMENU);
const WS_VSCROLL = @enumToInt(win32.WS_VSCROLL);
const WS_HSCROLL = @enumToInt(win32.WS_HSCROLL);
const WM_LBUTTONDOWN = win32.WM_LBUTTONDOWN;
const WM_MOUSEMOVE = win32.WM_MOUSEMOVE;
const WM_LBUTTONUP = win32.WM_LBUTTONUP;
const WM_PAINT = win32.WM_PAINT;
const WM_DESTROY = win32.WM_DESTROY;
const SendMessage = win32.SendMessage;

const windowsx = @import("windowsx").windowsx;
const GetStockBrush = windowsx.GetStockBrush;
const HANDLE_WM_LBUTTONDOWN = windowsx.HANDLE_WM_LBUTTONDOWN;
const HANDLE_WM_MOUSEMOVE = windowsx.HANDLE_WM_MOUSEMOVE;
const HANDLE_WM_LBUTTONUP = windowsx.HANDLE_WM_LBUTTONUP;
const HANDLE_WM_PAINT = windowsx.HANDLE_WM_PAINT;
const HANDLE_WM_DESTROY = windowsx.HANDLE_WM_DESTROY;

pub export fn wWinMain(
    hInstance: HINSTANCE,
    _: ?HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
    _ = pCmdLine;

    const app_name = L("Connect");
    const wndclassex = win32.WNDCLASSEX{
        .cbSize = @sizeOf(win32.WNDCLASSEX),
        .style = win32.WNDCLASS_STYLES.initFlags(.{ .HREDRAW = 1, .VREDRAW = 1 }),
        .lpfnWndProc = WndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hInstance,
        .hIcon = @ptrCast(win32.HICON, win32.LoadImage(null, win32.IDI_APPLICATION, win32.IMAGE_ICON, 0, 0, win32.IMAGE_FLAGS.initFlags(.{ .SHARED = 1, .DEFAULTSIZE = 1 }))),
        .hCursor = @ptrCast(win32.HCURSOR, win32.LoadImage(null, win32.IDC_ARROW, win32.IMAGE_CURSOR, 0, 0, win32.IMAGE_FLAGS.initFlags(.{ .SHARED = 1, .DEFAULTSIZE = 1 }))),
        .hbrBackground = GetStockBrush(win32.WHITE_BRUSH),
        .lpszMenuName = null,
        .lpszClassName = app_name,
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

    const hwnd = win32.CreateWindowEx(
        // https://docs.microsoft.com/en-us/windows/win32/winmsg/extended-window-styles
        win32.WINDOW_EX_STYLE.initFlags(.{}),
        lpClassName,
        L("Connect-the-Points Mouse Demo"),
        @intToEnum(win32.WINDOW_STYLE, WS_OVERLAPPEDWINDOW | WS_SYSMENU | WS_VSCROLL | WS_HSCROLL),
        CW_USEDEFAULT, // initial x position
        CW_USEDEFAULT, // initial y position
        CW_USEDEFAULT, // initial x size
        CW_USEDEFAULT, // initial y size
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

const Handler = struct {
    const MAXPOINTS = 50;
    pt: [MAXPOINTS]POINT = undefined,
    iCount: usize = 0,

    pub fn OnLButtonDown(self: *Handler, hwnd: HWND, fDoubleClick: bool, _: i16, _: i16, _: u32) void {
        if (!fDoubleClick) {
            self.iCount = 0;
            _ = win32.InvalidateRect(hwnd, null, TRUE);
        }
    }

    pub fn OnMouseMove(self: *Handler, hwnd: HWND, x: i16, y: i16, keyFlags: u32) void {
        if ((keyFlags & win32.MK_LBUTTON) != 0 and self.iCount < MAXPOINTS) {
            // RIP Windows 98.
            // The original code relied on rapid mouse movement combined with
            // a slow processor giving a good pixel spacing.
            //
            // Modern machines are too quick. This code checks the gap between
            // pixels.
            const ok = if (self.iCount != 0) blk: {
                const pt = self.pt[self.iCount - 1];
                const dx = pt.x - x;
                const dy = pt.y - y;
                const gap = 70; // pixels
                break :blk ((dx * dx) + (dy * dy)) > (gap * gap);
            } else true;

            if (ok) {
                self.pt[self.iCount] = POINT{ .x = x, .y = y };

                self.iCount += 1;

                const hdc = win32.GetDC(hwnd);
                _ = win32.SetPixel(hdc, x, y, 0);
                _ = win32.ReleaseDC(hwnd, hdc);
            }
        }
    }

    pub fn OnLButtonUp(_: *Handler, hwnd: HWND, _: i16, _: i16, _: u32) void {
        _ = win32.InvalidateRect(hwnd, null, FALSE);
    }

    pub fn OnPaint(self: *Handler, hwnd: HWND) void {
        if (self.iCount == 0)
            return;

        var ps: win32.PAINTSTRUCT = undefined;
        const hdc: ?HDC = win32.BeginPaint(hwnd, &ps);
        defer {
            _ = win32.EndPaint(hwnd, &ps);
        }
        const cursor = win32.SetCursor(win32.LoadCursor(null, win32.IDC_WAIT));
        _ = win32.ShowCursor(TRUE);

        var i: usize = 0;
        while (i < self.iCount - 1) : (i += 1) {
            var j: usize = i + 1;
            while (j < self.iCount) : (j += 1) {
                _ = win32.MoveToEx(hdc, self.pt[i].x, self.pt[i].y, null);
                _ = win32.LineTo(hdc, self.pt[j].x, self.pt[j].y);
            }
        }

        _ = win32.ShowCursor(FALSE);
        _ = win32.SetCursor(cursor);
    }

    pub fn OnDestroy(_: *Handler, _: HWND) void {
        win32.PostQuitMessage(0);
    }
};

var handler = Handler{};

fn WndProc(
    hwnd: HWND,
    message: u32,
    wParam: WPARAM,
    lParam: LPARAM,
) callconv(WINAPI) LRESULT {
    return switch (message) {
        WM_LBUTTONDOWN => HANDLE_WM_LBUTTONDOWN(hwnd, wParam, lParam, Handler, &handler),
        WM_MOUSEMOVE => HANDLE_WM_MOUSEMOVE(hwnd, wParam, lParam, Handler, &handler),
        WM_LBUTTONUP => HANDLE_WM_LBUTTONUP(hwnd, wParam, lParam, Handler, &handler),
        WM_PAINT => HANDLE_WM_PAINT(hwnd, wParam, lParam, Handler, &handler),
        WM_DESTROY => HANDLE_WM_DESTROY(hwnd, wParam, lParam, Handler, &handler),
        else => win32.DefWindowProc(hwnd, message, wParam, lParam),
    };
}
