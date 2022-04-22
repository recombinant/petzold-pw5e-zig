// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 8 - DigClock
//
// The original source code copyright:
//
// -----------------------------------------
//  DIGCLOCK.c -- Digital Clock
//                (c) Charles Petzold, 1998
// -----------------------------------------
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

    const szAppName = L("DigClock");

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

    const hwnd = win32.CreateWindowEx(
        // https://docs.microsoft.com/en-us/windows/win32/winmsg/extended-window-styles
        win32.WINDOW_EX_STYLE.initFlags(.{}),
        lpClassName,
        L("Digital Clock"),
        win32.WINDOW_STYLE.initFlags(.{
            .TILEDWINDOW = 1, // .OVERLAPPEDWINDOW equivalent
        }),
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

fn DisplayDigit(hdc: ?HDC, iNumber: usize) void {
    const fSevenSegment: [10][7]bool = [_][7]bool{
        [_]bool{ true, true, true, false, true, true, true }, // 0
        [_]bool{ false, false, true, false, false, true, false }, // 1
        [_]bool{ true, false, true, true, true, false, true }, // 2
        [_]bool{ true, false, true, true, false, true, true }, // 3
        [_]bool{ false, true, true, true, false, true, false }, // 4
        [_]bool{ true, true, false, true, false, true, true }, // 5
        [_]bool{ true, true, false, true, true, true, true }, // 6
        [_]bool{ true, false, true, false, false, true, false }, // 7
        [_]bool{ true, true, true, true, true, true, true }, // 8
        [_]bool{ true, true, true, true, false, true, true }, // 9
    };
    const ptSegment: [7][6]POINT = [_][6]POINT{
        [_]POINT{ POINT{ .x = 7, .y = 6 }, POINT{ .x = 11, .y = 2 }, POINT{ .x = 31, .y = 2 }, POINT{ .x = 35, .y = 6 }, POINT{ .x = 31, .y = 10 }, POINT{ .x = 11, .y = 10 } },
        [_]POINT{ POINT{ .x = 6, .y = 7 }, POINT{ .x = 10, .y = 11 }, POINT{ .x = 10, .y = 31 }, POINT{ .x = 6, .y = 35 }, POINT{ .x = 2, .y = 31 }, POINT{ .x = 2, .y = 11 } },
        [_]POINT{ POINT{ .x = 36, .y = 7 }, POINT{ .x = 40, .y = 11 }, POINT{ .x = 40, .y = 31 }, POINT{ .x = 36, .y = 35 }, POINT{ .x = 32, .y = 31 }, POINT{ .x = 32, .y = 11 } },
        [_]POINT{ POINT{ .x = 7, .y = 36 }, POINT{ .x = 11, .y = 32 }, POINT{ .x = 31, .y = 32 }, POINT{ .x = 35, .y = 36 }, POINT{ .x = 31, .y = 40 }, POINT{ .x = 11, .y = 40 } },
        [_]POINT{ POINT{ .x = 6, .y = 37 }, POINT{ .x = 10, .y = 41 }, POINT{ .x = 10, .y = 61 }, POINT{ .x = 6, .y = 65 }, POINT{ .x = 2, .y = 61 }, POINT{ .x = 2, .y = 41 } },
        [_]POINT{ POINT{ .x = 36, .y = 37 }, POINT{ .x = 40, .y = 41 }, POINT{ .x = 40, .y = 61 }, POINT{ .x = 36, .y = 65 }, POINT{ .x = 32, .y = 61 }, POINT{ .x = 32, .y = 41 } },
        [_]POINT{ POINT{ .x = 7, .y = 66 }, POINT{ .x = 11, .y = 62 }, POINT{ .x = 31, .y = 62 }, POINT{ .x = 35, .y = 66 }, POINT{ .x = 31, .y = 70 }, POINT{ .x = 11, .y = 70 } },
    };

    var iSeg: usize = 0;
    while (iSeg < fSevenSegment[iNumber].len) : (iSeg += 1) {
        if (fSevenSegment[iNumber][iSeg])
            _ = win32.Polygon(hdc, &ptSegment[iSeg], ptSegment[iSeg].len);
    }
}

fn DisplayTwoDigits(hdc: ?HDC, iNumber: usize, fSuppress: bool) void {
    if (!fSuppress or (@divTrunc(iNumber, 10) != 0))
        DisplayDigit(hdc, @divTrunc(iNumber, 10));

    _ = win32.OffsetWindowOrgEx(hdc, -42, 0, null);
    DisplayDigit(hdc, @mod(iNumber, 10));
    _ = win32.OffsetWindowOrgEx(hdc, -42, 0, null);
}

fn DisplayColon(hdc: ?HDC) void {
    const ptColon: [2][4]POINT = [_][4]POINT{
        [_]POINT{ POINT{ .x = 2, .y = 21 }, POINT{ .x = 6, .y = 17 }, POINT{ .x = 10, .y = 21 }, POINT{ .x = 6, .y = 25 } },
        [_]POINT{ POINT{ .x = 2, .y = 51 }, POINT{ .x = 6, .y = 47 }, POINT{ .x = 10, .y = 51 }, POINT{ .x = 6, .y = 55 } },
    };

    _ = win32.Polygon(hdc, &ptColon[0], 4);
    _ = win32.Polygon(hdc, &ptColon[1], 4);

    _ = win32.OffsetWindowOrgEx(hdc, -12, 0, null);
}

fn DisplayTime(hdc: ?HDC, f24Hour: bool, fSuppress: bool) void {
    var st: win32.SYSTEMTIME = undefined;
    _ = win32.GetLocalTime(&st);

    if (f24Hour) {
        DisplayTwoDigits(hdc, st.wHour, fSuppress);
    } else {
        st.wHour = @mod(st.wHour, 12);
        DisplayTwoDigits(hdc, if (st.wHour != 0) st.wHour else 12, fSuppress);
    }

    DisplayColon(hdc);
    DisplayTwoDigits(hdc, st.wMinute, false);
    DisplayColon(hdc);
    DisplayTwoDigits(hdc, st.wSecond, false);
}

const Handler = struct {
    const ID_TIMER = 1;
    f24Hour: bool = true,
    fSuppress: bool = false, // suppress hour leading zero
    hBrushRed: ?win32.HBRUSH = undefined,
    cxClient: i32 = undefined,
    cyClient: i32 = undefined,

    fn locale(self: *Handler, hwnd: HWND) void {
        var szBuffer: [2]TCHAR = undefined;
        const localeName = windowsx.LOCALE_NAME_USER_DEFAULT;
        // const localeName = L("en-US");

        _ = win32.GetLocaleInfoEx(localeName, win32.LOCALE_ITIME, &szBuffer, szBuffer.len);
        self.f24Hour = (szBuffer[0] == '1');

        _ = win32.GetLocaleInfoEx(localeName, win32.LOCALE_ITLZERO, &szBuffer, szBuffer.len);
        self.fSuppress = (szBuffer[0] == '0');

        _ = win32.InvalidateRect(hwnd, null, TRUE);
    }
    pub fn OnCreate(self: *Handler, hwnd: HWND, _: *win32.CREATESTRUCT) LRESULT {
        self.hBrushRed = win32.CreateSolidBrush(windowsx.RGB(255, 0, 0));
        _ = win32.SetTimer(hwnd, ID_TIMER, 1000, null);

        self.locale(hwnd);
        return 0;
    }
    pub fn OnSettingChange(self: *Handler, hwnd: HWND, _: win32.SYSTEM_PARAMETERS_INFO_ACTION, _: ?[*:0]const TCHAR) void {
        self.locale(hwnd);
    }
    pub fn OnSize(self: *Handler, _: HWND, _: u32, cxClient: i16, cyClient: i16) void {
        self.cxClient = cxClient;
        self.cyClient = cyClient;
    }
    pub fn OnTimer(_: *Handler, hwnd: HWND, _: usize) void {
        _ = win32.InvalidateRect(hwnd, null, TRUE);
    }
    pub fn OnPaint(self: *Handler, hwnd: HWND) void {
        var ps: win32.PAINTSTRUCT = undefined;
        const hdc: ?HDC = win32.BeginPaint(hwnd, &ps);
        defer _ = win32.EndPaint(hwnd, &ps);

        _ = win32.SetMapMode(hdc, win32.MM_ISOTROPIC);
        _ = win32.SetWindowExtEx(hdc, 276, 72, null);
        _ = win32.SetViewportExtEx(hdc, self.cxClient, self.cyClient, null);
        _ = win32.SetWindowOrgEx(hdc, 138, 36, null);
        _ = win32.SetViewportOrgEx(hdc, @divTrunc(self.cxClient, 2), @divTrunc(self.cyClient, 2), null);

        _ = windowsx.SelectPen(hdc, windowsx.GetStockPen(win32.NULL_PEN));
        _ = windowsx.SelectBrush(hdc, self.hBrushRed);

        DisplayTime(hdc, self.f24Hour, self.fSuppress);
    }
    pub fn OnDestroy(self: *Handler, hwnd: HWND) void {
        _ = win32.KillTimer(hwnd, ID_TIMER);
        _ = windowsx.DeleteBrush(self.hBrushRed);
        win32.PostQuitMessage(0);
    }
};

var handler = Handler{};

const WM_CREATE = win32.WM_CREATE;
const WM_SETTINGCHANGE = win32.WM_SETTINGCHANGE;
const WM_SIZE = win32.WM_SIZE;
const WM_TIMER = win32.WM_TIMER;
const WM_PAINT = win32.WM_PAINT;
const WM_DESTROY = win32.WM_DESTROY;
const HANDLE_WM_CREATE = windowsx.HANDLE_WM_CREATE;
const HANDLE_WM_SETTINGCHANGE = windowsx.HANDLE_WM_SETTINGCHANGE;
const HANDLE_WM_SIZE = windowsx.HANDLE_WM_SIZE;
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
        WM_SETTINGCHANGE => HANDLE_WM_SETTINGCHANGE(hwnd, wParam, lParam, Handler, &handler),
        WM_SIZE => HANDLE_WM_SIZE(hwnd, wParam, lParam, Handler, &handler),
        WM_TIMER => HANDLE_WM_TIMER(hwnd, wParam, lParam, Handler, &handler),
        WM_PAINT => HANDLE_WM_PAINT(hwnd, wParam, lParam, Handler, &handler),
        WM_DESTROY => HANDLE_WM_DESTROY(hwnd, wParam, lParam, Handler, &handler),
        else => win32.DefWindowProc(hwnd, message, wParam, lParam),
    };
}
