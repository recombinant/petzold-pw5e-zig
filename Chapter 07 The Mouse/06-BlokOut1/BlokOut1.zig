// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 7 - BlokOut1
//
// The original source code copyright:
//
// -----------------------------------------
//  BLOKOUT1.C -- Mouse Button Demo Program
//                (c) Charles Petzold, 1998
// -----------------------------------------
pub const UNICODE = true;

const std = @import("std");

const WINAPI = std.os.windows.WINAPI;

const win32 = struct {
    usingnamespace @import("win32").zig;
    usingnamespace @import("win32").system.library_loader;
    usingnamespace @import("win32").foundation;
    usingnamespace @import("win32").ui.windows_and_messaging;
    usingnamespace @import("win32").ui.input.keyboard_and_mouse;
    usingnamespace @import("win32").graphics.gdi;
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

    const szAppName = L("BlokOut1");

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
        L("Mouse Button Demo"),
        win32.WINDOW_STYLE.initFlags(.{
            .TILEDWINDOW = 1, // .OVERLAPPEDWINDOW equivalent
            .SYSMENU = 1,
            .VSCROLL = 1,
            .HSCROLL = 1,
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

fn DrawBoxOutline(hwnd: HWND, ptBeg: POINT, ptEnd: POINT) void {
    const hdc = win32.GetDC(hwnd);
    defer _ = win32.ReleaseDC(hwnd, hdc);

    _ = win32.SetROP2(hdc, win32.R2_NOT);
    _ = win32.SelectObject(hdc, windowsx.GetStockBrush(win32.NULL_BRUSH));
    _ = win32.Rectangle(hdc, ptBeg.x, ptBeg.y, ptEnd.x, ptEnd.y);
}

const Handler = struct {
    fBlocking: bool = false,
    fValidBox: bool = false,
    ptBeg: POINT = undefined,
    ptEnd: POINT = undefined,
    ptBoxBeg: POINT = undefined,
    ptBoxEnd: POINT = undefined,

    pub fn OnLButtonDown(self: *Handler, hwnd: HWND, fDoubleClick: bool, x: i16, y: i16, keyFlags: u32) void {
        _ = fDoubleClick;
        _ = keyFlags;

        self.ptBeg = POINT{ .x = x, .y = y };
        self.ptEnd = POINT{ .x = x, .y = y };

        DrawBoxOutline(hwnd, self.ptBeg, self.ptEnd);

        const crossCursor = @ptrCast(
            win32.HCURSOR,
            win32.LoadImage(null, win32.IDC_CROSS, win32.IMAGE_CURSOR, 0, 0, win32.IMAGE_FLAGS.initFlags(.{ .SHARED = 1, .DEFAULTSIZE = 1 })),
        );
        _ = win32.SetCursor(crossCursor);

        self.fBlocking = true;
    }
    pub fn OnMouseMove(self: *Handler, hwnd: HWND, x: i16, y: i16, keyFlags: u32) void {
        _ = keyFlags;

        if (self.fBlocking) {
            const crossCursor = @ptrCast(
                win32.HCURSOR,
                win32.LoadImage(null, win32.IDC_CROSS, win32.IMAGE_CURSOR, 0, 0, win32.IMAGE_FLAGS.initFlags(.{ .SHARED = 1, .DEFAULTSIZE = 1 })),
            );
            _ = win32.SetCursor(crossCursor);

            DrawBoxOutline(hwnd, self.ptBeg, self.ptEnd);

            self.ptEnd = POINT{ .x = x, .y = y };

            DrawBoxOutline(hwnd, self.ptBeg, self.ptEnd);
        }
    }
    pub fn OnLButtonUp(self: *Handler, hwnd: HWND, x: i16, y: i16, keyFlags: u32) void {
        _ = keyFlags;

        if (self.fBlocking) {
            DrawBoxOutline(hwnd, self.ptBeg, self.ptEnd);

            self.ptBoxBeg = self.ptBeg;
            self.ptBoxEnd = POINT{ .x = x, .y = y };

            const arrowCursor = @ptrCast(
                win32.HCURSOR,
                win32.LoadImage(null, win32.IDC_ARROW, win32.IMAGE_CURSOR, 0, 0, win32.IMAGE_FLAGS.initFlags(.{ .SHARED = 1, .DEFAULTSIZE = 1 })),
            );
            _ = win32.SetCursor(arrowCursor);

            self.fBlocking = false;
            self.fValidBox = true;

            _ = win32.InvalidateRect(hwnd, null, TRUE);
        }
    }
    pub fn OnChar(self: *Handler, hwnd: HWND, ch: TCHAR, cRepeat: i16) void {
        _ = cRepeat;

        // i.e. Escape
        if (self.fBlocking and (ch == '\x1B')) {
            DrawBoxOutline(hwnd, self.ptBeg, self.ptEnd);

            const arrowCursor = @ptrCast(
                win32.HCURSOR,
                win32.LoadImage(null, win32.IDC_ARROW, win32.IMAGE_CURSOR, 0, 0, win32.IMAGE_FLAGS.initFlags(.{ .SHARED = 1, .DEFAULTSIZE = 1 })),
            );
            _ = win32.SetCursor(arrowCursor);

            self.fBlocking = false;
        }
    }
    pub fn OnPaint(self: *Handler, hwnd: HWND) void {
        var ps: win32.PAINTSTRUCT = undefined;
        const hdc: ?HDC = win32.BeginPaint(hwnd, &ps);
        defer _ = win32.EndPaint(hwnd, &ps);

        if (self.fValidBox) {
            _ = win32.SelectObject(hdc, windowsx.GetStockBrush(win32.BLACK_BRUSH));
            _ = win32.Rectangle(hdc, self.ptBoxBeg.x, self.ptBoxBeg.y, self.ptBoxEnd.x, self.ptBoxEnd.y);
        }

        if (self.fBlocking) {
            _ = win32.SetROP2(hdc, win32.R2_NOT);
            _ = win32.SelectObject(hdc, windowsx.GetStockBrush(win32.NULL_BRUSH));
            _ = win32.Rectangle(hdc, self.ptBeg.x, self.ptBeg.y, self.ptEnd.x, self.ptEnd.y);
        }
    }
    pub fn OnDestroy(_: *Handler, _: HWND) void {
        win32.PostQuitMessage(0);
    }
};

var handler = Handler{};

const WM_LBUTTONDOWN = win32.WM_LBUTTONDOWN;
const WM_MOUSEMOVE = win32.WM_MOUSEMOVE;
const WM_LBUTTONUP = win32.WM_LBUTTONUP;
const WM_CHAR = win32.WM_CHAR;
const WM_PAINT = win32.WM_PAINT;
const WM_DESTROY = win32.WM_DESTROY;
const HANDLE_WM_LBUTTONDOWN = windowsx.HANDLE_WM_LBUTTONDOWN;
const HANDLE_WM_MOUSEMOVE = windowsx.HANDLE_WM_MOUSEMOVE;
const HANDLE_WM_LBUTTONUP = windowsx.HANDLE_WM_LBUTTONUP;
const HANDLE_WM_CHAR = windowsx.HANDLE_WM_CHAR;
const HANDLE_WM_PAINT = windowsx.HANDLE_WM_PAINT;
const HANDLE_WM_DESTROY = windowsx.HANDLE_WM_DESTROY;

fn WndProc(
    hwnd: HWND,
    message: u32,
    wParam: WPARAM,
    lParam: LPARAM,
) callconv(WINAPI) LRESULT {
    return switch (message) {
        WM_LBUTTONDOWN => HANDLE_WM_LBUTTONDOWN(hwnd, wParam, lParam, Handler, &handler),
        WM_MOUSEMOVE => HANDLE_WM_MOUSEMOVE(hwnd, wParam, lParam, Handler, &handler),
        WM_LBUTTONUP => HANDLE_WM_LBUTTONUP(hwnd, wParam, lParam, Handler, &handler),
        WM_CHAR => HANDLE_WM_CHAR(hwnd, wParam, lParam, Handler, &handler),
        WM_PAINT => HANDLE_WM_PAINT(hwnd, wParam, lParam, Handler, &handler),
        WM_DESTROY => HANDLE_WM_DESTROY(hwnd, wParam, lParam, Handler, &handler),
        else => win32.DefWindowProc(hwnd, message, wParam, lParam),
    };
}
