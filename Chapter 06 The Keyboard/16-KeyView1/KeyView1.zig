// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 6 - KeyView1
//
// The original source code copyright:
//
// --------------------------------------------------------
//  KEYVIEW1.C -- Displays Keyboard and Character Messages
//                (c) Charles Petzold, 1998
// --------------------------------------------------------
pub const UNICODE = true;

const std = @import("std");

const WINAPI = std.os.windows.WINAPI;

const win32 = struct {
    usingnamespace @import("zigwin32").zig;
    usingnamespace @import("zigwin32").system.library_loader;
    usingnamespace @import("zigwin32").foundation;
    usingnamespace @import("zigwin32").system.system_services;
    usingnamespace @import("zigwin32").ui.windows_and_messaging;
    usingnamespace @import("zigwin32").graphics.gdi;
    usingnamespace @import("zigwin32").ui.controls;
    usingnamespace @import("zigwin32").ui.input.keyboard_and_mouse;
};
const BOOL = win32.BOOL;
const FALSE = win32.FALSE;
const TRUE = win32.TRUE;
const TCHAR = win32.TCHAR;
const L = win32.L;
const HINSTANCE = win32.HINSTANCE;
const MSG = win32.MSG;
const HWND = win32.HWND;
const HDC = win32.HDC;
const LPARAM = win32.LPARAM;
const WPARAM = win32.WPARAM;
const LRESULT = win32.LRESULT;
const CREATESTRUCT = win32.CREATESTRUCT;
const RECT = win32.RECT;
const TEXTMETRIC = win32.TEXTMETRIC;
const VIRTUAL_KEY = win32.VIRTUAL_KEY;

const windowsx = @import("windowsx");

