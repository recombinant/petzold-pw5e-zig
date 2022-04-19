// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 5 - Bezier
//
// The original source code copyright:
//
// ---------------------------------------
//  BEZIER.C -- Bezier Splines Demo
//              (c) Charles Petzold, 1998
// ---------------------------------------
pub const UNICODE = true;

const std = @import("std");

const WINAPI = std.os.windows.WINAPI;

const win32 = struct {
    usingnamespace @import("win32").zig;
    usingnamespace @import("win32").system.library_loader;
    usingnamespace @import("win32").foundation;
    usingnamespace @import("win32").system.system_services;
    usingnamespace @import("win32").ui.windows_and_messaging;
    usingnamespace @import("win32").graphics.gdi;
};
const BOOL = win32.BOOL;
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
const MK_LBUTTON = win32.MK_LBUTTON;
const MK_RBUTTON = win32.MK_RBUTTON;
const WM_SIZE = win32.WM_SIZE;
const WM_PAINT = win32.WM_PAINT;
const WM_DESTROY = win32.WM_DESTROY;
const WM_MOUSEMOVE = win32.WM_MOUSEMOVE;
const WM_LBUTTONDOWN = win32.WM_LBUTTONDOWN;
const WM_RBUTTONDOWN = win32.WM_RBUTTONDOWN;

const windowsx = @import("windowsx").windowsx;
const GetStockBrush = windowsx.GetStockBrush;
const GetStockPen = windowsx.GetStockPen;
const SelectPen = windowsx.SelectPen;
const HANDLE_WM_SIZE = windowsx.HANDLE_WM_SIZE;
const HANDLE_WM_PAINT = windowsx.HANDLE_WM_PAINT;
const HANDLE_WM_DESTROY = windowsx.HANDLE_WM_DESTROY;
const HANDLE_WM_MOUSEMOVE = windowsx.HANDLE_WM_MOUSEMOVE;
const HANDLE_WM_LBUTTONDOWN = windowsx.HANDLE_WM_LBUTTONDOWN;
const HANDLE_WM_RBUTTONDOWN = windowsx.HANDLE_WM_RBUTTONDOWN;

pub export fn wWinMain(
    hInstance: HINSTANCE,
    _: ?HINSTANCE,
    _: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
    const app_name = L("Bezier");
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
        L("Bezier Splines"),
        @intToEnum(win32.WINDOW_STYLE, WS_OVERLAPPEDWINDOW | WS_SYSMENU),
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

    var msg: MSG = undefined;
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

fn DrawBezier(hdc: ?HDC, apt: [4]POINT) void {
    _ = win32.PolyBezier(hdc, &apt, 4);

    _ = win32.MoveToEx(hdc, apt[0].x, apt[0].y, null);
    _ = win32.LineTo(hdc, apt[1].x, apt[1].y);

    _ = win32.MoveToEx(hdc, apt[2].x, apt[2].y, null);
    _ = win32.LineTo(hdc, apt[3].x, apt[3].y);
}

const Handler = struct {
    apt: [4]POINT = undefined,

    pub fn OnSize(self: *Handler, _: HWND, _: u32, client_width: i16, client_height: i16) void {
        self.apt = .{
            .{ .x = @divTrunc(client_width, 4), .y = @divTrunc(client_height, 2) },
            .{ .x = @divTrunc(client_width, 2), .y = @divTrunc(client_height, 4) },
            .{ .x = @divTrunc(client_width, 2), .y = @divTrunc(3 * client_height, 4) },
            .{ .x = @divTrunc(3 * client_width, 4), .y = @divTrunc(client_height, 2) },
        };
    }

    // OnLButtonDown & OnRButtonDown are here...
    pub fn OnMouseMove(self: *Handler, hwnd: HWND, x: i16, y: i16, keyFlags: u32) void {
        if (keyFlags & MK_LBUTTON != 0 or keyFlags & MK_RBUTTON != 0) {
            const hdc = win32.GetDC(hwnd);
            defer _ = win32.ReleaseDC(hwnd, hdc);

            const original = SelectPen(hdc, GetStockPen(win32.WHITE_PEN));
            DrawBezier(hdc, self.apt);

            if (keyFlags & MK_LBUTTON != 0)
                self.apt[1] = .{ .x = x, .y = y };

            if (keyFlags & MK_RBUTTON != 0)
                self.apt[2] = .{ .x = x, .y = y };

            _ = SelectPen(hdc, original);
            DrawBezier(hdc, self.apt);
        }
    }

    pub fn OnPaint(self: *Handler, hwnd: HWND) void {
        _ = win32.InvalidateRect(hwnd, null, TRUE);

        var ps: win32.PAINTSTRUCT = undefined;

        const hdc: HDC = win32.BeginPaint(hwnd, &ps).?;
        defer _ = win32.EndPaint(hwnd, &ps);

        DrawBezier(hdc, self.apt);
    }

    pub fn OnDestroy(_: *Handler, _: HWND) void {
        win32.PostQuitMessage(0);
    }
};

var handler = Handler{};

fn WndProc(hwnd: HWND, message: u32, wParam: WPARAM, lParam: LPARAM) callconv(WINAPI) LRESULT {
    return switch (message) {
        WM_SIZE => HANDLE_WM_SIZE(hwnd, wParam, lParam, Handler, &handler),
        WM_PAINT => HANDLE_WM_PAINT(hwnd, wParam, lParam, Handler, &handler),
        WM_DESTROY => HANDLE_WM_DESTROY(hwnd, wParam, lParam, Handler, &handler),
        WM_MOUSEMOVE, WM_LBUTTONDOWN, WM_RBUTTONDOWN => HANDLE_WM_MOUSEMOVE(hwnd, wParam, lParam, Handler, &handler),
        else => win32.DefWindowProc(hwnd, message, wParam, lParam),
    };
}
