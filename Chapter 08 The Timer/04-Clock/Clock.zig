// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 8 - DigClock
//
// The original source code copyright:
//
// --------------------------------------
//  CLOCK.c -- Analog Clock
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

const windowsx = @import("windowsx").windowsx;

pub export fn wWinMain(
    hInstance: HINSTANCE,
    hPrevInstance: ?HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
    _ = hPrevInstance;
    _ = pCmdLine;

    const szAppName = L("Clock");

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
        L("Analog Clock"),
        win32.WINDOW_STYLE.initFlags(.{
            .TILEDWINDOW = 1, // .OVERLAPPEDWINDOW equivalent
            .SYSMENU = 1,
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

pub fn SetIsotropic(hdc: HDC, cxClient: i32, cyClient: i32) void {
    _ = win32.SetMapMode(hdc, win32.MM_ISOTROPIC);
    _ = win32.SetWindowExtEx(hdc, 1000, 1000, null);
    _ = win32.SetViewportExtEx(hdc, @divTrunc(cxClient, 2), @divTrunc(-cyClient, 2), null);
    _ = win32.SetViewportOrgEx(hdc, @divTrunc(cxClient, 2), @divTrunc(cyClient, 2), null);
}

pub fn RotatePoint(pt: POINT, angle: f32) POINT {
    const DEG2RAD: f32 = std.math.pi * 2.0 / 360.0;

    const xIn: f32 = @intToFloat(f32, pt.x);
    const yIn: f32 = @intToFloat(f32, pt.y);

    const xOut: f32 = xIn * std.math.cos(DEG2RAD * angle) + yIn * std.math.sin(DEG2RAD * angle);
    const yOut: f32 = yIn * std.math.cos(DEG2RAD * angle) - xIn * std.math.sin(DEG2RAD * angle);

    return POINT{ .x = @floatToInt(i32, xOut), .y = @floatToInt(i32, yOut) };
}

pub fn DrawClock(hdc: HDC) void {
    _ = windowsx.SelectBrush(hdc, windowsx.GetStockBrush(win32.BLACK_BRUSH));

    var pt: [2]POINT = undefined; // top left, bottom right
    var iAngle: i32 = 0;
    while (iAngle < 360) : (iAngle += 6) {
        pt[0] = POINT{ .x = 0, .y = 900 };

        pt[0] = RotatePoint(pt[0], @intToFloat(f32, iAngle));

        const diameter: i32 = if (@mod(iAngle, 5) != 0) 33 else 100;

        pt[0].x -= @divTrunc(diameter, 2);
        pt[0].y -= @divTrunc(diameter, 2);

        pt[1].x = pt[0].x + diameter;
        pt[1].y = pt[0].y + diameter;

        _ = win32.Ellipse(hdc, pt[0].x, pt[0].y, pt[1].x, pt[1].y);
    }
}
pub fn DrawHands(hdc: HDC, pst: *win32.SYSTEMTIME, fChange: bool) void {
    const pt: [3][5]POINT = [3][5]POINT{
        [5]POINT{ POINT{ .x = 0, .y = -150 }, POINT{ .x = 100, .y = 0 }, POINT{ .x = 0, .y = 600 }, POINT{ .x = -100, .y = 0 }, POINT{ .x = 0, .y = -150 } },
        [5]POINT{ POINT{ .x = 0, .y = -200 }, POINT{ .x = 50, .y = 0 }, POINT{ .x = 0, .y = 800 }, POINT{ .x = -50, .y = 0 }, POINT{ .x = 0, .y = -200 } },
        [5]POINT{ POINT{ .x = 0, .y = 0 }, POINT{ .x = 0, .y = 0 }, POINT{ .x = 0, .y = 0 }, POINT{ .x = 0, .y = 0 }, POINT{ .x = 0, .y = 800 } },
    };

    var angle: [3]f32 = undefined;
    angle[0] = @intToFloat(f32, @mod(pst.*.wHour * 30, 360) + @divTrunc(pst.*.wMinute, 2));
    angle[1] = @intToFloat(f32, pst.*.wMinute * 6);
    angle[2] = @intToFloat(f32, pst.*.wSecond * 6);

    var ptTemp: [5]POINT = undefined;
    var i: usize = if (fChange) 0 else 2;
    while (i < angle.len) : (i += 1) {
        var j: usize = 0;
        while (j < ptTemp.len) : (j += 1) {
            ptTemp[j] = RotatePoint(pt[i][j], angle[i]);
        }
        _ = win32.Polyline(hdc, &ptTemp, 5);
    }
}

const Handler = struct {
    const ID_TIMER = 1;
    stPrevious: win32.SYSTEMTIME = undefined,
    fChange: bool = false,
    cxClient: i32 = undefined,
    cyClient: i32 = undefined,

    pub fn OnCreate(self: *Handler, hwnd: HWND, _: *win32.CREATESTRUCT) LRESULT {
        _ = win32.SetTimer(hwnd, ID_TIMER, 1000, null);
        var st: win32.SYSTEMTIME = undefined;
        _ = win32.GetLocalTime(&st);
        self.stPrevious = st;
        return 0;
    }
    pub fn OnSize(self: *Handler, _: HWND, _: u32, cxClient: i16, cyClient: i16) void {
        self.cxClient = cxClient;
        self.cyClient = cyClient;
    }
    pub fn OnTimer(self: *Handler, hwnd: HWND, _: usize) void {
        var st: win32.SYSTEMTIME = undefined;
        _ = win32.GetLocalTime(&st);

        self.fChange = st.wHour != self.stPrevious.wHour or
            st.wMinute != self.stPrevious.wMinute;

        const hdc: HDC = win32.GetDC(hwnd).?;
        defer _ = win32.ReleaseDC(hwnd, hdc);

        SetIsotropic(hdc, self.cxClient, self.cyClient);

        _ = windowsx.SelectPen(hdc, windowsx.GetStockPen(win32.WHITE_PEN));
        DrawHands(hdc, &self.stPrevious, self.fChange);

        _ = windowsx.SelectPen(hdc, windowsx.GetStockPen(win32.BLACK_PEN));
        DrawHands(hdc, &st, true);

        self.stPrevious = st;
    }
    pub fn OnPaint(self: *Handler, hwnd: HWND) void {
        var ps: win32.PAINTSTRUCT = undefined;
        const hdc: HDC = win32.BeginPaint(hwnd, &ps).?;
        defer _ = win32.EndPaint(hwnd, &ps);

        SetIsotropic(hdc, self.cxClient, self.cyClient);
        DrawClock(hdc);
        DrawHands(hdc, &self.stPrevious, true);
    }
    pub fn OnDestroy(_: *Handler, hwnd: HWND) void {
        _ = win32.KillTimer(hwnd, ID_TIMER);
        win32.PostQuitMessage(0);
    }
};

var handler = Handler{};

const WM_CREATE = win32.WM_CREATE;
const WM_SIZE = win32.WM_SIZE;
const WM_TIMER = win32.WM_TIMER;
const WM_PAINT = win32.WM_PAINT;
const WM_DESTROY = win32.WM_DESTROY;
const HANDLE_WM_CREATE = windowsx.HANDLE_WM_CREATE;
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
        WM_SIZE => HANDLE_WM_SIZE(hwnd, wParam, lParam, Handler, &handler),
        WM_TIMER => HANDLE_WM_TIMER(hwnd, wParam, lParam, Handler, &handler),
        WM_PAINT => HANDLE_WM_PAINT(hwnd, wParam, lParam, Handler, &handler),
        WM_DESTROY => HANDLE_WM_DESTROY(hwnd, wParam, lParam, Handler, &handler),
        else => win32.DefWindowProc(hwnd, message, wParam, lParam),
    };
}
