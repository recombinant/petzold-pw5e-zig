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
const LPARAM = win32.LPARAM;
const WPARAM = win32.WPARAM;
const LRESULT = win32.LRESULT;
const HRGN = win32.HRGN;

const windowsx = @import("windowsx");
const GetStockBrush = windowsx.GetStockBrush;

pub export fn wWinMain(
    hInstance: HINSTANCE,
    _: ?HINSTANCE,
    _: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
    const app_name = L("Clover");
    const wndclassex = win32.WNDCLASSEX{
        .cbSize = @sizeOf(win32.WNDCLASSEX),
        .style = win32.WNDCLASS_STYLES{ .HREDRAW = 1, .VREDRAW = 1 },
        .lpfnWndProc = WndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hInstance,
        .hIcon = @ptrCast(win32.LoadImage(null, win32.IDI_APPLICATION, win32.IMAGE_ICON, 0, 0, win32.IMAGE_FLAGS{ .SHARED = 1, .DEFAULTSIZE = 1 })),
        .hCursor = @ptrCast(win32.LoadImage(null, win32.IDC_ARROW, win32.IMAGE_CURSOR, 0, 0, win32.IMAGE_FLAGS{ .SHARED = 1, .DEFAULTSIZE = 1 })),
        .hbrBackground = GetStockBrush(win32.WHITE_BRUSH),
        .lpszMenuName = null,
        .lpszClassName = app_name,
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
        L("Draw a Clover"),
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

    var msg: MSG = undefined;
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
    hRgnClip: ?HRGN = null,
    cxClient: i32 = undefined,
    cyClient: i32 = undefined,

    pub fn OnSize(self: *Handler, _: HWND, _: u32, cx: i16, cy: i16) void {
        self.cxClient = cx;
        self.cyClient = cy;

        const waitCursor: win32.HCURSOR = @ptrCast(win32.LoadImage(
            null,
            win32.IDC_WAIT,
            win32.IMAGE_CURSOR,
            0,
            0,
            win32.IMAGE_FLAGS{ .SHARED = 1, .DEFAULTSIZE = 1 },
        ));

        const previousCursor = win32.SetCursor(waitCursor);
        defer _ = win32.SetCursor(previousCursor);

        _ = win32.ShowCursor(TRUE);
        defer _ = win32.ShowCursor(FALSE);

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

        for (hRgnTemp) |optional| {
            if (optional) |hRgn| {
                _ = win32.DeleteObject(hRgn);
            }
        }
    }

    pub fn OnPaint(self: *Handler, hwnd: HWND) void {
        var ps: win32.PAINTSTRUCT = undefined;
        const hdc = win32.BeginPaint(hwnd, &ps);
        defer _ = win32.EndPaint(hwnd, &ps);

        _ = win32.SetViewportOrgEx(hdc, @divTrunc(self.cxClient, 2), @divTrunc(self.cyClient, 2), null);
        _ = win32.SelectClipRgn(hdc, self.hRgnClip);

        const fRadius = std.math.hypot(@as(f32, @floatFromInt(self.cxClient)) / 2.0, @as(f32, @floatFromInt(self.cyClient)) / 2.0);
        var fAngle: f32 = 0.0;
        const inc = 2.0 * std.math.pi / 360.0;
        while (fAngle < 2 * std.math.pi) : (fAngle += inc) {
            _ = win32.MoveToEx(hdc, 0, 0, null);
            _ = win32.LineTo(
                hdc,
                @intFromFloat(fRadius * @cos(fAngle) + 0.5),
                @intFromFloat(-fRadius * @sin(fAngle) + 0.5),
            );
        }
    }

    pub fn OnDestroy(_: *Handler, _: HWND) void {
        win32.PostQuitMessage(0);
    }
};

const WM_SIZE = win32.WM_SIZE;
const WM_PAINT = win32.WM_PAINT;
const WM_DESTROY = win32.WM_DESTROY;
const HANDLE_WM_SIZE = windowsx.HANDLE_WM_SIZE;
const HANDLE_WM_PAINT = windowsx.HANDLE_WM_PAINT;
const HANDLE_WM_DESTROY = windowsx.HANDLE_WM_DESTROY;

fn WndProc(hwnd: HWND, message: u32, wParam: WPARAM, lParam: LPARAM) callconv(WINAPI) LRESULT {
    const state = struct {
        var handler = Handler{};
    };

    return switch (message) {
        WM_SIZE => HANDLE_WM_SIZE(hwnd, wParam, lParam, Handler, &state.handler),
        WM_PAINT => HANDLE_WM_PAINT(hwnd, wParam, lParam, Handler, &state.handler),
        WM_DESTROY => HANDLE_WM_DESTROY(hwnd, wParam, lParam, Handler, &state.handler),
        else => win32.DefWindowProc(hwnd, message, wParam, lParam),
    };
}
