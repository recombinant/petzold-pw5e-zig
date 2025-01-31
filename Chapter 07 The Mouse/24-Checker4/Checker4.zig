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
const SendMessage = win32.SendMessage;

const windowsx = @import("windowsx");
const GetStockBrush = windowsx.GetStockBrush;
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
        .style = win32.WNDCLASS_STYLES{ .HREDRAW = 1, .VREDRAW = 1 },
        .lpfnWndProc = WndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hInstance,
        .hIcon = @ptrCast(win32.LoadImage(null, win32.IDI_APPLICATION, win32.IMAGE_ICON, 0, 0, win32.IMAGE_FLAGS{ .SHARED = 1, .DEFAULTSIZE = 1 })),
        .hCursor = @ptrCast(win32.LoadImage(null, win32.IDC_ARROW, win32.IMAGE_CURSOR, 0, 0, win32.IMAGE_FLAGS{ .SHARED = 1, .DEFAULTSIZE = 1 })),
        .hbrBackground = GetStockBrush(win32.WHITE_BRUSH),
        .lpszMenuName = null,
        .lpszClassName = app_name,
        .hIconSm = null,
    };

    const atom: u16 = win32.RegisterClassEx(&wndclassex);
    if (0 == atom) {
        std.log.err("failed RegisterClassEx()", .{});
        return 0; // premature exit
    }

    wndclassex.lpfnWndProc = ChildWndProc;
    wndclassex.cbWndExtra = @sizeOf(usize); // sizeof(long)
    wndclassex.hIcon = null;
    wndclassex.lpszClassName = ChildHandler.szChildClass;

    _ = win32.RegisterClassEx(&wndclassex);

    // If a memory align panic occurs with CreateWindowExW() lpClassName then look at:
    // https://github.com/marlersoft/zigwin32gen/issues/9

    const hwnd = win32.CreateWindowEx(
        // https://docs.microsoft.com/en-us/windows/win32/winmsg/extended-window-styles
        win32.WINDOW_EX_STYLE{},
        @ptrFromInt(atom),
        L("Checker4 Mouse Hit-Test Demo"),
        win32.WS_OVERLAPPEDWINDOW,
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
                    win32.WINDOW_EX_STYLE{},
                    ChildHandler.szChildClass,
                    null,
                    win32.WINDOW_STYLE.initFlags(.{ .CHILD = 1, .VISIBLE = 1 }),
                    0,
                    0,
                    0,
                    0,
                    hwnd,
                    @ptrFromInt((j << 8 | i)),
                    @ptrFromInt(@as(usize, @bitCast(win32.GetWindowLongPtr(hwnd, win32.GWLP_HINSTANCE)))),
                    null,
                );
            }
        }
        return 0;
    }

    pub fn OnSize(self: *Handler, _: HWND, _: u32, cxClient: i16, cyClient: i16) void {
        const cxBlock = @divTrunc(cxClient, DIVISIONS);
        const cyBlock = @divTrunc(cyClient, DIVISIONS);
        var i: usize = 0;
        while (i < DIVISIONS) : (i += 1) {
            var j: usize = 0;
            while (j < DIVISIONS) : (j += 1) {
                const x: i32 = @intCast(i);
                const y: i32 = @intCast(j);
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
    const Self = @This();

    dummy: i1 = undefined, // workaround for Zig 0.10.0 issue #13451
    pub const szChildClass = L("Checker3_Child");

    pub fn OnCreate(self: *Self, hwnd: HWND, cs: *win32.CREATESTRUCT) LRESULT {
        _ = self;
        _ = cs;

        _ = win32.SetWindowLongPtr(hwnd, win32.GWLP_USERDATA, 0); // on/off flag
        return 0;
    }

    pub fn OnKey(self: *Self, hwnd: HWND, vk: win32.VIRTUAL_KEY, fDown: bool, cRepeat: i16, flags: u16) void {
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

    pub fn OnLButtonDown(_: *Self, hwnd: HWND, fDoubleClick: bool, x: i16, y: i16, keyFlags: u32) void {
        _ = fDoubleClick;
        _ = x;
        _ = y;
        _ = keyFlags;

        const currentState = win32.GetWindowLongPtr(hwnd, win32.GWLP_USERDATA);
        _ = win32.SetWindowLongPtr(hwnd, win32.GWLP_USERDATA, 1 ^ currentState);
        _ = win32.SetFocus(hwnd);
        _ = win32.InvalidateRect(hwnd, null, FALSE);
    }

    pub fn OnSetFocus(handler: *Self, hwnd: HWND, hwndOldFocus: ?HWND) void {
        _ = hwndOldFocus;

        // For focus messages, invalidate the window for repaint

        handler.idFocus = @intCast(win32.GetWindowLongPtr(hwnd, win32.GWLP_ID));

        // The C version "fell through" the case statement to WM_KILLFOCUS
        _ = win32.InvalidateRect(hwnd, null, TRUE);
    }

    pub fn OnKillFocus(_: *Self, hwnd: HWND, hwndNewFocus: ?HWND) void {
        _ = hwndNewFocus;

        _ = win32.InvalidateRect(hwnd, null, TRUE);
    }

    pub fn OnPaint(_: *Self, hwnd: HWND) void {
        var ps: win32.PAINTSTRUCT = undefined;
        const hdc: ?HDC = win32.BeginPaint(hwnd, &ps);
        defer _ = win32.EndPaint(hwnd, &ps);

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

const WM_CREATE = win32.WM_CREATE;
const WM_SIZE = win32.WM_SIZE;
const WM_LBUTTONDOWN = win32.WM_LBUTTONDOWN;
const WM_SETFOCUS = win32.WM_SETFOCUS;
const WM_KILLFOCUS = win32.WM_KILLFOCUS;
const WM_KEYDOWN = win32.WM_KEYDOWN;
const WM_PAINT = win32.WM_PAINT;
const WM_DESTROY = win32.WM_DESTROY;
const HANDLE_WM_CREATE = windowsx.HANDLE_WM_CREATE;
const HANDLE_WM_SIZE = windowsx.HANDLE_WM_SIZE;
const HANDLE_WM_LBUTTONDOWN = windowsx.HANDLE_WM_LBUTTONDOWN;
const HANDLE_WM_SETFOCUS = windowsx.HANDLE_WM_SETFOCUS;
const HANDLE_WM_KILLFOCUS = windowsx.HANDLE_WM_KILLFOCUS;
const HANDLE_WM_KEYDOWN = windowsx.HANDLE_WM_KEYDOWN;
const HANDLE_WM_PAINT = windowsx.HANDLE_WM_PAINT;
const HANDLE_WM_DESTROY = windowsx.HANDLE_WM_DESTROY;

fn WndProc(
    hwnd: HWND,
    message: u32,
    wParam: WPARAM,
    lParam: LPARAM,
) callconv(WINAPI) LRESULT {
    const state = struct {
        var handler = Handler{};
    };

    return switch (message) {
        WM_CREATE => HANDLE_WM_CREATE(hwnd, wParam, lParam, Handler, &state.handler),
        WM_SIZE => HANDLE_WM_SIZE(hwnd, wParam, lParam, Handler, &state.handler),
        WM_LBUTTONDOWN => HANDLE_WM_LBUTTONDOWN(hwnd, wParam, lParam, Handler, &state.handler),
        WM_SETFOCUS => HANDLE_WM_SETFOCUS(hwnd, wParam, lParam, Handler, &state.handler),
        WM_KEYDOWN => HANDLE_WM_KEYDOWN(hwnd, wParam, lParam, Handler, &state.handler),
        WM_DESTROY => HANDLE_WM_DESTROY(hwnd, wParam, lParam, Handler, &state.handler),
        else => win32.DefWindowProc(hwnd, message, wParam, lParam),
    };
}

fn ChildWndProc(
    hwndChild: HWND,
    message: u32,
    wParam: WPARAM,
    lParam: LPARAM,
) callconv(WINAPI) LRESULT {
    const state = struct {
        var handler = Handler{};
    };

    return switch (message) {
        WM_CREATE => HANDLE_WM_CREATE(hwndChild, wParam, lParam, ChildHandler, &state.handler),
        WM_KEYDOWN => HANDLE_WM_KEYDOWN(hwndChild, wParam, lParam, ChildHandler, &state.handler),
        WM_LBUTTONDOWN => HANDLE_WM_LBUTTONDOWN(hwndChild, wParam, lParam, ChildHandler, &state.handler),
        WM_SETFOCUS => HANDLE_WM_SETFOCUS(hwndChild, wParam, lParam, ChildHandler, &state.handler),
        WM_KILLFOCUS => HANDLE_WM_KILLFOCUS(hwndChild, wParam, lParam, ChildHandler, &state.handler),
        WM_PAINT => HANDLE_WM_PAINT(hwndChild, wParam, lParam, ChildHandler, &state.handler),
        else => win32.DefWindowProc(hwndChild, message, wParam, lParam),
    };
}
