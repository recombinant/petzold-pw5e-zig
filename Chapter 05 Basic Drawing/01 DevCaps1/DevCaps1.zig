// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 5 - DevCap1
//
// The original source code copyright:
//
// ---------------------------------------------------------
//  DEVCAPS1.C -- Device Capabilities Display Program No. 1
//                (c) Charles Petzold, 1998
// ---------------------------------------------------------
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
const L = win32.L;
const HINSTANCE = win32.HINSTANCE;
const MSG = win32.MSG;
const HWND = win32.HWND;
const HDC = win32.HDC;
const LPARAM = win32.LPARAM;
const WPARAM = win32.WPARAM;
const LRESULT = win32.LRESULT;
const CREATESTRUCT = win32.CREATESTRUCT;
const CW_USEDEFAULT = win32.CW_USEDEFAULT;
const TA_TOP = @enumToInt(win32.TA_TOP);
const TA_LEFT = @enumToInt(win32.TA_LEFT);
const TA_RIGHT = @enumToInt(win32.TA_RIGHT);
const WS_OVERLAPPEDWINDOW = @enumToInt(win32.WS_OVERLAPPEDWINDOW);
const WS_SYSMENU = @enumToInt(win32.WS_SYSMENU);
const WM_CREATE = win32.WM_CREATE;
const WM_PAINT = win32.WM_PAINT;
const WM_DESTROY = win32.WM_DESTROY;

const windowsx = @import("windowsx").windowsx;
const GetStockBrush = windowsx.GetStockBrush;
const HANDLE_WM_CREATE = windowsx.HANDLE_WM_CREATE;
const HANDLE_WM_PAINT = windowsx.HANDLE_WM_PAINT;
const HANDLE_WM_DESTROY = windowsx.HANDLE_WM_DESTROY;

const DevCaps = struct {
    index: win32.GET_DEVICE_CAPS_INDEX,
    label: []const u8,
    description: []const u8,
};

pub const devcaps = [_]DevCaps{
    .{ .index = win32.HORZSIZE, .label = "HORZSIZE", .description = "Width in millimeters:" },
    .{ .index = win32.VERTSIZE, .label = "VERTSIZE", .description = "Height in millimeters:" },
    .{ .index = win32.HORZRES, .label = "HORZRES", .description = "Width in pixels:" },
    .{ .index = win32.VERTRES, .label = "VERTRES", .description = "Height in raster lines:" },
    .{ .index = win32.BITSPIXEL, .label = "BITSPIXEL", .description = "Color bits per pixel:" },
    .{ .index = win32.PLANES, .label = "PLANES", .description = "Number of color planes:" },
    .{ .index = win32.NUMBRUSHES, .label = "NUMBRUSHES", .description = "Number of device brushes:" },
    .{ .index = win32.NUMPENS, .label = "NUMPENS", .description = "Number of device pens:" },
    .{ .index = win32.NUMMARKERS, .label = "NUMMARKERS", .description = "Number of device markers:" },
    .{ .index = win32.NUMFONTS, .label = "NUMFONTS", .description = "Number of device fonts:" },
    .{ .index = win32.NUMCOLORS, .label = "NUMCOLORS", .description = "Number of device colors:" },
    .{ .index = win32.PDEVICESIZE, .label = "PDEVICESIZE", .description = "Size of device structure:" },
    .{ .index = win32.ASPECTX, .label = "ASPECTX", .description = "Relative width of pixel:" },
    .{ .index = win32.ASPECTY, .label = "ASPECTY", .description = "Relative height of pixel:" },
    .{ .index = win32.ASPECTXY, .label = "ASPECTXY", .description = "Relative diagonal of pixel:" },
    .{ .index = win32.LOGPIXELSX, .label = "LOGPIXELSX", .description = "Horizontal dots per inch:" },
    .{ .index = win32.LOGPIXELSY, .label = "LOGPIXELSY", .description = "Vertical dots per inch:" },
    .{ .index = win32.SIZEPALETTE, .label = "SIZEPALETTE", .description = "Number of palette entries:" },
    .{ .index = win32.NUMRESERVED, .label = "NUMRESERVED", .description = "Reserved palette entries:" },
    .{ .index = win32.COLORRES, .label = "COLORRES", .description = "Actual color resolution:" },
};

