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
    usingnamespace @import("win32").zig;
    usingnamespace @import("win32").system.library_loader;
    usingnamespace @import("win32").foundation;
    usingnamespace @import("win32").system.system_services;
    usingnamespace @import("win32").ui.windows_and_messaging;
    usingnamespace @import("win32").graphics.gdi;
    usingnamespace @import("win32").ui.controls;
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
const CREATESTRUCT = win32.CREATESTRUCT;
const SCROLLINFO = win32.SCROLLINFO;
const SCROLLINFO_MASK = win32.SCROLLINFO_MASK;
const SIF_POS = win32.SIF_POS;
const CW_USEDEFAULT = win32.CW_USEDEFAULT;
const SB_VERT = win32.SB_VERT;
const SB_HORZ = win32.SB_HORZ;
const TA_TOP = @enumToInt(win32.TA_TOP);
const TA_LEFT = @enumToInt(win32.TA_LEFT);
const TA_RIGHT = @enumToInt(win32.TA_RIGHT);
const WS_OVERLAPPEDWINDOW = @enumToInt(win32.WS_OVERLAPPEDWINDOW);
const WS_SYSMENU = @enumToInt(win32.WS_SYSMENU);
const WS_VSCROLL = @enumToInt(win32.WS_VSCROLL);
const WS_HSCROLL = @enumToInt(win32.WS_HSCROLL);
const WM_CREATE = win32.WM_CREATE;
const WM_SIZE = win32.WM_SIZE;
const WM_HSCROLL = win32.WM_HSCROLL;
const WM_VSCROLL = win32.WM_VSCROLL;
const WM_PAINT = win32.WM_PAINT;
const WM_DESTROY = win32.WM_DESTROY;

