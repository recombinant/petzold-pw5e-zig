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
    usingnamespace @import("zigwin32").zig;
    usingnamespace @import("zigwin32").system.library_loader;
    usingnamespace @import("zigwin32").system.system_information;
    usingnamespace @import("zigwin32").foundation;
    usingnamespace @import("zigwin32").ui.windows_and_messaging;
    usingnamespace @import("zigwin32").ui.input.keyboard_and_mouse;
    usingnamespace @import("zigwin32").graphics.gdi;
    usingnamespace @import("zigwin32").globalization;
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

const windowsx = @import("windowsx");

pub export fn wWinMain(
    hInstance: HINSTANCE,
    hPrevInstance: ?HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
    _ = hPrevInstance;
    _ = pCmdLine;

    const app_name = L("DigClock");

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
        .lpszClassName = app_name,
        .hIconSm = null,
    };

    const atom: u16 = win32.RegisterClassEx(&wndclassex);
    if (0 == atom) {
        std.log.err("failed RegisterClassEx()", .{});
        return 0; // premature exit
    }

    // If a memory align panic occurs then the CreateWindowExW() Zig declaration
    // needs to have align(1) added to the class_name parameter.
    //   class_name: ?[*:0]align(1) const u16,
    //                      ^^^^^^^^
    // https://github.com/marlersoft/zigwin32gen/issues/9
    const class_name = @as([*:0]align(1) const u16, @ptrFromInt(atom));

    const hwnd = win32.CreateWindowEx(
        // https://docs.microsoft.com/en-us/windows/win32/winmsg/extended-window-styles
        win32.WINDOW_EX_STYLE{},
        class_name,
        L("Digital Clock"),
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

// 10 digits, each 7 segments
const digit_segment_flags: [10][7]bool = [_][7]bool{
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
// 7 segments
const segment_points: [7][6]POINT = [_][6]POINT{
    [_]POINT{ POINT{ .x = 7, .y = 6 }, POINT{ .x = 11, .y = 2 }, POINT{ .x = 31, .y = 2 }, POINT{ .x = 35, .y = 6 }, POINT{ .x = 31, .y = 10 }, POINT{ .x = 11, .y = 10 } },
    [_]POINT{ POINT{ .x = 6, .y = 7 }, POINT{ .x = 10, .y = 11 }, POINT{ .x = 10, .y = 31 }, POINT{ .x = 6, .y = 35 }, POINT{ .x = 2, .y = 31 }, POINT{ .x = 2, .y = 11 } },
    [_]POINT{ POINT{ .x = 36, .y = 7 }, POINT{ .x = 40, .y = 11 }, POINT{ .x = 40, .y = 31 }, POINT{ .x = 36, .y = 35 }, POINT{ .x = 32, .y = 31 }, POINT{ .x = 32, .y = 11 } },
    [_]POINT{ POINT{ .x = 7, .y = 36 }, POINT{ .x = 11, .y = 32 }, POINT{ .x = 31, .y = 32 }, POINT{ .x = 35, .y = 36 }, POINT{ .x = 31, .y = 40 }, POINT{ .x = 11, .y = 40 } },
    [_]POINT{ POINT{ .x = 6, .y = 37 }, POINT{ .x = 10, .y = 41 }, POINT{ .x = 10, .y = 61 }, POINT{ .x = 6, .y = 65 }, POINT{ .x = 2, .y = 61 }, POINT{ .x = 2, .y = 41 } },
    [_]POINT{ POINT{ .x = 36, .y = 37 }, POINT{ .x = 40, .y = 41 }, POINT{ .x = 40, .y = 61 }, POINT{ .x = 36, .y = 65 }, POINT{ .x = 32, .y = 61 }, POINT{ .x = 32, .y = 41 } },
    [_]POINT{ POINT{ .x = 7, .y = 66 }, POINT{ .x = 11, .y = 62 }, POINT{ .x = 31, .y = 62 }, POINT{ .x = 35, .y = 66 }, POINT{ .x = 31, .y = 70 }, POINT{ .x = 11, .y = 70 } },
};

const colon_points: [2][4]POINT = [_][4]POINT{
    [_]POINT{ POINT{ .x = 2, .y = 21 }, POINT{ .x = 6, .y = 17 }, POINT{ .x = 10, .y = 21 }, POINT{ .x = 6, .y = 25 } },
    [_]POINT{ POINT{ .x = 2, .y = 51 }, POINT{ .x = 6, .y = 47 }, POINT{ .x = 10, .y = 51 }, POINT{ .x = 6, .y = 55 } },
};

fn DisplayDigit(hdc: ?HDC, digit: usize) void {
    const flags = digit_segment_flags[digit];

    // Segment index
    var i: usize = 0;

    for (segment_points) |points| {
        if (flags[i]) {
            _ = win32.Polygon(hdc, &points, points.len);
        }
        i += 1;
    }
}

fn DisplayTwoDigits(hdc: ?HDC, digit: usize, suppress_zero: bool) void {
    if (!suppress_zero or (@divTrunc(digit, 10) != 0))
        DisplayDigit(hdc, @divTrunc(digit, 10));

    _ = win32.OffsetWindowOrgEx(hdc, -42, 0, null);
    DisplayDigit(hdc, @mod(digit, 10));
    _ = win32.OffsetWindowOrgEx(hdc, -42, 0, null);
}

fn DisplayColon(hdc: ?HDC) void {
    inline for (colon_points) |points| {
        _ = win32.Polygon(hdc, &points, points.len);
    }
    _ = win32.OffsetWindowOrgEx(hdc, -12, 0, null);
}

fn DisplayTime(hdc: ?HDC, is_24hour: bool, suppress_zero: bool) void {
    var st: win32.SYSTEMTIME = undefined;
    _ = win32.GetLocalTime(&st);

    if (is_24hour) {
        DisplayTwoDigits(hdc, st.wHour, suppress_zero);
    } else {
        st.wHour = @mod(st.wHour, 12);
        DisplayTwoDigits(hdc, if (st.wHour != 0) st.wHour else 12, suppress_zero);
    }

    DisplayColon(hdc);
    DisplayTwoDigits(hdc, st.wMinute, false);
    DisplayColon(hdc);
    DisplayTwoDigits(hdc, st.wSecond, false);
}

const Handler = struct {
    const Self = @This();

    const ID_TIMER = 1;

    is_24hour: bool = true,
    suppress_zero: bool = false, // suppress hour leading zero
    hbrush_red: ?win32.HBRUSH = undefined,
    cx_client: i32 = undefined,
    cy_client: i32 = undefined,

    fn locale(self: *Self, hwnd: HWND) void {
        var buffer: [2:0]TCHAR = undefined;
        const locale_name = windowsx.LOCALE_NAME_USER_DEFAULT;
        // const locale_name = L("en-US");

        _ = win32.GetLocaleInfoEx(locale_name, win32.LOCALE_ITIME, &buffer, buffer.len);
        self.is_24hour = (buffer[0] == '1');

        _ = win32.GetLocaleInfoEx(locale_name, win32.LOCALE_ITLZERO, &buffer, buffer.len);
        self.suppress_zero = (buffer[0] == '0');

        _ = win32.InvalidateRect(hwnd, null, TRUE);
    }
    pub fn OnCreate(self: *Self, hwnd: HWND, _: *win32.CREATESTRUCT) LRESULT {
        self.hbrush_red = win32.CreateSolidBrush(windowsx.RGB(255, 0, 0));
        _ = win32.SetTimer(hwnd, ID_TIMER, 1000, null);

        self.locale(hwnd);
        return 0;
    }
    pub fn OnSettingChange(self: *Self, hwnd: HWND, _: win32.SYSTEM_PARAMETERS_INFO_ACTION, _: ?[*:0]const TCHAR) void {
        self.locale(hwnd);
    }
    pub fn OnSize(self: *Self, _: HWND, _: u32, cx_client: i16, cy_client: i16) void {
        self.cx_client = cx_client;
        self.cy_client = cy_client;
    }
    pub fn OnTimer(_: *Self, hwnd: HWND, _: usize) void {
        _ = win32.InvalidateRect(hwnd, null, TRUE);
    }
    pub fn OnPaint(self: *Self, hwnd: HWND) void {
        var ps: win32.PAINTSTRUCT = undefined;
        const hdc: ?HDC = win32.BeginPaint(hwnd, &ps);
        defer _ = win32.EndPaint(hwnd, &ps);

        _ = win32.SetMapMode(hdc, win32.MM_ISOTROPIC);
        _ = win32.SetWindowExtEx(hdc, 276, 72, null);
        _ = win32.SetViewportExtEx(hdc, self.cx_client, self.cy_client, null);
        _ = win32.SetWindowOrgEx(hdc, 138, 36, null);
        _ = win32.SetViewportOrgEx(hdc, @divTrunc(self.cx_client, 2), @divTrunc(self.cy_client, 2), null);

        _ = windowsx.SelectPen(hdc, windowsx.GetStockPen(win32.NULL_PEN));
        _ = windowsx.SelectBrush(hdc, self.hbrush_red);

        DisplayTime(hdc, self.is_24hour, self.suppress_zero);
    }
    pub fn OnDestroy(self: *Self, hwnd: HWND) void {
        _ = win32.KillTimer(hwnd, ID_TIMER);
        _ = windowsx.DeleteBrush(self.hbrush_red);
        win32.PostQuitMessage(0);
    }
};

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
    wparam: WPARAM,
    lparam: LPARAM,
) callconv(WINAPI) LRESULT {
    const state = struct {
        var handler = Handler{};
    };

    return switch (message) {
        WM_CREATE => HANDLE_WM_CREATE(hwnd, wparam, lparam, Handler, &state.handler),
        WM_SETTINGCHANGE => HANDLE_WM_SETTINGCHANGE(hwnd, wparam, lparam, Handler, &state.handler),
        WM_SIZE => HANDLE_WM_SIZE(hwnd, wparam, lparam, Handler, &state.handler),
        WM_TIMER => HANDLE_WM_TIMER(hwnd, wparam, lparam, Handler, &state.handler),
        WM_PAINT => HANDLE_WM_PAINT(hwnd, wparam, lparam, Handler, &state.handler),
        WM_DESTROY => HANDLE_WM_DESTROY(hwnd, wparam, lparam, Handler, &state.handler),
        else => win32.DefWindowProc(hwnd, message, wparam, lparam),
    };
}