pub export fn wWinMain(
    hInstance: HINSTANCE,
    _: ?HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
    _ = pCmdLine;

    const app_name = L("DevCaps1");
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
        L("Device Capabilities"),
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
    char_width: i32 = undefined,
    caps_width: i32 = undefined,
    char_height: i32 = undefined,

    pub fn OnCreate(self: *Handler, hwnd: HWND, _: *CREATESTRUCT) LRESULT {
        const hdc = win32.GetDC(hwnd);
        defer _ = win32.ReleaseDC(hwnd, hdc);

        var tm: win32.TEXTMETRIC = undefined;
        _ = win32.GetTextMetrics(hdc, &tm);
        self.char_width = tm.tmAveCharWidth;
        const factor: i32 = if (tm.tmPitchAndFamily & 1 != 0) 3 else 2;
        self.caps_width = @divTrunc(factor * self.char_width, 2);
        self.char_height = tm.tmHeight + tm.tmExternalLeading;

        return 0;
    }

    pub fn OnPaint(self: *Handler, hwnd: HWND) void {
        var ps: win32.PAINTSTRUCT = undefined;

        const hdc: ?HDC = win32.BeginPaint(hwnd, &ps);
        defer _ = win32.EndPaint(hwnd, &ps);

        // The strings are ASCII so the buffer size required will be the string length.
        const sizes = comptime blk: {
            var label_size: usize = 0;
            var description_size: usize = 0;
            for (devcaps) |devcap| {
                label_size = @maximum(label_size, devcap.label.len);
                description_size = @maximum(description_size, devcap.description.len);
            }
            break :blk .{
                .label = label_size + 1,
                .description = description_size + 1,
            };
        };

        const flagsL = @intToEnum(win32.TEXT_ALIGN_OPTIONS, TA_LEFT | TA_TOP);
        const flagsR = @intToEnum(win32.TEXT_ALIGN_OPTIONS, TA_RIGHT | TA_TOP);

        var i: i32 = 0;
        for (devcaps) |devcap| {

            // Convert to Windows strings

            var label: [sizes.label]u16 = [_]u16{0} ** sizes.label;
            var label_len: i32 = @intCast(i32, std.unicode.utf8ToUtf16Le(label[0..], devcap.label) catch unreachable);

            var description: [sizes.description]u16 = [_]u16{0} ** sizes.description;
            var description_len = @intCast(i32, std.unicode.utf8ToUtf16Le(description[0..], devcap.description) catch unreachable);

            const caps: i32 = win32.GetDeviceCaps(hdc, devcap.index);
            var buffer2: [6]u8 = [_]u8{0} ** 6;
            _ = std.fmt.bufPrint(buffer2[0..], "{d:5}", .{caps}) catch unreachable;

            var value: [6]u16 = [_]u16{0} ** 6;
            var value_len = @intCast(i32, std.unicode.utf8ToUtf16Le(value[0..], &buffer2) catch unreachable);

            // Output

            _ = win32.SetTextAlign(hdc, flagsL);

            _ = win32.TextOut(hdc, 0, self.char_height * i, &label, label_len);
            _ = win32.TextOut(hdc, 14 * self.caps_width, self.char_height * i, &description, description_len);

            _ = win32.SetTextAlign(hdc, flagsR);

            _ = win32.TextOut(hdc, 14 * self.caps_width + 35 * self.char_width, self.char_height * i, &value, value_len);

            //

            i += 1;
        }
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
    switch (message) {
        WM_CREATE => return HANDLE_WM_CREATE(hwnd, wParam, lParam, Handler, &handler),
        WM_PAINT => return HANDLE_WM_PAINT(hwnd, wParam, lParam, Handler, &handler),
        WM_DESTROY => return HANDLE_WM_DESTROY(hwnd, wParam, lParam, Handler, &handler),
        else => return win32.DefWindowProc(hwnd, message, wParam, lParam),
    }
}