pub export fn wWinMain(
    hInstance: HINSTANCE,
    _: ?HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
    _ = pCmdLine;

    const app_name = L("KeyView1");
    const wndclassex = win32.WNDCLASSEX{
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

    const ws_overlapped_window: u32 = @bitCast(win32.WS_OVERLAPPEDWINDOW);
    const ws_vscroll: u32 = @bitCast(win32.WS_VSCROLL);
    const ws_hscroll: u32 = @bitCast(win32.WS_HSCROLL);
    const dwStyle: win32.WINDOW_STYLE = @bitCast(ws_overlapped_window | ws_vscroll | ws_hscroll);

    // If a memory align panic occurs with CreateWindowExW() lpClassName then look at:
    // https://github.com/marlersoft/zigwin32gen/issues/9

    const hwnd = win32.CreateWindowEx(
        // https://docs.microsoft.com/en-us/windows/win32/winmsg/extended-window-styles
        win32.WINDOW_EX_STYLE{},
        @ptrFromInt(atom),
        L("Get System Metrics No. 4"),
        dwStyle,
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

const Handler = struct {
    cxClientMax: i32 = undefined,
    cyClientMax: i32 = undefined,
    cxChar: i32 = undefined,
    cyChar: i32 = undefined,
    cxClient: i32 = undefined,
    cyClient: i32 = undefined,
    cLinesMax: i32 = undefined,
    rectScroll: RECT = undefined,

    fn updateParams(self: *Handler, hwnd: HWND) void {
        // Get maximum size of client area

        self.cxClientMax = win32.GetSystemMetrics(win32.SM_CXMAXIMIZED);
        self.cyClientMax = win32.GetSystemMetrics(win32.SM_CYMAXIMIZED);

        // Get character size for fixed-pitch font
        {
            const hdc = win32.GetDC(hwnd);
            defer _ = win32.ReleaseDC(hwnd, hdc);

            _ = windowsx.SelectFont(hdc, windowsx.GetStockFont(win32.SYSTEM_FIXED_FONT));
            var tm: TEXTMETRIC = undefined;
            _ = win32.GetTextMetrics(hdc, &tm);
            self.cxChar = tm.tmAveCharWidth;
            self.cyChar = tm.tmHeight;
        }

        self.cLinesMax = @max(2, @divTrunc(self.cyClientMax, self.cyChar) - 2);

        pmsg.ensureTotalCapacity(@intCast(self.cLinesMax)) catch unreachable;

        self.calcScrollingRectangle(hwnd);
    }

    fn calcScrollingRectangle(self: *Handler, hwnd: HWND) void {
        self.rectScroll.left = 0;
        self.rectScroll.right = self.cxClient;
        self.rectScroll.top = self.cyChar;
        self.rectScroll.bottom = self.cyChar * @divTrunc(self.cyClient, self.cyChar);

        _ = win32.InvalidateRect(hwnd, null, TRUE);
    }

    pub fn OnCreate(self: *Handler, hwnd: HWND, _: *CREATESTRUCT) LRESULT {
        self.updateParams(hwnd);
        return 0;
    }

    pub fn OnDisplayChange(self: *Handler, hwnd: HWND, _: u32, _: u16, _: u16) void {
        self.updateParams(hwnd);
    }

    pub fn OnSize(self: *Handler, hwnd: HWND, _: u32, cxClient: i16, cyClient: i16) void {
        self.cxClient = cxClient;
        self.cyClient = cyClient;
        self.calcScrollingRectangle(hwnd);
    }

    // Note: this is not a message cracker handler function.
    pub fn storeMessage(self: *Handler, hwnd: HWND, message: u32, wParam: WPARAM, lParam: LPARAM) void {
        // Cap storage array

        while (pmsg.items.len > self.cLinesMax - 1) {
            _ = pmsg.pop();
        }

        // Store new message

        pmsg.insert(0, MSG{
            .hwnd = hwnd,
            .message = message,
            .wParam = wParam,
            .lParam = lParam,
            .pt = undefined,
            .time = undefined,
        }) catch unreachable;

        // Scroll up the display

        _ = win32.ScrollWindow(hwnd, 0, -self.cyChar, &self.rectScroll, &self.rectScroll);
    }

    pub fn OnPaint(self: *Handler, hwnd: HWND) void {
        var ps: win32.PAINTSTRUCT = undefined;
        const hdc: ?HDC = win32.BeginPaint(hwnd, &ps);
        defer _ = win32.EndPaint(hwnd, &ps);

        //                                          1         2         3         4         5         6
        //                                012345678901234567890123456789012345678901234567890123456789012
        const szTop = L("Message        Key       Char     Repeat Scan Ext ALT Prev Tran");
        const szUnd = L("_______        ___       ____     ______ ____ ___ ___ ____ ____");

        _ = windowsx.SelectFont(hdc, windowsx.GetStockFont(win32.SYSTEM_FIXED_FONT));
        _ = win32.SetBkMode(hdc, win32.TRANSPARENT);
        _ = win32.TextOut(hdc, 0, 0, szTop, szTop.len);
        _ = win32.TextOut(hdc, 0, 0, szUnd, szUnd.len);

        const messages = [8][]const u8{
            "WM_KEYDOWN",    "WM_KEYUP",
            "WM_CHAR",       "WM_DEADCHAR",
            "WM_SYSKEYDOWN", "WM_SYSKEYUP",
            "WM_SYSCHAR",    "WM_SYSDEADCHAR",
        };

        for (pmsg.items, 0..) |msg, i| {
            const iType = (msg.message == WM_CHAR or
                msg.message == WM_SYSCHAR or
                msg.message == WM_DEADCHAR or
                msg.message == WM_SYSDEADCHAR);

            // WM_CHAR lParam
            const lparam: packed struct(u32) {
                repeat_count: u16,
                scan_code: u8,
                extended: u1,
                _25: u1,
                _26: u1,
                _27: u1,
                _28: u1,
                context_code: u1,
                previous_key_state: u1,
                transistion_state: u1,
            } = @bitCast(@as(u32, @truncate(@as(usize, @bitCast(msg.lParam)))));
            const repeat_count = lparam.repeat_count;
            const scan_code = lparam.scan_code;
            const extended = if (lparam.extended == 1) "Yes" else "No";
            const context_code = if (lparam.context_code == 1) "Yes" else "No";
            const previous_key_state = if (lparam.previous_key_state == 1) "Down" else "Up";
            const transistion_state = if (lparam.transistion_state == 1) "Up" else "Down";

            // create the text line as utf-8
            var buffer: [128]u8 = undefined;
            var stream = std.io.fixedBufferStream(&buffer);
            var writer = stream.writer();

            // part 1 of 3
            writer.print("{s:<13} ", .{messages[pmsg.items[i].message - win32.WM_KEYFIRST]}) catch unreachable;
            // part 2 of 3
            if (iType) {
                // WM_CHAR, WM_SYSCHAR, WM_DEADCHAR, WM_SYSDEADCHAR
                const char_buffer_wtf16 = [1]u16{@intCast(msg.wParam)};
                var char_buffer_wtf8: [4]u8 = undefined;
                const char_len = std.unicode.utf16LeToUtf8(&char_buffer_wtf8, &char_buffer_wtf16) catch unreachable;
                writer.print(
                    "           0x{x:0>4} {s:1}",
                    .{ msg.wParam, char_buffer_wtf8[0..char_len] },
                ) catch unreachable;
            } else {
                // WM_KEYUP, WM_KEYDOWN
                var szKeyName = [_:0]u16{0} ** 32;
                // TODO: rather than utf16->utf8->utf16 szKeyName could be inserted into szBuffer at output
                const len = win32.GetKeyNameText(@truncate(msg.lParam), &szKeyName, szKeyName.len);
                var key_name: [32]u8 = undefined;
                const key_name_len = std.unicode.utf16LeToUtf8(&key_name, szKeyName[0..@intCast(len)]) catch unreachable;
                //
                writer.print(
                    "{d:3} {s:<15}",
                    .{ msg.wParam, key_name[0..key_name_len] },
                ) catch unreachable;
            }
            // part 3 of 3
            writer.print(
                " {d:6} {d:4} {s:3} {s:3} {s:4} {s:4}",
                .{
                    repeat_count,
                    scan_code,
                    extended,
                    context_code,
                    previous_key_state,
                    transistion_state,
                },
            ) catch unreachable;

            // convert the line text to unicode
            var szBuffer = [_:0]u16{0} ** 128;
            const buffer_len = std.unicode.utf8ToUtf16Le(&szBuffer, stream.getWritten()) catch unreachable;
            const iy: i32 = @intCast(i);
            const y: i32 = (@divTrunc(self.cyClient, self.cyChar) - 1 - iy) * self.cyChar;
            _ = win32.TextOut(hdc, 0, y, &szBuffer, @intCast(buffer_len));
        }
    }

    pub fn OnDestroy(_: *Handler, _: HWND) void {
        win32.PostQuitMessage(0);
    }
};

// gpa and allocator are file scope
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
var pmsg = std.ArrayList(MSG).init(allocator);

const WM_CREATE = win32.WM_CREATE;
const WM_DISPLAYCHANGE = win32.WM_DISPLAYCHANGE;
const WM_SIZE = win32.WM_SIZE;
const WM_KEYDOWN = win32.WM_KEYDOWN;
const WM_KEYUP = win32.WM_KEYUP;
const WM_CHAR = win32.WM_CHAR;
const WM_DEADCHAR = win32.WM_DEADCHAR;
const WM_SYSKEYDOWN = win32.WM_SYSKEYDOWN;
const WM_SYSKEYUP = win32.WM_SYSKEYUP;
const WM_SYSCHAR = win32.WM_SYSCHAR;
const WM_SYSDEADCHAR = win32.WM_SYSDEADCHAR;
const WM_PAINT = win32.WM_PAINT;
const WM_DESTROY = win32.WM_DESTROY;
const HANDLE_WM_CREATE = windowsx.HANDLE_WM_CREATE;
const HANDLE_WM_DISPLAYCHANGE = windowsx.HANDLE_WM_DISPLAYCHANGE;
const HANDLE_WM_SIZE = windowsx.HANDLE_WM_SIZE;
const HANDLE_WM_PAINT = windowsx.HANDLE_WM_PAINT;
const HANDLE_WM_DESTROY = windowsx.HANDLE_WM_DESTROY;

fn WndProc(hwnd: HWND, message: u32, wParam: WPARAM, lParam: LPARAM) callconv(WINAPI) LRESULT {
    const state = struct {
        var handler = Handler{};
    };

    return switch (message) {
        WM_CREATE => HANDLE_WM_CREATE(hwnd, wParam, lParam, Handler, &state.handler),
        WM_SIZE => HANDLE_WM_SIZE(hwnd, wParam, lParam, Handler, &state.handler),
        WM_DISPLAYCHANGE => HANDLE_WM_DISPLAYCHANGE(hwnd, wParam, lParam, Handler, &state.handler),
        WM_KEYDOWN, WM_KEYUP, WM_SYSKEYDOWN, WM_SYSKEYUP, WM_CHAR, WM_SYSCHAR, WM_DEADCHAR, WM_SYSDEADCHAR => blk: {
            state.handler.storeMessage(hwnd, message, wParam, lParam);
            // call DefWindowProc so Sys messages work
            break :blk win32.DefWindowProc(hwnd, message, wParam, lParam);
        },
        WM_PAINT => HANDLE_WM_PAINT(hwnd, wParam, lParam, Handler, &state.handler),
        WM_DESTROY => HANDLE_WM_DESTROY(hwnd, wParam, lParam, Handler, &state.handler),
        else => win32.DefWindowProc(hwnd, message, wParam, lParam),
    };
}