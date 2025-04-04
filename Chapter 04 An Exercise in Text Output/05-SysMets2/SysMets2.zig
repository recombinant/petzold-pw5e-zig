// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 4 - SysMets2
//
// The original source code copyright:
//
// ----------------------------------------------------
//  SYSMETS2.C -- System Metrics Display Program No. 2
//                (c) Charles Petzold, 1998
// ----------------------------------------------------

// 2025 01 06 because of an issue with "zig build test"
// all the windows functions in this file are explicitly
// wide. The UNICODE does not appear work with the zigwin32
// when building a test.
// pub const UNICODE = true; // used by zigwin32

const std = @import("std");

const WINAPI = std.os.windows.WINAPI;

const GetStockBrush = @import("windowsx").GetStockBrush;

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
const HICON = win32.HICON;
const HCURSOR = win32.HCURSOR;

/// The high-order word of lparam specifies the new height of the client area.
fn GetYLParam(lparam: win32.LPARAM) i32 {
    return @truncate((lparam >> 16) & 0xffff);
}

fn LoWord(wParam: win32.WPARAM) i16 {
    return @bitCast(@as(u16, @truncate(wParam & 0xffff)));
}

fn HiWord(wParam: win32.WPARAM) i16 {
    return @bitCast(@as(u16, @truncate((wParam >> 16) & 0xffff)));
}

test "GetYLParam test" {
    // Pathetic test.
    const lParam: win32.LPARAM = 0xefefefe12345867;
    try std.testing.expectEqual(GetYLParam(lParam), 0x1234);
}

test "LoWord test" {
    const wParam: win32.WPARAM = 0x56789abcdef1234;
    try std.testing.expectEqual(LoWord(wParam), 0x1234);
}

test "HiWord test" {
    const wParam: win32.WPARAM = 0x9abcdef12345678;
    try std.testing.expectEqual(HiWord(wParam), 0x1234);
}

