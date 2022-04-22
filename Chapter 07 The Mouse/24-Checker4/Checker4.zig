// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 7 - Checker4
//
// The original source code copyright:
//
// -------------------------------------------------
//  CHECKER4.C -- Mouse Hit-Test Demo Program No. 4
//                (c) Charles Petzold, 1998
// -------------------------------------------------
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
    usingnamespace @import("win32").system.diagnostics.debug;
};
const BOOL = win32.BOOL;
const FALSE = win32.FALSE;
const TRUE = win32.TRUE;
const L = win32.L;
const HINSTANCE = win32.HINSTANCE;
const MSG = win32.MSG;
const HWND = win32.HWND;
const HDC = win32.HDC;
const LPARAM = win32.LPARAM;
const WPARAM = win32.WPARAM;
const LRESULT = win32.LRESULT;
const RECT = win32.RECT;
const CW_USEDEFAULT = win32.CW_USEDEFAULT;
const WM_CREATE = win32.WM_CREATE;
const WM_SIZE = win32.WM_SIZE;
const WM_LBUTTONDOWN = win32.WM_LBUTTONDOWN;
const WM_SETFOCUS = win32.WM_SETFOCUS;
const WM_KILLFOCUS = win32.WM_KILLFOCUS;
const WM_KEYDOWN = win32.WM_KEYDOWN;
const WM_PAINT = win32.WM_PAINT;
const WM_DESTROY = win32.WM_DESTROY;
const SendMessage = win32.SendMessage;

const windowsx = @import("windowsx").windowsx;
const GetStockBrush = windowsx.GetStockBrush;
const HANDLE_WM_CREATE = windowsx.HANDLE_WM_CREATE;
const HANDLE_WM_SIZE = windowsx.HANDLE_WM_SIZE;
const HANDLE_WM_LBUTTONDOWN = windowsx.HANDLE_WM_LBUTTONDOWN;
const HANDLE_WM_SETFOCUS = windowsx.HANDLE_WM_SETFOCUS;
const HANDLE_WM_KILLFOCUS = windowsx.HANDLE_WM_KILLFOCUS;
const HANDLE_WM_KEYDOWN = windowsx.HANDLE_WM_KEYDOWN;
const HANDLE_WM_PAINT = windowsx.HANDLE_WM_PAINT;
const HANDLE_WM_DESTROY = windowsx.HANDLE_WM_DESTROY;
const FORWARD_WM_KEYDOWN = windowsx.FORWARD_WM_KEYDOWN;
const FORWARD_WM_LBUTTONDOWN = windowsx.FORWARD_WM_LBUTTONDOWN;

