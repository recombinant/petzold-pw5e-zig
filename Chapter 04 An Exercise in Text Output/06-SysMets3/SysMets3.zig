// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 4 - SysMets3
//
// The original source code copyright:
//
// ----------------------------------------------------
//  SYSMETS2.C -- System Metrics Display Program No. 3
//                (c) Charles Petzold, 1998
// ----------------------------------------------------
pub const UNICODE = true;

const std = @import("std");

const WINAPI = std.os.windows.WINAPI;

const sysmetrics = @import("sysmets").sysmetrics;
const buffer_sizes = @import("sysmets").buffer_sizes;
const num_lines = @import("sysmets").num_lines;

const win32 = struct {
    usingnamespace @import("zigwin32").zig;
    usingnamespace @import("zigwin32").system.library_loader;
    usingnamespace @import("zigwin32").foundation;
    usingnamespace @import("zigwin32").system.system_services;
    usingnamespace @import("zigwin32").ui.windows_and_messaging;
    usingnamespace @import("zigwin32").graphics.gdi;
    usingnamespace @import("zigwin32").ui.controls;
};
const BOOL = win32.BOOL;
const FALSE = win32.FALSE;
const TRUE = win32.TRUE;
const L = win32.L;
const HINSTANCE = win32.HINSTANCE;
const MSG = win32.MSG;
const HWND = win32.HWND;
const HDC = win32.HDC;
const HICON = win32.HICON;
const HCURSOR = win32.HCURSOR;
const LPARAM = win32.LPARAM;
const WPARAM = win32.WPARAM;
const LRESULT = win32.LRESULT;
const WM_CREATE = win32.WM_CREATE;
const WM_SIZE = win32.WM_SIZE;
const WM_HSCROLL = win32.WM_HSCROLL;
const WM_VSCROLL = win32.WM_VSCROLL;
const WM_PAINT = win32.WM_PAINT;
const WM_DESTROY = win32.WM_DESTROY;

const windowsx = @import("windowsx");
const GetStockBrush = windowsx.GetStockBrush;
const HANDLE_WM_CREATE = windowsx.HANDLE_WM_CREATE;
const HANDLE_WM_SIZE = windowsx.HANDLE_WM_SIZE;
const HANDLE_WM_HSCROLL = windowsx.HANDLE_WM_HSCROLL;
const HANDLE_WM_VSCROLL = windowsx.HANDLE_WM_VSCROLL;
const HANDLE_WM_PAINT = windowsx.HANDLE_WM_PAINT;
const HANDLE_WM_DESTROY = windowsx.HANDLE_WM_DESTROY;