const windowsx = @import("windowsx").windowsx;
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
        L("Get System Metrics No. 3"),
        @intToEnum(win32.WINDOW_STYLE, WS_OVERLAPPEDWINDOW | WS_SYSMENU | WS_VSCROLL | WS_HSCROLL),
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
    caps_width: i32 = undefined,
    char_width: i32 = undefined,
    char_height: i32 = undefined,
    client_width: i32 = undefined,
    client_height: i32 = undefined,
    max_column_width: i32 = undefined,

    pub fn OnCreate(self: *Handler, hwnd: HWND, _: *CREATESTRUCT) LRESULT {
        {
            const hdc = win32.GetDC(hwnd);
            defer {
                _ = win32.ReleaseDC(hwnd, hdc);
            }

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

    pub fn OnSize(self: *Handler, hwnd: HWND, _: u32, cx: i32, cy: i32) void {
        self.client_width = cx;
        self.client_height = cy;

        // Set vertical scroll bar range and page size
        {
            var si = SCROLLINFO{
                .cbSize = @sizeOf(SCROLLINFO),
                .fMask = SCROLLINFO_MASK.initFlags(.{ .RANGE = 1, .PAGE = 1 }),
                .nMin = 0,
                .nMax = num_lines - 1,
                .nPage = @intCast(u32, @divTrunc(self.client_height, self.char_height)),
                .nPos = undefined,
                .nTrackPos = undefined,
            };
            _ = win32.SetScrollInfo(hwnd, SB_VERT, &si, TRUE);
        }

        // Set horizontal scroll bar range and page size
        {
            var si = SCROLLINFO{
                .cbSize = @sizeOf(SCROLLINFO),
                .fMask = SCROLLINFO_MASK.initFlags(.{ .RANGE = 1, .PAGE = 1 }),
                .nMin = 0,
                .nMax = 2 + @divTrunc(self.max_column_width, self.char_width),
                .nPage = @intCast(u32, @divTrunc(self.client_width, self.char_width)),
                .nPos = undefined,
                .nTrackPos = undefined,
            };
            _ = win32.SetScrollInfo(hwnd, SB_HORZ, &si, TRUE);
        }
    }

    pub fn OnVScroll(self: *Handler, hwnd: HWND, _: ?HWND, code: u32, _: i32) void {
        // Get all the vertical scroll bar information
        var si = SCROLLINFO{
            .cbSize = @sizeOf(SCROLLINFO),
            .fMask = SCROLLINFO_MASK.initFlags(.{ .ALL = 1 }),
            .nMin = undefined,
            .nMax = undefined,
            .nPage = undefined,
            .nPos = undefined,
            .nTrackPos = undefined,
        };
        _ = win32.GetScrollInfo(hwnd, SB_VERT, &si);

        // Save the position for comparison later on

        const iVertPos = si.nPos;

        switch (code) {
            win32.SB_TOP => si.nPos = si.nMin,
            win32.SB_BOTTOM => si.nPos = si.nMax,
            win32.SB_LINEUP => si.nPos -= 1,
            win32.SB_LINEDOWN => si.nPos += 1,
            win32.SB_PAGEUP => si.nPos -= @intCast(i32, si.nPage),
            win32.SB_PAGEDOWN => si.nPos += @intCast(i32, si.nPage),
            win32.SB_THUMBTRACK => si.nPos = si.nTrackPos,
            else => {},
        }

        // Set the position and then retrieve it.  Due to adjustments
        //   by Windows it may not be the same as the value set.

        si.fMask = SIF_POS;
        _ = win32.SetScrollInfo(hwnd, SB_VERT, &si, TRUE);
        _ = win32.GetScrollInfo(hwnd, SB_VERT, &si);

        // If the position has changed, scroll the window and update it

        if (si.nPos != iVertPos) {
            _ = win32.ScrollWindow(hwnd, 0, self.char_height * (iVertPos - si.nPos), null, null);
            _ = win32.UpdateWindow(hwnd);
        }
    }

    pub fn OnHScroll(self: *Handler, hwnd: HWND, _: ?HWND, code: u32, _: i32) void {
        // Get all the horizontal scroll bar information
        var si = SCROLLINFO{
            .cbSize = @sizeOf(SCROLLINFO),
            .fMask = SCROLLINFO_MASK.initFlags(.{ .ALL = 1 }),
            .nMin = undefined,
            .nMax = undefined,
            .nPage = undefined,
            .nPos = undefined,
            .nTrackPos = undefined,
        };

        // Save the position for comparison later on

        _ = win32.GetScrollInfo(hwnd, SB_HORZ, &si);
        var iHorzPos = si.nPos;

        switch (code) {
            win32.SB_LINELEFT => si.nPos -= 1,
            win32.SB_LINERIGHT => si.nPos += 1,
            win32.SB_PAGELEFT => si.nPos -= @intCast(i32, si.nPage),
            win32.SB_PAGERIGHT => si.nPos += @intCast(i32, si.nPage),
            win32.SB_THUMBPOSITION => si.nPos = si.nTrackPos,
            else => {},
        }

        // Set the position and then retrieve it.  Due to adjustments
        //   by Windows it may not be the same as the value set.

        si.fMask = SIF_POS;
        _ = win32.SetScrollInfo(hwnd, SB_HORZ, &si, TRUE);
        _ = win32.GetScrollInfo(hwnd, SB_HORZ, &si);

        // If the position has changed, scroll the window

        if (si.nPos != iHorzPos) {
            _ = win32.ScrollWindow(hwnd, self.char_width * (iHorzPos - si.nPos), 0, null, null);
        }
    }

    pub fn OnPaint(self: *Handler, hwnd: HWND) void {
        var ps: win32.PAINTSTRUCT = undefined;
        const hdc: ?HDC = win32.BeginPaint(hwnd, &ps);
        defer {
            _ = win32.EndPaint(hwnd, &ps);
        }

        var si = SCROLLINFO{
            .cbSize = @sizeOf(SCROLLINFO),
            .fMask = SCROLLINFO_MASK.initFlags(.{ .POS = 1 }),
            .nMin = undefined,
            .nMax = undefined,
            .nPage = undefined,
            .nPos = undefined,
            .nTrackPos = undefined,
        };

        // Get vertical scroll bar position
        _ = win32.GetScrollInfo(hwnd, SB_VERT, &si);
        const iVertPos = si.nPos;

        // Get horizontal scroll bar position
        _ = win32.GetScrollInfo(hwnd, SB_HORZ, &si);
        const iHorzPos = si.nPos;

        // Find painting limits
        const iPaintBeg = @maximum(0, iVertPos + @divTrunc(ps.rcPaint.top, self.char_height));
        const iPaintEnd = @minimum(num_lines - 1, iVertPos + @divTrunc(ps.rcPaint.bottom, self.char_height));

        const flagsL = @intToEnum(win32.TEXT_ALIGN_OPTIONS, TA_LEFT | TA_TOP);
        const flagsR = @intToEnum(win32.TEXT_ALIGN_OPTIONS, TA_RIGHT | TA_TOP);

        var i = iPaintBeg;
        while (i <= iPaintEnd) : (i += 1) {
            const metric = sysmetrics[@intCast(usize, i)];

            const x = self.char_width * (1 - iHorzPos);
            const y = self.char_height * (i - iVertPos);

            // Convert text to Windows UTF16

            var label: [buffer_sizes.label]u16 = [_]u16{0} ** buffer_sizes.label;
            var label_len: i32 = @intCast(i32, std.unicode.utf8ToUtf16Le(label[0..], metric.label) catch unreachable);

            var description: [buffer_sizes.description]u16 = [_]u16{0} ** buffer_sizes.description;
            var description_len = @intCast(i32, std.unicode.utf8ToUtf16Le(description[0..], metric.description) catch unreachable);

            var buffer2: [6]u8 = [_]u8{0} ** 6;
            _ = std.fmt.bufPrint(buffer2[0..], "{d:5}", .{win32.GetSystemMetrics(metric.index)}) catch unreachable;

            var index: [6]u16 = [_]u16{0} ** 6;
            var index_len = @intCast(i32, std.unicode.utf8ToUtf16Le(index[0..], &buffer2) catch unreachable);

            // Output text

            _ = win32.SetTextAlign(hdc, flagsL);

            _ = win32.TextOut(hdc, x, y, &label, label_len);
            _ = win32.TextOut(hdc, x + 22 * self.caps_width, y, &description, description_len);

            _ = win32.SetTextAlign(hdc, flagsR);

            _ = win32.TextOut(hdc, x + 22 * self.caps_width + 40 * self.char_width, y, &index, index_len);
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
        WM_SIZE => return HANDLE_WM_SIZE(hwnd, wParam, lParam, Handler, &handler),
        WM_HSCROLL => return HANDLE_WM_HSCROLL(hwnd, wParam, lParam, Handler, &handler),
        WM_VSCROLL => return HANDLE_WM_VSCROLL(hwnd, wParam, lParam, Handler, &handler),
        WM_PAINT => return HANDLE_WM_PAINT(hwnd, wParam, lParam, Handler, &handler),
        WM_DESTROY => return HANDLE_WM_DESTROY(hwnd, wParam, lParam, Handler, &handler),
        else => return win32.DefWindowProc(hwnd, message, wParam, lParam),
    }
}
