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

fn GetStockBrush(hbrush: win32.GET_STOCK_OBJECT_FLAGS) ?win32.HBRUSH {
    return @as(?win32.HBRUSH, win32.GetStockObject(hbrush));
}

/// The high-order word of lparam specifies the new height of the client area.
fn GET_Y_LPARAM(lparam: win32.LPARAM) i32 {
    return @as(i32, @truncate(i16, (lparam >> 16) & 0xffff));
}

fn GET_X_LPARAM(lparam: win32.LPARAM) i32 {
    return @as(i32, @truncate(i16, lparam & 0xffff));
}

fn LOWORD_WP(wParam: win32.WPARAM) i16 {
    return @bitCast(i16, @truncate(u16, wParam & 0xffff));
}

fn HIWORD_WP(wParam: win32.WPARAM) i16 {
    return @bitCast(i16, @truncate(u16, (wParam >> 16) & 0xffff));
}

test "GET_Y_LPARAM test" {
    const assert = std.debug.assert;

    // Pathetic test.
    const word: win32.LPARAM = 0xefefefe12345867;
    assert(GET_Y_LPARAM(word) == 0x1234);
}

pub export fn wWinMain(
    hInstance: HINSTANCE,
    _: ?HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
    _ = pCmdLine;

    const app_name = L("SysMets2");
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
        @intToEnum(win32.WINDOW_STYLE, WS_OVERLAPPEDWINDOW | WS_SYSMENU | WS_VSCROLL),
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

fn WndProc(
    hwnd: HWND,
    message: u32,
    wParam: win32.WPARAM,
    lParam: win32.LPARAM,
) callconv(WINAPI) win32.LRESULT {
    const state = struct {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        var cxChar: i32 = undefined;
        var cxCaps: i32 = undefined;
        var cyChar: i32 = undefined;
        var cyClient: i32 = undefined;
        var cxClient: i32 = undefined;
        var iMaxWidth: i32 = undefined;
    };
    const num_lines = @intCast(i32, sysmetrics.len);

    switch (message) {
        win32.WM_CREATE => {
            {
                const hdc = win32.GetDC(hwnd);
                defer {
                    _ = win32.ReleaseDC(hwnd, hdc);
                }

                var tm: win32.TEXTMETRIC = undefined;
                _ = win32.GetTextMetrics(hdc, &tm);
                state.cxChar = tm.tmAveCharWidth;
                const factor: i32 = if (tm.tmPitchAndFamily & 1 != 0) 3 else 2;
                state.cxCaps = @divTrunc(factor * state.cxChar, 2);
                state.cyChar = tm.tmHeight + tm.tmExternalLeading;
            }

            // Save the width of the three columns

            state.iMaxWidth = 40 * state.cxChar + 22 * state.cxCaps;

            return 0;
        },

        win32.WM_SIZE => {
            state.cxClient = GET_X_LPARAM(lParam);
            state.cyClient = GET_Y_LPARAM(lParam);

            // Set vertical scroll bar range and page size
            {
                var si = SCROLLINFO{
                    .cbSize = @sizeOf(SCROLLINFO),
                    .fMask = SCROLLINFO_MASK.initFlags(.{ .RANGE = 1, .PAGE = 1 }),
                    .nMin = 0,
                    .nMax = num_lines - 1,
                    .nPage = @intCast(u32, @divTrunc(state.cyClient, state.cyChar)),
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
                    .nMax = 2 + @divTrunc(state.iMaxWidth, state.cxChar),
                    .nPage = @intCast(u32, @divTrunc(state.cxClient, state.cxChar)),
                    .nPos = undefined,
                    .nTrackPos = undefined,
                };
                _ = win32.SetScrollInfo(hwnd, SB_HORZ, &si, TRUE);
            }
            return 0;
        },

        win32.WM_VSCROLL => {
            // Get all the vertial scroll bar information
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

            switch (LOWORD_WP(wParam)) {
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
                _ = win32.ScrollWindow(hwnd, 0, state.cyChar * (iVertPos - si.nPos), null, null);
                _ = win32.UpdateWindow(hwnd);
            }
            return 0;
        },

        win32.WM_HSCROLL => {
            // Get all the vertial scroll bar information
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

            switch (LOWORD_WP(wParam)) {
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
                _ = win32.ScrollWindow(hwnd, state.cxChar * (iHorzPos - si.nPos), 0, null, null);
            }
            return 0;
        },

        win32.WM_PAINT => {
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
            const iPaintBeg = @maximum(0, iVertPos + @divTrunc(ps.rcPaint.top, state.cyChar));
            const iPaintEnd = @minimum(num_lines - 1, iVertPos + @divTrunc(ps.rcPaint.bottom, state.cyChar));

            const allocator = state.gpa.allocator();

            var i = iPaintBeg;
            while (i <= iPaintEnd) : (i += 1) {
                const metric = sysmetrics[@intCast(usize, i)];

                const x = state.cxChar * (1 - iHorzPos);
                const y = state.cyChar * (i - iVertPos);

                const label = std.unicode.utf8ToUtf16LeWithNull(allocator, metric.label) catch unreachable;
                const description = std.unicode.utf8ToUtf16LeWithNull(allocator, metric.description) catch unreachable;
                defer {
                    allocator.free(label);
                    allocator.free(description);
                }

                const flagsL = @intToEnum(win32.TEXT_ALIGN_OPTIONS, TA_LEFT | TA_TOP);
                _ = win32.SetTextAlign(hdc, flagsL);

                // As text is ASCII length of string is number of characters.
                _ = win32.TextOut(hdc, x, y, label, @intCast(i32, label.len));
                _ = win32.TextOut(hdc, x + 22 * state.cxCaps, y, description, @intCast(i32, description.len));

                const temp = std.fmt.allocPrint(allocator, "{d}", .{win32.GetSystemMetrics(metric.index)}) catch unreachable;
                const index = std.unicode.utf8ToUtf16LeWithNull(allocator, temp) catch unreachable;
                const index_length = @intCast(i32, temp.len); // ASCII, so Ok
                allocator.free(temp);
                defer allocator.free(index);

                const flagsR = @intToEnum(win32.TEXT_ALIGN_OPTIONS, TA_RIGHT | TA_TOP);
                _ = win32.SetTextAlign(hdc, flagsR);

                _ = win32.TextOut(hdc, x + 22 * state.cxCaps + 40 * state.cxChar, y, index, index_length);
            }

            return 0; // message processed
        },

        win32.WM_DESTROY => {
            win32.PostQuitMessage(0);
            return 0; // message processed
        },
        else => return win32.DefWindowProc(hwnd, message, wParam, lParam),
    }
}
