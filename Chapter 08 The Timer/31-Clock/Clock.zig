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
const ID_TIMER = 1;

const std = @import("std");

pub const UNICODE = true; // used by zigwin32
const win32 = @import("win32").everything;

const HINSTANCE = win32.HINSTANCE;
const HWND = win32.HWND;
const HDC = win32.HDC;
const WPARAM = win32.WPARAM;
const LPARAM = win32.LPARAM;
const LRESULT = win32.LRESULT;
const POINT = win32.POINT;
const BOOL = win32.BOOL;
const L = win32.L;

const windowsx = @import("windowsx");

pub export fn wWinMain(
    hInstance: HINSTANCE,
    hPrevInstance: ?HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(.winapi) c_int {
    _ = hPrevInstance;
    _ = pCmdLine;

    const app_name = L("Clock");

    var wndclassex: win32.WNDCLASSEXW = .{
        .cbSize = @sizeOf(win32.WNDCLASSEXW),
        .style = win32.WNDCLASS_STYLES{ .HREDRAW = 1, .VREDRAW = 1 },
        .lpfnWndProc = WndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hInstance,
        .hIcon = @ptrCast(win32.LoadImageW(null, win32.IDI_APPLICATION, win32.IMAGE_ICON, 0, 0, win32.IMAGE_FLAGS{ .SHARED = 1, .DEFAULTSIZE = 1 })),
        .hCursor = @ptrCast(win32.LoadImageW(null, win32.IDC_ARROW, win32.IMAGE_CURSOR, 0, 0, win32.IMAGE_FLAGS{ .SHARED = 1, .DEFAULTSIZE = 1 })),
        .hbrBackground = windowsx.GetStockBrush(win32.WHITE_BRUSH),
        .lpszMenuName = null,
        .lpszClassName = app_name,
        .hIconSm = null,
    };

    const atom: u16 = win32.RegisterClassExW(&wndclassex);
    if (0 == atom) {
        std.log.err("failed RegisterClassEx()", .{});
        return 0; // premature exit
    }

    // If a memory align panic occurs then the CreateWindowExW() Zig declaration
    // needs to have align(1) added to the class_name parameter.
    //   class_name: ?[*:0]align(1) const u16,
    //                     ^^^^^^^^
    // https://github.com/marlersoft/zigwin32gen/issues/9
    const class_name = @as([*:0]align(1) const u16, @ptrFromInt(atom));

    const hwnd = win32.CreateWindowExW(
        // https://docs.microsoft.com/en-us/windows/win32/winmsg/extended-window-styles
        win32.WINDOW_EX_STYLE{},
        class_name,
        L("Analog Clock"),
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

    var msg: win32.MSG = undefined;
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

pub fn SetIsotropic(hdc: HDC, cx_client: i32, cy_client: i32) void {
    _ = win32.SetMapMode(hdc, win32.MM_ISOTROPIC);
    _ = win32.SetWindowExtEx(hdc, 1000, 1000, null);
    _ = win32.SetViewportExtEx(hdc, @divTrunc(cx_client, 2), @divTrunc(-cy_client, 2), null);
    _ = win32.SetViewportOrgEx(hdc, @divTrunc(cx_client, 2), @divTrunc(cy_client, 2), null);
}

const AngleFloat = struct {
    cos: f32,
    sin: f32,

    fn init(angle_i32: i32) AngleFloat {
        const angle_f32 = std.math.degreesToRadians(@as(f32, @floatFromInt(angle_i32)));

        return .{
            .cos = @cos(angle_f32),
            .sin = @sin(angle_f32),
        };
    }
};

/// `const angle = AngleFloat.init(180);`
/// `const rotated_point: POINT = PointFloat(unrotated_point).rotate(angle).point();`
const PointFloat = struct {
    const Self = @This();

    x: f32,
    y: f32,

    fn init(pt: POINT) Self {
        return .{
            .x = @floatFromInt(pt.x),
            .y = @floatFromInt(pt.y),
        };
    }
    fn rotate(self: Self, angle: AngleFloat) Self {
        return .{
            .x = (self.x * angle.cos) + (self.y * angle.sin),
            .y = (self.y * angle.cos) - (self.x * angle.sin),
        };
    }
    fn offset(self: Self, distance: f32) Self {
        return .{
            .x = self.x + distance,
            .y = self.y + distance,
        };
    }
    fn point(self: Self) POINT {
        return .{
            .x = @intFromFloat(self.x),
            .y = @intFromFloat(self.y),
        };
    }
};

/// Rotate slice of POINT in place
pub fn rotatePoints(pts: []POINT, angle_i32: i32) void {
    const angle_f32: AngleFloat = .init(angle_i32);

    for (pts) |*pt|
        pt.* = PointFloat.init(pt.*).rotate(angle_f32).point();
}

pub fn drawClock(hdc: HDC) void {
    const original = windowsx.SelectBrush(hdc, windowsx.GetStockBrush(win32.BLACK_BRUSH));
    defer _ = windowsx.SelectBrush(hdc, original);

    var angle_i32: i32 = 0;
    while (angle_i32 < 360) : (angle_i32 += 6) {
        const diameter: f32 = if (@mod(angle_i32, 5) != 0) 33 else 100;
        const radius = diameter / 2;

        // Rotate
        const angle_f32: AngleFloat = .init(angle_i32);
        const center = PointFloat.init(.{ .x = 0, .y = 900 }).rotate(angle_f32);

        const top_left: POINT = center.offset(-radius).point();
        const bottom_right: POINT = center.offset(radius).point();

        _ = win32.Ellipse(hdc, top_left.x, top_left.y, bottom_right.x, bottom_right.y);
    }
}

pub fn drawHands(hdc: HDC, system_time: *win32.SYSTEMTIME, changed: bool) void {
    // Arrays of hand points for each of the hands.
    var hour_hand: [5]POINT = .{
        .{ .x = 0, .y = -150 }, .{ .x = 100, .y = 0 },
        .{ .x = 0, .y = 600 },  .{ .x = -100, .y = 0 },
        .{ .x = 0, .y = -150 },
    };
    var minute_hand: [5]POINT = .{
        .{ .x = 0, .y = -200 }, .{ .x = 50, .y = 0 },
        .{ .x = 0, .y = 800 },  .{ .x = -50, .y = 0 },
        .{ .x = 0, .y = -200 },
    };
    var second_hand: [2]POINT = .{ .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 800 } };

    // Array of slices of hand points.
    const hand_point_slices: [3][]POINT = .{
        hour_hand[0..],
        minute_hand[0..],
        second_hand[0..],
    };

    const hand_angles: [3]i32 = .{
        @mod(system_time.*.wHour * 30, 360) + @divTrunc(system_time.*.wMinute, 2),
        system_time.*.wMinute * 6,
        system_time.*.wSecond * 6,
    };

    // Only draw the hour and minute hands if "changed" is true.
    const i: usize = if (changed) 0 else 2;

    for (hand_point_slices[i..], hand_angles[i..]) |hand_points, hand_angle| {
        rotatePoints(hand_points, hand_angle);

        const apt = hand_points.ptr;
        const cpt = @as(i32, @intCast(@as(u32, @truncate(hand_points.len))));
        _ = win32.Polyline(hdc, apt, cpt);
    }
}

const Handler = struct {
    // This value results in initial "changed" to true in OnTimer()
    system_time: win32.SYSTEMTIME = .{ .wYear = 0, .wMonth = 0, .wDayOfWeek = 0, .wDay = 0, .wHour = 0xffff, .wMinute = 0xffff, .wSecond = 0, .wMilliseconds = 0 },
    cx_client: i32 = undefined,
    cy_client: i32 = undefined,

    pub fn OnCreate(self: *Handler, hwnd: HWND, _: *win32.CREATESTRUCTW) LRESULT {
        _ = win32.SetTimer(hwnd, ID_TIMER, 1000, null);
        var system_time: win32.SYSTEMTIME = undefined;
        _ = win32.GetLocalTime(&system_time);
        self.system_time = system_time;
        return 0;
    }
    pub fn OnSize(self: *Handler, _: HWND, _: u32, cx_client: i16, cy_client: i16) void {
        self.cx_client = cx_client;
        self.cy_client = cy_client;
    }
    pub fn OnTimer(self: *Handler, hwnd: HWND, _: usize) void {
        var system_time: win32.SYSTEMTIME = undefined;
        _ = win32.GetLocalTime(&system_time);
        defer self.system_time = system_time;

        const changed: bool = system_time.wHour != self.system_time.wHour or
            system_time.wMinute != self.system_time.wMinute;

        const hdc: HDC = win32.GetDC(hwnd).?;
        defer _ = win32.ReleaseDC(hwnd, hdc);

        SetIsotropic(hdc, self.cx_client, self.cy_client);

        const pen = windowsx.SelectPen(hdc, windowsx.GetStockPen(win32.WHITE_PEN));
        defer _ = windowsx.SelectPen(hdc, pen);

        drawHands(hdc, &self.system_time, changed);

        _ = windowsx.SelectPen(hdc, windowsx.GetStockPen(win32.BLACK_PEN));
        drawHands(hdc, &system_time, true);
    }
    pub fn OnPaint(self: *Handler, hwnd: HWND) void {
        var ps: win32.PAINTSTRUCT = undefined;
        const hdc: HDC = win32.BeginPaint(hwnd, &ps).?;
        defer _ = win32.EndPaint(hwnd, &ps);

        SetIsotropic(hdc, self.cx_client, self.cy_client);
        drawClock(hdc);
        drawHands(hdc, &self.system_time, true);
    }
    pub fn OnDestroy(_: *Handler, hwnd: HWND) void {
        _ = win32.KillTimer(hwnd, ID_TIMER);
        win32.PostQuitMessage(0);
    }
};

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
) callconv(.winapi) LRESULT {
    const state = struct {
        var handler: Handler = .{};
    };

    return switch (message) {
        WM_CREATE => HANDLE_WM_CREATE(hwnd, wParam, lParam, Handler, &state.handler),
        WM_SIZE => HANDLE_WM_SIZE(hwnd, wParam, lParam, Handler, &state.handler),
        WM_TIMER => HANDLE_WM_TIMER(hwnd, wParam, lParam, Handler, &state.handler),
        WM_PAINT => HANDLE_WM_PAINT(hwnd, wParam, lParam, Handler, &state.handler),
        WM_DESTROY => HANDLE_WM_DESTROY(hwnd, wParam, lParam, Handler, &state.handler),
        else => win32.DefWindowProcW(hwnd, message, wParam, lParam),
    };
}
