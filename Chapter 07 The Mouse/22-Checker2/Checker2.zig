// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 7 - Checker2
//
// The original source code copyright:
//
// -------------------------------------------------
//  CHECKER2.C -- Mouse Hit-Test Demo Program No. 2
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
const POINT = win32.POINT;
const CW_USEDEFAULT = win32.CW_USEDEFAULT;
const SendMessage = win32.SendMessage;

const windowsx = @import("windowsx");
const GetStockBrush = windowsx.GetStockBrush;
const FORWARD_WM_LBUTTONDOWN = windowsx.FORWARD_WM_LBUTTONDOWN;

pub export fn wWinMain(
    hInstance: HINSTANCE,
    _: ?HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
    _ = pCmdLine;

    const app_name = L("Checker2");
    const wndclassex = win32.WNDCLASSEX{
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

    // If a memory align panic occurs with CreateWindowExW() lpClassName then look at:
    // https://github.com/marlersoft/zigwin32gen/issues/9

    const hwnd = win32.CreateWindowEx(
        // https://docs.microsoft.com/en-us/windows/win32/winmsg/extended-window-styles
        win32.WINDOW_EX_STYLE{},
        @ptrFromInt(atom),
        L("Checker2 Mouse Hit-Test Demo"),
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
    fState: [DIVISIONS][DIVISIONS]bool = [_][DIVISIONS]bool{[_]bool{false} ** DIVISIONS} ** DIVISIONS,
    cxBlock: i32 = undefined,
    cyBlock: i32 = undefined,

    pub fn OnSize(self: *Handler, _: HWND, _: u32, cxClient: i16, cyClient: i16) void {
        self.cxBlock = @divTrunc(cxClient, DIVISIONS);
        self.cyBlock = @divTrunc(cyClient, DIVISIONS);
    }

    pub fn OnSetFocus(self: *Handler, hwnd: HWND, hwndOldFocus: ?HWND) void {
        _ = self;
        _ = hwnd;
        _ = hwndOldFocus;
        _ = win32.ShowCursor(TRUE);
    }
    pub fn OnKillFocus(self: *Handler, hwnd: HWND, hwndNewFocus: ?HWND) void {
        _ = self;
        _ = hwnd;
        _ = hwndNewFocus;
        _ = win32.ShowCursor(FALSE);
    }

    pub fn OnLButtonDown(self: *Handler, hwnd: HWND, _: bool, xMouse: i16, yMouse: i16, _: u32) void {
        const x = @divTrunc(xMouse, self.cxBlock);
        const y = @divTrunc(yMouse, self.cyBlock);

        if (x < DIVISIONS and y < DIVISIONS) {
            const i = @as(usize, @intCast(x));
            const j = @as(usize, @intCast(y));
            self.fState[i][j] = !self.fState[i][j];

            var rect: win32.RECT = undefined;

            rect.left = x * self.cxBlock;
            rect.top = y * self.cyBlock;
            rect.right = (x + 1) * self.cxBlock;
            rect.bottom = (y + 1) * self.cyBlock;

            _ = win32.InvalidateRect(hwnd, &rect, FALSE);
        } else {
            _ = win32.MessageBeep(0);
        }
    }

    pub fn OnKey(self: *Handler, hwnd: HWND, vk: win32.VIRTUAL_KEY, fDown: bool, cRepeat: i16, flags: u16) void {
        _ = fDown;
        _ = cRepeat;
        _ = flags;

        var point: POINT = undefined;
        _ = win32.GetCursorPos(&point);
        _ = win32.ScreenToClient(hwnd, &point);

        var x = @max(0, @min(DIVISIONS - 1, @divTrunc(point.x, self.cxBlock)));
        var y = @max(0, @min(DIVISIONS - 1, @divTrunc(point.y, self.cyBlock)));

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
            win32.VK_RETURN, win32.VK_SPACE => {
                FORWARD_WM_LBUTTONDOWN(
                    hwnd,
                    false,
                    @as(i16, @truncate(x * self.cxBlock)),
                    @as(i16, @truncate(y * self.cyBlock)),
                    win32.MK_LBUTTON,
                    SendMessage,
                );
            },
            else => {},
        }

        x = @mod(x + DIVISIONS, DIVISIONS);
        y = @mod(y + DIVISIONS, DIVISIONS);

        point = .{
            .x = (x * self.cxBlock) + @divTrunc(self.cxBlock, 2),
            .y = (y * self.cyBlock) + @divTrunc(self.cyBlock, 2),
        };

        _ = win32.ClientToScreen(hwnd, &point);
        _ = win32.SetCursorPos(point.x, point.y);
    }

    pub fn OnPaint(self: *Handler, hwnd: HWND) void {
        var ps: win32.PAINTSTRUCT = undefined;
        const hdc: ?HDC = win32.BeginPaint(hwnd, &ps);
        defer _ = win32.EndPaint(hwnd, &ps);

        var i: usize = 0;
        while (i < DIVISIONS) : (i += 1) {
            const x = @as(i32, @intCast(i));
            var j: usize = 0;
            while (j < DIVISIONS) : (j += 1) {
                const y = @as(i32, @intCast(j));
                _ = win32.Rectangle(
                    hdc,
                    x * self.cxBlock,
                    y * self.cyBlock,
                    (x + 1) * self.cxBlock,
                    (y + 1) * self.cyBlock,
                );

                if (self.fState[i][j]) {
                    _ = win32.MoveToEx(hdc, x * self.cxBlock, y * self.cyBlock, null);
                    _ = win32.LineTo(hdc, (x + 1) * self.cxBlock, (y + 1) * self.cyBlock);
                    _ = win32.MoveToEx(hdc, x * self.cxBlock, (y + 1) * self.cyBlock, null);
                    _ = win32.LineTo(hdc, (x + 1) * self.cxBlock, y * self.cyBlock);
                }
            }
        }
    }

    pub fn OnDestroy(_: *Handler, _: HWND) void {
        win32.PostQuitMessage(0);
    }
};

const WM_SETFOCUS = win32.WM_SETFOCUS;
const WM_KILLFOCUS = win32.WM_KILLFOCUS;
const WM_KEYDOWN = win32.WM_KEYDOWN;
const WM_SIZE = win32.WM_SIZE;
const WM_LBUTTONDOWN = win32.WM_LBUTTONDOWN;
const WM_PAINT = win32.WM_PAINT;
const WM_DESTROY = win32.WM_DESTROY;
const HANDLE_WM_SETFOCUS = windowsx.HANDLE_WM_SETFOCUS;
const HANDLE_WM_KILLFOCUS = windowsx.HANDLE_WM_KILLFOCUS;
const HANDLE_WM_KEYDOWN = windowsx.HANDLE_WM_KEYDOWN;
const HANDLE_WM_SIZE = windowsx.HANDLE_WM_SIZE;
const HANDLE_WM_LBUTTONDOWN = windowsx.HANDLE_WM_LBUTTONDOWN;
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
        WM_SIZE => HANDLE_WM_SIZE(hwnd, wParam, lParam, Handler, &state.handler),
        WM_LBUTTONDOWN => HANDLE_WM_LBUTTONDOWN(hwnd, wParam, lParam, Handler, &state.handler),
        WM_SETFOCUS => HANDLE_WM_SETFOCUS(hwnd, wParam, lParam, Handler, &state.handler),
        WM_KILLFOCUS => HANDLE_WM_KILLFOCUS(hwnd, wParam, lParam, Handler, &state.handler),
        WM_KEYDOWN => HANDLE_WM_KEYDOWN(hwnd, wParam, lParam, Handler, &state.handler),
        WM_PAINT => HANDLE_WM_PAINT(hwnd, wParam, lParam, Handler, &state.handler),
        WM_DESTROY => HANDLE_WM_DESTROY(hwnd, wParam, lParam, Handler, &state.handler),
        else => win32.DefWindowProc(hwnd, message, wParam, lParam),
    };
}