pub export fn wWinMain(
    hInstance: HINSTANCE,
    _: ?HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
    _ = pCmdLine;

    const app_name = L("SysMets3");
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

    const ws_tiled_window: u32 = @bitCast(win32.WS_TILEDWINDOW);
    const ws_vscroll: u32 = @bitCast(win32.WS_VSCROLL);
    const ws_hscroll: u32 = @bitCast(win32.WS_HSCROLL);
    const dwStyle: win32.WINDOW_STYLE = @bitCast(ws_tiled_window | ws_vscroll | ws_hscroll);

    // If a memory align panic occurs with CreateWindowExW() lpClassName then look at:
    // https://github.com/marlersoft/zigwin32gen/issues/9

    const hwnd = win32.CreateWindowEx(
        // https://docs.microsoft.com/en-us/windows/win32/winmsg/extended-window-styles
        win32.WINDOW_EX_STYLE{},
        @ptrFromInt(atom),
        L("Get System Metrics No. 3"),
        comptime dwStyle,
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
    caps_width: i32 = undefined,
    char_width: i32 = undefined,
    char_height: i32 = undefined,
    client_width: i32 = undefined,
    client_height: i32 = undefined,
    max_column_width: i32 = undefined,

    pub fn OnCreate(self: *Handler, hwnd: HWND, _: *win32.CREATESTRUCT) LRESULT {
        {
            const hdc = win32.GetDC(hwnd);
            defer _ = win32.ReleaseDC(hwnd, hdc);

            var tm: win32.TEXTMETRIC = undefined;
            _ = win32.GetTextMetrics(hdc, &tm);
            self.char_width = tm.tmAveCharWidth;
            const factor: i32 = if (tm.tmPitchAndFamily & 1 != 0) 3 else 2;
            self.caps_width = @divTrunc(factor * self.char_width, 2);
            self.char_height = tm.tmHeight + tm.tmExternalLeading;
        }

        // Save the width of the three columns

        self.max_column_width = 40 * self.char_width + 22 * self.caps_width;

        return 0;
    }

    pub fn OnSize(self: *Handler, hwnd: HWND, _: u32, cx: i16, cy: i16) void {
        self.client_width = cx;
        self.client_height = cy;

        // Set vertical scroll bar range and page size
        {
            var si = win32.SCROLLINFO{
                .cbSize = @sizeOf(win32.SCROLLINFO),
                .fMask = win32.SCROLLINFO_MASK{ .RANGE = 1, .PAGE = 1 },
                .nMin = 0,
                .nMax = num_lines - 1,
                .nPage = @intCast(@divTrunc(self.client_height, self.char_height)),
                .nPos = undefined,
                .nTrackPos = undefined,
            };
            _ = win32.SetScrollInfo(hwnd, win32.SB_VERT, &si, TRUE);
        }

        // Set horizontal scroll bar range and page size
        {
            var si = win32.SCROLLINFO{
                .cbSize = @sizeOf(win32.SCROLLINFO),
                .fMask = win32.SCROLLINFO_MASK{ .RANGE = 1, .PAGE = 1 },
                .nMin = 0,
                .nMax = 2 + @divTrunc(self.max_column_width, self.char_width),
                .nPage = @intCast(@divTrunc(self.client_width, self.char_width)),
                .nPos = undefined,
                .nTrackPos = undefined,
            };
            _ = win32.SetScrollInfo(hwnd, win32.SB_HORZ, &si, TRUE);
        }
    }

    pub fn OnVScroll(self: *Handler, hwnd: HWND, _: ?HWND, code: u16, _: i16) void {
        // Get all the vertical scroll bar information
        var si = win32.SCROLLINFO{
            .cbSize = @sizeOf(win32.SCROLLINFO),
            .fMask = win32.SIF_ALL,
            .nMin = undefined,
            .nMax = undefined,
            .nPage = undefined,
            .nPos = undefined,
            .nTrackPos = undefined,
        };
        _ = win32.GetScrollInfo(hwnd, win32.SB_VERT, &si);

        // Save the position for comparison later on

        const iVertPos = si.nPos;

        switch (code) {
            win32.SB_TOP => si.nPos = si.nMin,
            win32.SB_BOTTOM => si.nPos = si.nMax,
            win32.SB_LINEUP => si.nPos -= 1,
            win32.SB_LINEDOWN => si.nPos += 1,
            win32.SB_PAGEUP => si.nPos -= @as(i32, @intCast(si.nPage)),
            win32.SB_PAGEDOWN => si.nPos += @as(i32, @intCast(si.nPage)),
            win32.SB_THUMBTRACK => si.nPos = si.nTrackPos,
            else => {},
        }

        // Set the position and then retrieve it.  Due to adjustments
        //   by Windows it may not be the same as the value set.

        si.fMask = win32.SIF_POS;
        _ = win32.SetScrollInfo(hwnd, win32.SB_VERT, &si, TRUE);
        _ = win32.GetScrollInfo(hwnd, win32.SB_VERT, &si);

        // If the position has changed, scroll the window and update it

        if (si.nPos != iVertPos) {
            _ = win32.ScrollWindow(hwnd, 0, self.char_height * (iVertPos - si.nPos), null, null);
            _ = win32.UpdateWindow(hwnd);
        }
    }

    pub fn OnHScroll(self: *Handler, hwnd: HWND, _: ?HWND, code: u16, _: i16) void {
        // Get all the horizontal scroll bar information
        var si = win32.SCROLLINFO{
            .cbSize = @sizeOf(win32.SCROLLINFO),
            .fMask = win32.SIF_ALL,
            .nMin = undefined,
            .nMax = undefined,
            .nPage = undefined,
            .nPos = undefined,
            .nTrackPos = undefined,
        };

        // Save the position for comparison later on

        _ = win32.GetScrollInfo(hwnd, win32.SB_HORZ, &si);
        const iHorzPos = si.nPos;

        switch (code) {
            win32.SB_LINELEFT => si.nPos -= 1,
            win32.SB_LINERIGHT => si.nPos += 1,
            win32.SB_PAGELEFT => si.nPos -= @as(i32, @intCast(si.nPage)),
            win32.SB_PAGERIGHT => si.nPos += @as(i32, @intCast(si.nPage)),
            win32.SB_THUMBPOSITION => si.nPos = si.nTrackPos,
            else => {},
        }

        // Set the position and then retrieve it.  Due to adjustments
        //   by Windows it may not be the same as the value set.

        si.fMask = win32.SIF_POS;
        _ = win32.SetScrollInfo(hwnd, win32.SB_HORZ, &si, TRUE);
        _ = win32.GetScrollInfo(hwnd, win32.SB_HORZ, &si);

        // If the position has changed, scroll the window

        if (si.nPos != iHorzPos) {
            _ = win32.ScrollWindow(hwnd, self.char_width * (iHorzPos - si.nPos), 0, null, null);
        }
    }

    pub fn OnPaint(self: *Handler, hwnd: HWND) void {
        var ps: win32.PAINTSTRUCT = undefined;
        const hdc: ?HDC = win32.BeginPaint(hwnd, &ps);
        defer _ = win32.EndPaint(hwnd, &ps);

        var si = win32.SCROLLINFO{
            .cbSize = @sizeOf(win32.SCROLLINFO),
            .fMask = win32.SCROLLINFO_MASK{ .POS = 1 },
            .nMin = undefined,
            .nMax = undefined,
            .nPage = undefined,
            .nPos = undefined,
            .nTrackPos = undefined,
        };

        // Get vertical scroll bar position
        _ = win32.GetScrollInfo(hwnd, win32.SB_VERT, &si);
        const iVertPos = si.nPos;

        // Get horizontal scroll bar position
        _ = win32.GetScrollInfo(hwnd, win32.SB_HORZ, &si);
        const iHorzPos = si.nPos;

        // Find painting limits
        const iPaintBeg = @max(0, iVertPos + @divTrunc(ps.rcPaint.top, self.char_height));
        const iPaintEnd = @min(num_lines - 1, iVertPos + @divTrunc(ps.rcPaint.bottom, self.char_height));

        const TA_LEFT = @intFromEnum(win32.TA_LEFT);
        const TA_RIGHT = @intFromEnum(win32.TA_RIGHT);
        const TA_TOP = @intFromEnum(win32.TA_TOP);
        const flagsL: win32.TEXT_ALIGN_OPTIONS = @enumFromInt(TA_LEFT | TA_TOP);
        const flagsR: win32.TEXT_ALIGN_OPTIONS = @enumFromInt(TA_RIGHT | TA_TOP);

        var i = iPaintBeg;
        while (i <= iPaintEnd) : (i += 1) {
            const metric = sysmetrics[@intCast(i)];

            const x = self.char_width * (1 - iHorzPos);
            const y = self.char_height * (i - iVertPos);

            // Convert text to Windows UTF16

            var label: [buffer_sizes.label]u16 = [_]u16{0} ** buffer_sizes.label;
            const label_len: i32 = @intCast(std.unicode.utf8ToUtf16Le(label[0..], metric.label) catch unreachable);

            var description: [buffer_sizes.description]u16 = [_]u16{0} ** buffer_sizes.description;
            const description_len: i32 = @intCast(std.unicode.utf8ToUtf16Le(description[0..], metric.description) catch unreachable);

            // Do the merry dance to remove the + sign when printing positive signed integers on Zig 0.12.0
            const slice2 = blk: {
                var buffer2: [6]u8 = [_]u8{0} ** 6;
                const value = win32.GetSystemMetrics(metric.index);
                if (value >= 0)
                    break :blk std.fmt.bufPrint(buffer2[0..], "{d:5}", .{@as(u32, @bitCast(value))}) catch unreachable
                else
                    break :blk std.fmt.bufPrint(buffer2[0..], "{d:5}", .{value}) catch unreachable;
            };
            var index: [6]u16 = [_]u16{0} ** 6;
            const index_len: i32 = @intCast(std.unicode.utf8ToUtf16Le(index[0..], slice2) catch unreachable);

            // Output text

            _ = win32.SetTextAlign(hdc, flagsL);

            _ = win32.TextOut(hdc, x, y, @ptrCast(&label), label_len);
            _ = win32.TextOut(hdc, x + 22 * self.caps_width, y, @ptrCast(&description), description_len);

            _ = win32.SetTextAlign(hdc, flagsR);

            _ = win32.TextOut(hdc, x + 22 * self.caps_width + 40 * self.char_width, y, @ptrCast(&index), index_len);
        }
    }

    pub fn OnDestroy(_: *Handler, _: HWND) void {
        win32.PostQuitMessage(0);
    }
};

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
        WM_HSCROLL => HANDLE_WM_HSCROLL(hwnd, wParam, lParam, Handler, &state.handler),
        WM_VSCROLL => HANDLE_WM_VSCROLL(hwnd, wParam, lParam, Handler, &state.handler),
        WM_PAINT => HANDLE_WM_PAINT(hwnd, wParam, lParam, Handler, &state.handler),
        WM_DESTROY => HANDLE_WM_DESTROY(hwnd, wParam, lParam, Handler, &state.handler),
        else => win32.DefWindowProc(hwnd, message, wParam, lParam),
    };
}