pub export fn wWinMain(
    hInstance: HINSTANCE,
    _: ?HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
    _ = pCmdLine;

    const app_name = L("Checker4");
    var wndclassex = win32.WNDCLASSEX{
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

    wndclassex.lpfnWndProc = ChildWndProc;
    wndclassex.cbWndExtra = @sizeOf(usize); // sizeof(long)
    wndclassex.hIcon = null;
    wndclassex.lpszClassName = ChildHandler.szChildClass;

    _ = win32.RegisterClassEx(&wndclassex);

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
        L("Checker4 Mouse Hit-Test Demo"),
        win32.WINDOW_STYLE.initFlags(.{
            .TILEDWINDOW = 1, // .OVERLAPPEDWINDOW equivalent
        }),
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

const Handler = struct {
    const DIVISIONS = 5;
    hwndChild: [DIVISIONS][DIVISIONS]?HWND = undefined,
    idFocus: i32 = 0,

    pub fn OnCreate(self: *Handler, hwnd: HWND, cs: *win32.CREATESTRUCT) LRESULT {
        _ = cs;

        var i: usize = 0;
        while (i < DIVISIONS) : (i += 1) {
            var j: usize = 0;
            while (j < DIVISIONS) : (j += 1) {
                self.hwndChild[i][j] = win32.CreateWindowEx(
                    win32.WINDOW_EX_STYLE.initFlags(.{}),
                    ChildHandler.szChildClass,
                    null,
                    win32.WINDOW_STYLE.initFlags(.{ .CHILD = 1, .VISIBLE = 1 }),
                    0,
                    0,
                    0,
                    0,
                    hwnd,
                    @intToPtr(?win32.HMENU, (j << 8 | i)),
                    @intToPtr(?HINSTANCE, @bitCast(usize, win32.GetWindowLongPtr(hwnd, win32.GWLP_HINSTANCE))),
                    null,
                );
            }
        }
        return 0;
    }

    pub fn OnSize(self: *Handler, _: HWND, _: u32, cxClient: i16, cyClient: i16) void {
        var cxBlock = @divTrunc(cxClient, DIVISIONS);
        var cyBlock = @divTrunc(cyClient, DIVISIONS);
        var i: usize = 0;
        while (i < DIVISIONS) : (i += 1) {
            var j: usize = 0;
            while (j < DIVISIONS) : (j += 1) {
                var x = @intCast(i32, i);
                var y = @intCast(i32, j);
                _ = win32.MoveWindow(
                    self.hwndChild[i][j],
                    x * cxBlock,
                    y * cyBlock,
                    cxBlock,
                    cyBlock,
                    TRUE,
                );
            }
        }
    }

    pub fn OnLButtonDown(_: *Handler, _: HWND, _: bool, _: i16, _: i16, _: u32) void {
        _ = win32.MessageBeep(0);
    }

    pub fn OnSetFocus(self: *Handler, hwnd: HWND, _: ?HWND) void {
        _ = win32.SetFocus(win32.GetDlgItem(hwnd, self.idFocus));
    }

    pub fn OnKey(self: *Handler, hwnd: HWND, vk: win32.VIRTUAL_KEY, fDown: bool, cRepeat: i16, flags: u16) void {
        _ = hwnd;
        _ = fDown;
        _ = cRepeat;
        _ = flags;

        var x = self.idFocus & 0xFF;
        var y = self.idFocus >> 8;

        switch (vk) {
            win32.VK_UP => y -= 1,
            win32.VK_DOWN => y += 1,
            win32.VK_LEFT => x -= 1,
            win32.VK_RIGHT => x += 1,
            win32.VK_HOME => {
                x = 0;
                y = 0;
            },
            win32.VK_END => {
                x = DIVISIONS - 1;
                y = DIVISIONS - 1;
            },
            else => return,
        }

        x = @mod(x + DIVISIONS, DIVISIONS);
        y = @mod(y + DIVISIONS, DIVISIONS);

        self.idFocus = y << 8 | x;

        _ = win32.SetFocus(win32.GetDlgItem(hwnd, self.idFocus));
    }

    pub fn OnDestroy(_: *Handler, _: HWND) void {
        win32.PostQuitMessage(0);
    }
};

const ChildHandler = struct {
    pub const szChildClass = L("Checker3_Child");

    pub fn OnCreate(self: *ChildHandler, hwnd: HWND, cs: *win32.CREATESTRUCT) LRESULT {
        _ = self;
        _ = cs;

        _ = win32.SetWindowLongPtr(hwnd, win32.GWLP_USERDATA, 0); // on/off flag
        return 0;
    }

    pub fn OnKey(self: *ChildHandler, hwnd: HWND, vk: win32.VIRTUAL_KEY, fDown: bool, cRepeat: i16, flags: u16) void {
        _ = self;
        _ = fDown;

        // Send most key presses to the parent window

        if (vk != win32.VK_RETURN and vk != win32.VK_SPACE) {
            const hwndParent = win32.GetParent(hwnd).?;
            FORWARD_WM_KEYDOWN(hwndParent, vk, cRepeat, flags, win32.SendMessage);
            return;
        }

        // For Return and Space, to toggle the square...
        // falls through to the case WM_LBUTTONDOWN on the original C version.

        FORWARD_WM_LBUTTONDOWN(hwnd, false, 0, 0, 0, win32.SendMessage);
    }

    pub fn OnLButtonDown(self: *ChildHandler, hwnd: HWND, fDoubleClick: bool, x: i16, y: i16, keyFlags: u32) void {
        _ = self;
        _ = fDoubleClick;
        _ = x;
        _ = y;
        _ = keyFlags;

        const currentState = win32.GetWindowLongPtr(hwnd, win32.GWLP_USERDATA);
        _ = win32.SetWindowLongPtr(hwnd, win32.GWLP_USERDATA, 1 ^ currentState);
        _ = win32.SetFocus(hwnd);
        _ = win32.InvalidateRect(hwnd, null, FALSE);
    }

    pub fn OnSetFocus(self: *ChildHandler, hwnd: HWND, hwndOldFocus: ?HWND) void {
        _ = self;
        _ = hwndOldFocus;

        // For focus messages, invalidate the window for repaint

        handler.idFocus = @intCast(@TypeOf(handler.idFocus), win32.GetWindowLongPtr(hwnd, win32.GWLP_ID));

        // The C version "fell through" the case statement to WM_KILLFOCUS
        _ = win32.InvalidateRect(hwnd, null, TRUE);
    }

    pub fn OnKillFocus(self: *ChildHandler, hwnd: HWND, hwndNewFocus: ?HWND) void {
        _ = self;
        _ = hwndNewFocus;

        _ = win32.InvalidateRect(hwnd, null, TRUE);
    }

    pub fn OnPaint(_: *ChildHandler, hwnd: HWND) void {
        var ps: win32.PAINTSTRUCT = undefined;
        const hdc: ?HDC = win32.BeginPaint(hwnd, &ps);
        defer {
            _ = win32.EndPaint(hwnd, &ps);
        }

        var rect: RECT = undefined;
        _ = win32.GetClientRect(hwnd, &rect);
        _ = win32.Rectangle(hdc, 0, 0, rect.right, rect.bottom);

        // Draw the "x" mark

        if (win32.GetWindowLongPtr(hwnd, win32.GWLP_USERDATA) != 0) {
            _ = win32.MoveToEx(hdc, 0, 0, null);
            _ = win32.LineTo(hdc, rect.right, rect.bottom);
            _ = win32.MoveToEx(hdc, 0, rect.bottom, null);
            _ = win32.LineTo(hdc, rect.right, 0);
        }

        // Draw the "focus" rectangle

        if (hwnd == win32.GetFocus()) {
            rect.left += @divTrunc(rect.right, 10);
            rect.right -= rect.left;
            rect.top += @divTrunc(rect.bottom, 10);
            rect.bottom -= rect.top;

            _ = windowsx.SelectBrush(hdc, GetStockBrush(win32.NULL_BRUSH));
            _ = windowsx.SelectPen(hdc, win32.CreatePen(win32.PS_DASH, 0, 0));
            _ = win32.Rectangle(hdc, rect.left, rect.top, rect.right, rect.bottom);
            _ = windowsx.DeletePen(windowsx.SelectPen(hdc, windowsx.GetStockPen(win32.BLACK_PEN)));
        }
    }
};

var handler = Handler{};

fn WndProc(
    hwnd: HWND,
    message: u32,
    wParam: WPARAM,
    lParam: LPARAM,
) callconv(WINAPI) LRESULT {
    return switch (message) {
        WM_CREATE => HANDLE_WM_CREATE(hwnd, wParam, lParam, Handler, &handler),
        WM_SIZE => HANDLE_WM_SIZE(hwnd, wParam, lParam, Handler, &handler),
        WM_LBUTTONDOWN => HANDLE_WM_LBUTTONDOWN(hwnd, wParam, lParam, Handler, &handler),
        WM_SETFOCUS => HANDLE_WM_SETFOCUS(hwnd, wParam, lParam, Handler, &handler),
        WM_KEYDOWN => HANDLE_WM_KEYDOWN(hwnd, wParam, lParam, Handler, &handler),
        WM_DESTROY => HANDLE_WM_DESTROY(hwnd, wParam, lParam, Handler, &handler),
        else => win32.DefWindowProc(hwnd, message, wParam, lParam),
    };
}

var childHandler = ChildHandler{};

fn ChildWndProc(
    hwndChild: HWND,
    message: u32,
    wParam: WPARAM,
    lParam: LPARAM,
) callconv(WINAPI) LRESULT {
    return switch (message) {
        WM_CREATE => HANDLE_WM_CREATE(hwndChild, wParam, lParam, ChildHandler, &childHandler),
        WM_KEYDOWN => HANDLE_WM_KEYDOWN(hwndChild, wParam, lParam, ChildHandler, &childHandler),
        WM_LBUTTONDOWN => HANDLE_WM_LBUTTONDOWN(hwndChild, wParam, lParam, ChildHandler, childHandler),
        WM_SETFOCUS => HANDLE_WM_SETFOCUS(hwndChild, wParam, lParam, ChildHandler, &childHandler),
        WM_KILLFOCUS => HANDLE_WM_KILLFOCUS(hwndChild, wParam, lParam, ChildHandler, &childHandler),
        WM_PAINT => HANDLE_WM_PAINT(hwndChild, wParam, lParam, ChildHandler, childHandler),
        else => win32.DefWindowProc(hwndChild, message, wParam, lParam),
    };
}
