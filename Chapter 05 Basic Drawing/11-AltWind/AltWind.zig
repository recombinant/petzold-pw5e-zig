// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 5 - AltWind
//
// The original source code copyright:
//
// -----------------------------------------------
// ALTWIND.C -- Alternate and Winding Fill Modes
// (c) Charles Petzold, 1998
// -----------------------------------------------
const std = @import("std");

pub const UNICODE = true; // used by zigwin32
const win32 = @import("win32").everything;

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

const windowsx = @import("windowsx");
const GetStockBrush = windowsx.GetStockBrush;
const SelectBrush = windowsx.SelectBrush;

pub export fn wWinMain(
    hInstance: HINSTANCE,
    _: ?HINSTANCE,
    _: [*:0]u16,
    nCmdShow: u32,
) callconv(.winapi) c_int {
    const app_name = L("AltWind");
    const wndclassex: win32.WNDCLASSEXW = .{
        .cbSize = @sizeOf(win32.WNDCLASSEXW),
        .style = win32.WNDCLASS_STYLES{ .HREDRAW = 1, .VREDRAW = 1 },
        .lpfnWndProc = WndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hInstance,
        .hIcon = @ptrCast(win32.LoadImageW(null, win32.IDI_APPLICATION, win32.IMAGE_ICON, 0, 0, win32.IMAGE_FLAGS{ .SHARED = 1, .DEFAULTSIZE = 1 })),
        .hCursor = @ptrCast(win32.LoadImageW(null, win32.IDC_ARROW, win32.IMAGE_CURSOR, 0, 0, win32.IMAGE_FLAGS{ .SHARED = 1, .DEFAULTSIZE = 1 })),
        .hbrBackground = GetStockBrush(win32.WHITE_BRUSH),
        .lpszMenuName = null,
        .lpszClassName = app_name,
        .hIconSm = null,
    };

    const atom: u16 = win32.RegisterClassExW(&wndclassex);
    if (0 == atom) {
        std.log.err("failed RegisterClassEx()", .{});
        return 0; // premature exit
    }

    // If a memory align panic occurs with CreateWindowExW() lpClassName then look at:
    // https://github.com/marlersoft/zigwin32gen/issues/9

    const hwnd = win32.CreateWindowExW(
        // https://docs.microsoft.com/en-us/windows/win32/winmsg/extended-window-styles
        win32.WINDOW_EX_STYLE{},
        @ptrFromInt(atom),
        L("Alternate and Winding Fill Modes"),
        win32.WS_OVERLAPPEDWINDOW,
        win32.CW_USEDEFAULT, // initial x position
        win32.CW_USEDEFAULT, // initial y position
        win32.CW_USEDEFAULT, // initial x size
        win32.CW_USEDEFAULT, // initial y size
        null, // parent window handle
        null, // window menu handle
        win32.GetModuleHandleW(null),
        null,
    );

    if (null == hwnd) {
        std.log.err("failed CreateWindowEx(), error {t}", .{win32.GetLastError()});
        return 0; // premature exit
    }

    _ = win32.ShowWindow(hwnd, @bitCast(nCmdShow));
    if (0 == win32.UpdateWindow(hwnd)) {
        std.log.err("failed UpdateWindow()", .{});
        return 0; // premature exit
    }

    var msg: MSG = undefined;
    var ret: BOOL = win32.GetMessageW(&msg, null, 0, 0); // three states: -1, 0 or non-zero

    while (0 != ret) {
        if (-1 == ret) {
            // handle the error and/or exit
            // for error call GetLastError();
            std.log.err("failed message loop, error {t}", .{win32.GetLastError()});
            return 0;
        } else {
            _ = win32.TranslateMessage(&msg);
            _ = win32.DispatchMessageW(&msg);
        }
        ret = win32.GetMessageW(&msg, null, 0, 0);
    }

    // Normal exit
    return @bitCast(@as(c_uint, @truncate(msg.wParam))); // WM_QUIT
}

const Handler = struct {
    const aptFigure: [10]POINT = .{
        .{ .x = 10, .y = 70 },
        .{ .x = 50, .y = 70 },
        .{ .x = 50, .y = 10 },
        .{ .x = 90, .y = 10 },
        .{ .x = 90, .y = 50 },
        .{ .x = 30, .y = 50 },
        .{ .x = 30, .y = 90 },
        .{ .x = 70, .y = 90 },
        .{ .x = 70, .y = 30 },
        .{ .x = 10, .y = 30 },
    };
    cxClient: i32 = undefined,
    cyClient: i32 = undefined,

    pub fn OnSize(self: *Handler, _: HWND, _: u32, cx: i16, cy: i16) void {
        self.cxClient = cx;
        self.cyClient = cy;
    }

    pub fn OnPaint(self: *Handler, hwnd: HWND) void {
        var ps: win32.PAINTSTRUCT = undefined;

        const hdc: HDC = win32.BeginPaint(hwnd, &ps).?;
        defer _ = win32.EndPaint(hwnd, &ps);

        _ = SelectBrush(hdc, GetStockBrush(win32.GRAY_BRUSH));

        var apt: [aptFigure.len]POINT = undefined;

        for (&apt, aptFigure) |*pt, ptFigure|
            pt.* = POINT{
                .x = @divTrunc(self.cxClient * ptFigure.x, 200),
                .y = @divTrunc(self.cyClient * ptFigure.y, 100),
            };

        _ = win32.SetPolyFillMode(hdc, win32.ALTERNATE);
        _ = win32.Polygon(hdc, &apt, 10);

        for (&apt) |*pt|
            pt.x += @divTrunc(self.cxClient, 2);

        _ = win32.SetPolyFillMode(hdc, win32.WINDING);
        _ = win32.Polygon(hdc, &apt, 10);
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

fn WndProc(hwnd: HWND, message: u32, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT {
    const state = struct {
        var handler: Handler = .{};
    };

    return switch (message) {
        WM_SIZE => HANDLE_WM_SIZE(hwnd, wParam, lParam, Handler, &state.handler),
        WM_PAINT => HANDLE_WM_PAINT(hwnd, wParam, lParam, Handler, &state.handler),
        WM_DESTROY => HANDLE_WM_DESTROY(hwnd, wParam, lParam, Handler, &state.handler),
        else => win32.DefWindowProcW(hwnd, message, wParam, lParam),
    };
}
