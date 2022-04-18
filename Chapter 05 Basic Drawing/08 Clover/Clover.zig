// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 5 - Clover
//
// The original source code copyright:
//
// --------------------------------------------------
//  CLOVER.C -- Clover Drawing Program Using Regions
//              (c) Charles Petzold, 1998
// --------------------------------------------------
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
const FALSE = win32.FALSE;
const L = win32.L;
const HINSTANCE = win32.HINSTANCE;
const MSG = win32.MSG;
const HWND = win32.HWND;
const HDC = win32.HDC;
const LPARAM = win32.LPARAM;
const WPARAM = win32.WPARAM;
const LRESULT = win32.LRESULT;
const HRGN = win32.HRGN;
const CW_USEDEFAULT = win32.CW_USEDEFAULT;
const WS_OVERLAPPEDWINDOW = @enumToInt(win32.WS_OVERLAPPEDWINDOW);
const WS_SYSMENU = @enumToInt(win32.WS_SYSMENU);
const WM_SIZE = win32.WM_SIZE;
const WM_PAINT = win32.WM_PAINT;
const WM_DESTROY = win32.WM_DESTROY;

const windowsx = @import("windowsx").windowsx;
const GetStockBrush = windowsx.GetStockBrush;
const SelectBrush = windowsx.SelectBrush;
const HANDLE_WM_SIZE = windowsx.HANDLE_WM_SIZE;
const HANDLE_WM_PAINT = windowsx.HANDLE_WM_PAINT;
const HANDLE_WM_DESTROY = windowsx.HANDLE_WM_DESTROY;

pub export fn wWinMain(
    hInstance: HINSTANCE,
    _: ?HINSTANCE,
    _: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
    const app_name = L("Clover");
    const wndclassex = win32.WNDCLASSEX{
        .cbSize = @sizeOf(win32.WNDCLASSEX),
        .style = win32.WNDCLASS_STYLES.initFlags(.{ .HREDRAW = 1, .VREDRAW = 1 }),
        .lpfnWndProc = WndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hInstance,
        .hIcon = win32.LoadIcon(null, win32.IDI_APPLICATION),
        .hCursor = win32.LoadCursor(null, win32.IDC_ARROW),
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
        L("Draw a Clover"),
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

const Handler = struct {
    hRgnClip: ?HRGN = null,
    cxClient: i32 = undefined,
    cyClient: i32 = undefined,

    pub fn OnSize(self: *Handler, _: HWND, _: u32, cx: i16, cy: i16) void {
        self.cxClient = cx;
        self.cyClient = cy;

        const hCursor = win32.SetCursor(win32.LoadCursor(null, win32.IDC_WAIT));
        _ = win32.ShowCursor(TRUE);

        if (self.hRgnClip) |hRgn|
            _ = win32.DeleteObject(hRgn);

        const hRgnTemp = [6]?HRGN{
            win32.CreateEllipticRgn(
                0,
                @divTrunc(self.cyClient, 3),
                @divTrunc(self.cxClient, 2),
                @divTrunc(2 * self.cyClient, 3),
            ),
            win32.CreateEllipticRgn(
                @divTrunc(self.cxClient, 2),
                @divTrunc(self.cyClient, 3),
                self.cxClient,
                @divTrunc(2 * self.cyClient, 3),
            ),
            win32.CreateEllipticRgn(
                @divTrunc(self.cxClient, 3),
                0,
                @divTrunc(2 * self.cxClient, 3),
                @divTrunc(self.cyClient, 2),
            ),
            win32.CreateEllipticRgn(
                @divTrunc(self.cxClient, 3),
                @divTrunc(self.cyClient, 2),
                @divTrunc(2 * self.cxClient, 3),
                self.cyClient,
            ),
            win32.CreateRectRgn(0, 0, 1, 1),
            win32.CreateRectRgn(0, 0, 1, 1),
        };
        self.hRgnClip = win32.CreateRectRgn(0, 0, 1, 1);

        _ = win32.CombineRgn(hRgnTemp[4], hRgnTemp[0], hRgnTemp[1], win32.RGN_OR);
        _ = win32.CombineRgn(hRgnTemp[5], hRgnTemp[2], hRgnTemp[3], win32.RGN_OR);
        _ = win32.CombineRgn(self.hRgnClip, hRgnTemp[4], hRgnTemp[5], win32.RGN_XOR);

        for (hRgnTemp) |hRgn|
            _ = win32.DeleteObject(hRgn);

        _ = win32.SetCursor(hCursor);
        _ = win32.ShowCursor(FALSE);
    }

    pub fn OnPaint(self: *Handler, hwnd: HWND) void {
        var ps: win32.PAINTSTRUCT = undefined;
        const hdc = win32.BeginPaint(hwnd, &ps);
        defer _ = win32.EndPaint(hwnd, &ps);

        _ = win32.SetViewportOrgEx(hdc, @divTrunc(self.cxClient, 2), @divTrunc(self.cyClient, 2), null);
        _ = win32.SelectClipRgn(hdc, self.hRgnClip);

        const fRadius = std.math.hypot(f32, @intToFloat(f32, self.cxClient) / 2.0, @intToFloat(f32, self.cyClient) / 2.0);
        var fAngle: f32 = 0.0;
        const inc = 2.0 * std.math.pi / 360.0;
        while (fAngle < 2 * std.math.pi) : (fAngle += inc) {
            _ = win32.MoveToEx(hdc, 0, 0, null);
            _ = win32.LineTo(
                hdc,
                @floatToInt(i32, fRadius * std.math.cos(fAngle) + 0.5),
                @floatToInt(i32, -fRadius * std.math.sin(fAngle) + 0.5),
            );
        }
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
        else => win32.DefWindowProc(hwnd, message, wParam, lParam),
    };
}
