// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 5 - RandRect
//
// The original source code copyright:
//
// ------------------------------------------
//  RANDRECT.C -- Displays Random Rectangles
//                (c) Charles Petzold, 1998
// ------------------------------------------
pub const UNICODE = true;

const std = @import("std");
const RndGen = std.rand.DefaultPrng;

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
const FALSE = win32.FALSE;
const L = win32.L;
const HINSTANCE = win32.HINSTANCE;
const MSG = win32.MSG;
const HWND = win32.HWND;
const HDC = win32.HDC;
const LPARAM = win32.LPARAM;
const WPARAM = win32.WPARAM;
const LRESULT = win32.LRESULT;
const CW_USEDEFAULT = win32.CW_USEDEFAULT;
const WS_OVERLAPPEDWINDOW = @enumToInt(win32.WS_OVERLAPPEDWINDOW);
const WS_SYSMENU = @enumToInt(win32.WS_SYSMENU);
const WM_SIZE = win32.WM_SIZE;
const WM_DESTROY = win32.WM_DESTROY;
const WM_QUIT = win32.WM_QUIT;

const windowsx = @import("windowsx").windowsx;
const GetStockBrush = windowsx.GetStockBrush;
const HANDLE_WM_SIZE = windowsx.HANDLE_WM_SIZE;
const HANDLE_WM_DESTROY = windowsx.HANDLE_WM_DESTROY;

pub export fn wWinMain(
    hInstance: HINSTANCE,
    _: ?HINSTANCE,
    _: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
    const app_name = L("RandRect");
    const wndclassex = win32.WNDCLASSEX{
        .cbSize = @sizeOf(win32.WNDCLASSEX),
        .style = win32.WNDCLASS_STYLES.initFlags(.{ .HREDRAW = 1, .VREDRAW = 1 }),
        .lpfnWndProc = WndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hInstance,
        .hIcon = @ptrCast(win32.HICON, win32.LoadImage(null, win32.IDI_APPLICATION, win32.IMAGE_ICON, 0, 0, win32.IMAGE_FLAGS.initFlags(.{ .SHARED = 1, .DEFAULTSIZE = 1 }))),
        .hCursor = @ptrCast(win32.HCURSOR, win32.LoadImage(null, win32.IDC_ARROW, win32.IMAGE_CURSOR, 0, 0, win32.IMAGE_FLAGS.initFlags(.{ .SHARED = 1, .DEFAULTSIZE = 1 }))),
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
        L("Random Rectangles"),
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
        } else if (win32.PeekMessage(&msg, null, 0, 0, win32.PM_REMOVE) != FALSE) {
            if (msg.message == WM_QUIT)
                break;

            _ = win32.TranslateMessage(&msg);
            _ = win32.DispatchMessage(&msg);
        } else {
            DrawRectangle(hwnd);
        }
        ret = win32.GetMessage(&msg, null, 0, 0);
    }

    // Normal exit
    return @bitCast(c_int, @truncate(c_uint, msg.wParam)); // WM_QUIT
}

fn DrawRectangle(hwnd: ?HWND) void {
    if (handler.cxClient == 0 or handler.cyClient == 0)
        return;

    var rnd = handler.rnd.random();

    var rect: win32.RECT = undefined;
    const xLeft = rnd.intRangeLessThan(i32, 0, handler.cxClient);
    const yTop = rnd.intRangeLessThan(i32, 0, handler.cyClient);
    const xRight = rnd.intRangeLessThan(i32, 0, handler.cxClient);
    const yBottom = rnd.intRangeLessThan(i32, 0, handler.cyClient);

    _ = win32.SetRect(&rect, xLeft, yTop, xRight, yBottom);

    const r = rnd.intRangeLessThan(u32, 0, 256);
    const g = rnd.intRangeLessThan(u32, 0, 256);
    const b = rnd.intRangeLessThan(u32, 0, 256);
    const color = r | g << 8 | b << 16;

    const hBrush = win32.CreateSolidBrush(color);

    const hdc = win32.GetDC(hwnd);
    _ = win32.FillRect(hdc, &rect, hBrush);
    _ = win32.ReleaseDC(hwnd, hdc);
    _ = win32.DeleteObject(hBrush);
}

const Handler = struct {
    cxClient: i32 = undefined,
    cyClient: i32 = undefined,
    rnd: std.rand.DefaultPrng = RndGen.init(0),

    pub fn OnSize(self: *Handler, _: HWND, _: u32, cx: i16, cy: i16) void {
        self.cxClient = cx;
        self.cyClient = cy;
    }

    pub fn OnDestroy(_: *Handler, _: HWND) void {
        win32.PostQuitMessage(0);
    }
};

var handler = Handler{};

fn WndProc(hwnd: HWND, message: u32, wParam: WPARAM, lParam: LPARAM) callconv(WINAPI) LRESULT {
    return switch (message) {
        WM_SIZE => HANDLE_WM_SIZE(hwnd, wParam, lParam, Handler, &handler),
        WM_DESTROY => HANDLE_WM_DESTROY(hwnd, wParam, lParam, Handler, &handler),
        else => win32.DefWindowProc(hwnd, message, wParam, lParam),
    };
}