pub export fn wWinMain(
    hInstance: HINSTANCE,
    _: ?HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
    _ = pCmdLine;

    const app_name = L("SysMets2");
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

    const ws_overlapped_window: u32 = @bitCast(win32.WS_OVERLAPPEDWINDOW);
    const ws_vscroll: u32 = @bitCast(win32.WS_VSCROLL);
    const dwStyle: win32.WINDOW_STYLE = @bitCast(ws_overlapped_window | ws_vscroll);

    // If a memory align panic occurs with CreateWindowExW() lpClassName then look at:
    // https://github.com/marlersoft/zigwin32gen/issues/9

    const hwnd = win32.CreateWindowExW(
        // https://docs.microsoft.com/en-us/windows/win32/winmsg/extended-window-styles
        win32.WINDOW_EX_STYLE{},
        @ptrFromInt(atom),
        L("Get System Metrics No. 2"),
        comptime dwStyle,
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
        std.log.err("failed CreateWindowEx(), error {}", .{win32.GetLastError()});
        return 0; // premature exit
    }

    _ = win32.ShowWindow(hwnd, @bitCast(nCmdShow));
    if (0 == win32.UpdateWindow(hwnd)) {
        std.log.err("failed UpdateWindow()", .{});
        return 0; // premature exit
    }

    var msg: win32.MSG = undefined;
    var ret: BOOL = win32.GetMessageW(&msg, null, 0, 0); // three states: -1, 0 or non-zero

    while (0 != ret) {
        if (-1 == ret) {
            // handle the error and/or exit
            // for error call GetLastError();
            std.log.err("failed message loop, error {}", .{win32.GetLastError()});
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

fn WndProc(
    hwnd: HWND,
    message: u32,
    wParam: win32.WPARAM,
    lParam: win32.LPARAM,
) callconv(WINAPI) win32.LRESULT {
    const state = struct {
        var cxChar: i32 = undefined;
        var cxCaps: i32 = undefined;
        var cyChar: i32 = undefined;
        var cyClient: i32 = undefined;
        var iVscrollPos: i32 = undefined;
    };

    switch (message) {
        win32.WM_CREATE => {
            {
                const hdc = win32.GetDC(hwnd);
                defer _ = win32.ReleaseDC(hwnd, hdc);

                var tm: win32.TEXTMETRICW = undefined;
                _ = win32.GetTextMetricsW(hdc, &tm);
                state.cxChar = tm.tmAveCharWidth;
                const factor: i32 = if (tm.tmPitchAndFamily & 1 != 0) 3 else 2;
                state.cxCaps = @divTrunc(factor * state.cxChar, 2);
                state.cyChar = tm.tmHeight + tm.tmExternalLeading;
            }

            var si = win32.SCROLLINFO{
                .cbSize = @sizeOf(win32.SCROLLINFO),
                .fMask = win32.SCROLLINFO_MASK{ .RANGE = 1, .POS = 1 },
                .nMin = 0,
                .nMax = num_lines,
                .nPos = state.iVscrollPos,
                .nPage = undefined,
                .nTrackPos = undefined,
            };
            _ = win32.SetScrollInfo(hwnd, win32.SB_VERT, &si, TRUE);

            return 0;
        },

        win32.WM_SIZE => {
            state.cyClient = GetYLParam(lParam);
            return 0;
        },

        win32.WM_VSCROLL => {
            switch (LoWord(wParam)) {
                win32.SB_LINEUP => state.iVscrollPos -= 1,
                win32.SB_LINEDOWN => state.iVscrollPos += 1,
                win32.SB_PAGEUP => state.iVscrollPos -= @divTrunc(state.cyClient, state.cyChar),
                win32.SB_PAGEDOWN => state.iVscrollPos += @divTrunc(state.cyClient, state.cyChar),
                win32.SB_THUMBPOSITION => state.iVscrollPos = HiWord(wParam),
                else => {},
            }

            state.iVscrollPos = @max(0, @min(state.iVscrollPos, num_lines - 1));

            const SB_VERT = win32.SB_VERT;
            if (state.iVscrollPos != win32.GetScrollPos(hwnd, SB_VERT)) {
                _ = win32.SetScrollPos(hwnd, SB_VERT, state.iVscrollPos, TRUE);
                _ = win32.InvalidateRect(hwnd, null, TRUE);
            }
            return 0;
        },

        win32.WM_PAINT => {
            var ps: win32.PAINTSTRUCT = undefined;
            const hdc: ?HDC = win32.BeginPaint(hwnd, &ps);
            defer _ = win32.EndPaint(hwnd, &ps);

            const TA_LEFT = @intFromEnum(win32.TA_LEFT);
            const TA_RIGHT = @intFromEnum(win32.TA_RIGHT);
            const TA_TOP = @intFromEnum(win32.TA_TOP);
            const flagsL: win32.TEXT_ALIGN_OPTIONS = @enumFromInt(TA_LEFT | TA_TOP);
            const flagsR: win32.TEXT_ALIGN_OPTIONS = @enumFromInt(TA_RIGHT | TA_TOP);

            var i: i32 = 0;
            for (sysmetrics) |metric| {
                const y: i32 = state.cyChar * (i - state.iVscrollPos);

                // Convert text to Windows UTF16

                var label: [buffer_sizes.label]u16 = [_]u16{0} ** buffer_sizes.label;
                const label_len: i32 = @intCast(std.unicode.utf8ToUtf16Le(label[0..], metric.label) catch unreachable);

                var description: [buffer_sizes.description]u16 = [_]u16{0} ** buffer_sizes.description;
                const description_len: i32 = @intCast(std.unicode.utf8ToUtf16Le(description[0..], metric.description) catch unreachable);

                var buffer2: [6]u8 = [_]u8{0} ** 6;
                const slice2 = std.fmt.bufPrint(buffer2[0..], "{d:5}", .{win32.GetSystemMetrics(metric.index)}) catch unreachable;

                var index: [6]u16 = [_]u16{0} ** 6;
                const index_len: i32 = @intCast(std.unicode.utf8ToUtf16Le(index[0..], slice2) catch unreachable);

                // Output text

                _ = win32.SetTextAlign(hdc, flagsL);

                // As text is ASCII length of string is number of characters.
                _ = win32.TextOutW(hdc, 0, y, @ptrCast(&label), label_len);
                _ = win32.TextOutW(hdc, 22 * state.cxCaps, y, @ptrCast(&description), description_len);

                _ = win32.SetTextAlign(hdc, flagsR);

                _ = win32.TextOutW(hdc, 22 * state.cxCaps + 40 * state.cxChar, y, @ptrCast(&index), index_len);

                i += 1;
            }

            return 0; // message processed
        },

        win32.WM_DESTROY => {
            win32.PostQuitMessage(0);
            return 0; // message processed
        },
        else => return win32.DefWindowProcW(hwnd, message, wParam, lParam),
    }
}
