// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 5 - DevCaps1
//
// The original source code copyright:
//
// ---------------------------------------------------------
//  DEVCAPS1.C -- Device Capabilities Display Program No. 1
//                (c) Charles Petzold, 1998
// ---------------------------------------------------------
const std = @import("std");

pub const UNICODE = true; // used by zigwin32
const win32 = @import("win32").everything;

const BOOL = win32.BOOL;
const L = win32.L;
const HINSTANCE = win32.HINSTANCE;
const MSG = win32.MSG;
const HWND = win32.HWND;
const HDC = win32.HDC;
const LPARAM = win32.LPARAM;
const WPARAM = win32.WPARAM;
const LRESULT = win32.LRESULT;
const CREATESTRUCT = win32.CREATESTRUCTW;

const windowsx = @import("windowsx");
const GetStockBrush = windowsx.GetStockBrush;

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
) callconv(.winapi) c_int {
    _ = pCmdLine;

    const app_name = L("DevCaps1");
    const wndclassex = win32.WNDCLASSEXW{
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
        L("Device Capabilities"),
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
    char_width: i32 = undefined,
    caps_width: i32 = undefined,
    char_height: i32 = undefined,

    pub fn OnCreate(self: *Handler, hwnd: HWND, _: *CREATESTRUCT) LRESULT {
        const hdc = win32.GetDC(hwnd);
        defer _ = win32.ReleaseDC(hwnd, hdc);

        var tm: win32.TEXTMETRICW = undefined;
        _ = win32.GetTextMetricsW(hdc, &tm);
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
                label_size = @max(label_size, devcap.label.len);
                description_size = @max(description_size, devcap.description.len);
            }
            break :blk .{
                .label = label_size + 1,
                .description = description_size + 1,
            };
        };

        const TA_LEFT = @intFromEnum(win32.TA_LEFT);
        const TA_RIGHT = @intFromEnum(win32.TA_RIGHT);
        const TA_TOP = @intFromEnum(win32.TA_TOP);
        const flagsL: win32.TEXT_ALIGN_OPTIONS = @enumFromInt(TA_LEFT | TA_TOP);
        const flagsR: win32.TEXT_ALIGN_OPTIONS = @enumFromInt(TA_RIGHT | TA_TOP);

        var i: i32 = 0;
        for (devcaps) |devcap| {

            // Convert to Windows strings

            var label: [sizes.label]u16 = [_]u16{0} ** sizes.label;
            const label_len: i32 = @intCast(std.unicode.utf8ToUtf16Le(label[0..], devcap.label) catch unreachable);

            var description: [sizes.description]u16 = [_]u16{0} ** sizes.description;
            const description_len: i32 = @intCast(std.unicode.utf8ToUtf16Le(description[0..], devcap.description) catch unreachable);

            const caps: i32 = win32.GetDeviceCaps(hdc, devcap.index);
            var buffer2: [6]u8 = [_]u8{0} ** 6;
            const slice2 = std.fmt.bufPrint(buffer2[0..], "{d:5}", .{caps}) catch unreachable;

            var value: [6]u16 = [_]u16{0} ** 6;
            const value_len: i32 = @intCast(std.unicode.utf8ToUtf16Le(value[0..], slice2) catch unreachable);

            // Output

            _ = win32.SetTextAlign(hdc, flagsL);

            _ = win32.TextOutW(hdc, 0, self.char_height * i, @ptrCast(&label), label_len);
            _ = win32.TextOutW(hdc, 14 * self.caps_width, self.char_height * i, @ptrCast(&description), description_len);

            _ = win32.SetTextAlign(hdc, flagsR);

            _ = win32.TextOutW(hdc, 14 * self.caps_width + 35 * self.char_width, self.char_height * i, @ptrCast(&value), value_len);

            //

            i += 1;
        }
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

fn WndProc(
    hwnd: HWND,
    message: u32,
    wParam: WPARAM,
    lParam: LPARAM,
) callconv(.winapi) LRESULT {
    const state = struct {
        var handler = Handler{};
    };

    return switch (message) {
        WM_CREATE => HANDLE_WM_CREATE(hwnd, wParam, lParam, Handler, &state.handler),
        WM_PAINT => HANDLE_WM_PAINT(hwnd, wParam, lParam, Handler, &state.handler),
        WM_DESTROY => HANDLE_WM_DESTROY(hwnd, wParam, lParam, Handler, &state.handler),
        else => win32.DefWindowProcW(hwnd, message, wParam, lParam),
    };
}
