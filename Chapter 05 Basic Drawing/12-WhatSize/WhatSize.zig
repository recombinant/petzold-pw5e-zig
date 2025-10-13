// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 5 - WhatSize
//
// The original source code copyright:
//
// -----------------------------------------
// WHATSIZE.C -- What Size is the Window?
//               (c) Charles Petzold, 1998
// -----------------------------------------
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
const GetStockFont = windowsx.GetStockFont;
const SelectFont = windowsx.SelectFont;

pub export fn wWinMain(
    hInstance: HINSTANCE,
    _: ?HINSTANCE,
    _: [*:0]u16,
    nCmdShow: u32,
) callconv(.winapi) c_int {
    const app_name = L("WhatSize");
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
        L("What Size is the Window?"),
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

fn Show(hwnd: HWND, hdc: ?HDC, xText: i32, yText: i32, iMapMode: win32.HDC_MAP_MODE, szMapMode: []const u8) void {
    var rect: win32.RECT = undefined;
    {
        _ = win32.SaveDC(hdc);
        defer _ = win32.RestoreDC(hdc, -1);

        _ = win32.SetMapMode(hdc, iMapMode);
        _ = win32.GetClientRect(hwnd, &rect);
        _ = win32.DPtoLP(hdc, @ptrCast(&rect), 2);
    }

    const length = 20 + 8 * 4;
    var buffer1: [length]u8 = undefined;
    // TODO: format signed positive numbers without the leading + symbol
    const slice1 = std.fmt.bufPrint(buffer1[0..], "{s:<20} {d:7} {d:7} {d:7} {d:7}", .{ szMapMode, rect.left, rect.right, rect.top, rect.bottom }) catch unreachable;

    var buffer2: [length]u16 = undefined;
    const len2: i32 = @intCast(std.unicode.utf8ToUtf16Le(buffer2[0..], slice1) catch unreachable);

    _ = win32.TextOutW(hdc, xText, yText, @ptrCast(&buffer2), len2);
}

const Handler = struct {
    cxChar: i32 = undefined,
    cyChar: i32 = undefined,

    pub fn OnCreate(self: *Handler, hwnd: HWND, _: *win32.CREATESTRUCTW) LRESULT {
        const hdc = win32.GetDC(hwnd);
        defer _ = win32.ReleaseDC(hwnd, hdc);
        _ = SelectFont(hdc, GetStockFont(win32.SYSTEM_FIXED_FONT));

        var tm: win32.TEXTMETRICW = undefined;
        _ = win32.GetTextMetricsW(hdc, &tm);
        self.cxChar = tm.tmAveCharWidth;
        self.cyChar = tm.tmHeight + tm.tmExternalLeading;

        return 0;
    }

    pub fn OnPaint(self: *Handler, hwnd: HWND) void {
        var ps: win32.PAINTSTRUCT = undefined;

        const hdc = win32.BeginPaint(hwnd, &ps);
        defer _ = win32.EndPaint(hwnd, &ps);

        _ = SelectFont(hdc, GetStockFont(win32.SYSTEM_FIXED_FONT));

        _ = win32.SetMapMode(hdc, win32.MM_ANISOTROPIC);
        _ = win32.SetWindowExtEx(hdc, 1, 1, null);
        _ = win32.SetViewportExtEx(hdc, self.cxChar, self.cyChar, null);

        const szHeading = L("Mapping Mode            Left   Right     Top  Bottom");
        const szUndLine = L("------------            ----   -----     ---  ------");

        _ = win32.TextOutW(hdc, 1, 1, szHeading, szHeading.len);
        _ = win32.TextOutW(hdc, 1, 2, szUndLine, szUndLine.len);

        Show(hwnd, hdc, 1, 3, win32.MM_TEXT, "TEXT (pixels)");
        Show(hwnd, hdc, 1, 4, win32.MM_LOMETRIC, "LOMETRIC (.1 mm)");
        Show(hwnd, hdc, 1, 5, win32.MM_HIMETRIC, "HIMETRIC (.01 mm)");
        Show(hwnd, hdc, 1, 6, win32.MM_LOENGLISH, "LOENGLISH (.01 in)");
        Show(hwnd, hdc, 1, 7, win32.MM_HIENGLISH, "HIENGLISH (.001 in)");
        Show(hwnd, hdc, 1, 8, win32.MM_TWIPS, "TWIPS (1/1440 in)");
    }

    pub fn OnDestroy(_: *Handler, _: HWND) void {
        win32.PostQuitMessage(0);
    }
};

const WM_CREATE = win32.WM_CREATE;
const WM_PAINT = win32.WM_PAINT;
const WM_DESTROY = win32.WM_DESTROY;
const HANDLE_WM_CREATE = windowsx.HANDLE_WM_CREATE;
const HANDLE_WM_PAINT = windowsx.HANDLE_WM_PAINT;
const HANDLE_WM_DESTROY = windowsx.HANDLE_WM_DESTROY;

fn WndProc(hwnd: HWND, message: u32, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT {
    const state = struct {
        var handler: Handler = .{};
    };

    return switch (message) {
        WM_CREATE => HANDLE_WM_CREATE(hwnd, wParam, lParam, Handler, &state.handler),
        WM_PAINT => HANDLE_WM_PAINT(hwnd, wParam, lParam, Handler, &state.handler),
        WM_DESTROY => HANDLE_WM_DESTROY(hwnd, wParam, lParam, Handler, &state.handler),
        else => win32.DefWindowProcW(hwnd, message, wParam, lParam),
    };
}
