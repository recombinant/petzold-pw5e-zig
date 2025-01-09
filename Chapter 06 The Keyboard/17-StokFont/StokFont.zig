// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 5 - DevCaps1
//
// The original source code copyright:
//
// ---------------------------------------------------------
//  STOKFONT.C -- Stock Font Objects
//                (c) Charles Petzold, 1998
// ---------------------------------------------------------

// https://learn.microsoft.com/en-us/windows/apps/design/globalizing/use-utf8-code-page
pub const UNICODE = false; // use UTF-8

const std = @import("std");

const WINAPI = std.os.windows.WINAPI;

const win32 = struct {
    usingnamespace @import("zigwin32").zig;
    usingnamespace @import("zigwin32").system.library_loader;
    usingnamespace @import("zigwin32").foundation;
    usingnamespace @import("zigwin32").ui.windows_and_messaging;
    usingnamespace @import("zigwin32").graphics.gdi;
    usingnamespace @import("zigwin32").ui.controls;
    usingnamespace @import("zigwin32").ui.input.keyboard_and_mouse;
};
const BOOL = win32.BOOL;
const FALSE = win32.FALSE;
const TRUE = win32.TRUE;
const L = win32.L;
const HINSTANCE = win32.HINSTANCE;
const MSG = win32.MSG;
const HWND = win32.HWND;
const LPARAM = win32.LPARAM;
const WPARAM = win32.WPARAM;
const LRESULT = win32.LRESULT;

const windowsx = @import("windowsx");

// TODO: 2025/01/09 these is broken in zigwin32 .ansi
const IDI_APPLICATION = win32.typedConst([*:0]align(1) const u8, @as(u32, 32512));
const IDC_ARROW = win32.typedConst([*:0]align(1) const u8, @as(i32, 32512));

pub export fn wWinMain(
    hInstance: HINSTANCE,
    _: ?HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
    _ = pCmdLine;

    const app_name = "StokFont";
    const wndclassex = win32.WNDCLASSEX{
        .cbSize = @sizeOf(win32.WNDCLASSEX),
        .style = win32.WNDCLASS_STYLES{ .HREDRAW = 1, .VREDRAW = 1 },
        .lpfnWndProc = WndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hInstance,
        .hIcon = @ptrCast(win32.LoadImage(null, IDI_APPLICATION, win32.IMAGE_ICON, 0, 0, win32.IMAGE_FLAGS{ .SHARED = 1, .DEFAULTSIZE = 1 })),
        .hCursor = @ptrCast(win32.LoadImage(null, IDC_ARROW, win32.IMAGE_CURSOR, 0, 0, win32.IMAGE_FLAGS{ .SHARED = 1, .DEFAULTSIZE = 1 })),
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
    const dwStyle: win32.WINDOW_STYLE = @bitCast(ws_overlapped_window | ws_vscroll);

    // If a memory align panic occurs with CreateWindowExW() lpClassName then look at:
    // https://github.com/marlersoft/zigwin32gen/issues/9

    const hwnd = win32.CreateWindowEx(
        // https://docs.microsoft.com/en-us/windows/win32/winmsg/extended-window-styles
        win32.WINDOW_EX_STYLE{},
        @ptrFromInt(atom),
        "Stock Fonts",
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

/// stockfonts{id,name} is created at comptime for use in Handler.OnPaint()
const stockfonts = blk: {
    const fonts = [_]win32.GET_STOCK_OBJECT_FLAGS{
        win32.OEM_FIXED_FONT,
        win32.ANSI_FIXED_FONT,
        win32.ANSI_VAR_FONT,
        win32.SYSTEM_FONT,
        win32.DEVICE_DEFAULT_FONT,
        win32.SYSTEM_FIXED_FONT,
        win32.DEFAULT_GUI_FONT,
    };

    @setEvalBranchQuota(2000);
    var names: [fonts.len][]const u8 = undefined;
    for (&names, fonts) |*name, id| {
        name.* = @tagName(id);
    }

    var result: [fonts.len]struct {
        id: win32.GET_STOCK_OBJECT_FLAGS,
        name: []const u8,
    } = undefined;

    for (&result, fonts, names) |*value, font, name| {
        value.* = .{
            .id = font,
            .name = name,
        };
    }
    break :blk result;
};

const Handler = struct {
    iFont: usize = 0,

    pub fn OnCreate(_: *Handler, hwnd: HWND, _: *win32.CREATESTRUCT) LRESULT {
        var si = win32.SCROLLINFO{
            .cbSize = @sizeOf(win32.SCROLLINFO),
            .fMask = win32.SIF_RANGE,
            .nMin = 0,
            .nMax = @intCast(stockfonts.len - 1),
            .nPos = 0,
            .nPage = undefined,
            .nTrackPos = 0,
        };
        _ = win32.SetScrollInfo(hwnd, win32.SB_VERT, &si, TRUE);
        return 0;
    }

    pub fn OnDisplayChange(_: *Handler, hwnd: HWND, _: u32, _: u16, _: u16) void {
        _ = win32.InvalidateRect(hwnd, null, TRUE);
    }

    pub fn OnVScroll(self: *Handler, hwnd: HWND, _: ?HWND, code: u16, pos: i16) void {
        const last = stockfonts.len - 1;
        self.iFont = switch (code) {
            win32.SB_TOP => 0,
            win32.SB_BOTTOM => last,
            win32.SB_LINEUP, win32.SB_PAGEUP => if (self.iFont != 0) self.iFont - 1 else self.iFont,
            win32.SB_LINEDOWN, win32.SB_PAGEDOWN => self.iFont + 1,
            win32.SB_THUMBPOSITION => if (pos >= 0) @intCast(pos) else 0,
            win32.SB_THUMBTRACK => return,
            win32.SB_ENDSCROLL => return,
            else => return,
        };
        self.iFont = std.math.clamp(self.iFont, 0, last);
        _ = win32.SetScrollPos(hwnd, win32.SB_VERT, @intCast(self.iFont), TRUE);
        _ = win32.InvalidateRect(hwnd, null, TRUE);
    }

    pub fn OnKey(_: *Handler, hwnd: HWND, vk: win32.VIRTUAL_KEY, fDown: bool, cRepeat: i16, flags: u16) void {
        _ = cRepeat;
        _ = flags;
        if (fDown)
            _ = switch (vk) {
                win32.VK_HOME => win32.SendMessage(hwnd, win32.WM_VSCROLL, win32.SB_TOP, 0),
                win32.VK_END => win32.SendMessage(hwnd, win32.WM_VSCROLL, win32.SB_BOTTOM, 0),
                win32.VK_PRIOR,
                win32.VK_LEFT,
                win32.VK_UP,
                => win32.SendMessage(hwnd, win32.WM_VSCROLL, win32.SB_LINEUP, 0),
                win32.VK_NEXT,
                win32.VK_RIGHT,
                win32.VK_DOWN,
                => win32.SendMessage(hwnd, win32.WM_VSCROLL, win32.SB_PAGEDOWN, 0),
                else => return,
            };
    }

    pub fn OnPaint(self: *Handler, hwnd: HWND) void {
        var ps: win32.PAINTSTRUCT = undefined;

        const hdc: ?win32.HDC = win32.BeginPaint(hwnd, &ps);
        defer _ = win32.EndPaint(hwnd, &ps);

        _ = win32.SelectObject(hdc, windowsx.GetStockFont(stockfonts[self.iFont].id));

        var tm: win32.TEXTMETRIC = undefined;
        _ = win32.GetTextMetrics(hdc, &tm);
        const cxGrid = @max(3 * tm.tmAveCharWidth, 2 * tm.tmMaxCharWidth);
        const cyGrid = tm.tmHeight + 3;

        var szFaceName: [win32.LF_FACESIZE:0]u8 = undefined;
        _ = win32.GetTextFace(hdc, win32.LF_FACESIZE, &szFaceName);

        var buffer1: [win32.LF_FACESIZE + 64]u8 = undefined;
        var stream1 = std.io.fixedBufferStream(&buffer1);
        const writer1 = stream1.writer();

        writer1.print(
            " {s}: Face Name = {s}, CharSet = {}",
            .{ stockfonts[self.iFont].name, @as([*:0]u8, @ptrCast(&szFaceName)), tm.tmCharSet },
        ) catch unreachable;
        const written1 = stream1.getWritten();
        _ = win32.TextOut(hdc, 0, 0, @ptrCast(written1), @intCast(written1.len));

        _ = win32.SetTextAlign(hdc, @enumFromInt(@intFromEnum(win32.TA_TOP) | @intFromEnum(win32.TA_CENTER)));

        // vertical and horizontal lines

        var i: i32 = 0;
        while (i <= 16) : (i += 1) {
            if (i < 9) {
                _ = win32.MoveToEx(hdc, (i + 2) * cxGrid, 2 * cyGrid, null);
                _ = win32.LineTo(hdc, (i + 2) * cxGrid, 19 * cyGrid);
            }
            _ = win32.MoveToEx(hdc, cxGrid, (i + 3) * cyGrid, null);
            _ = win32.LineTo(hdc, 10 * cxGrid, (i + 3) * cyGrid);
        }

        // vertical and horizontal headings

        var buffer2: [16]u8 = undefined;
        var stream2 = std.io.fixedBufferStream(&buffer2);
        const writer2 = stream2.writer();

        i = 0;
        while (i < 16) : (i += 1) {
            if (i < 8) {
                stream2.reset();
                writer2.print("{X}-", .{i}) catch unreachable;
                const written2 = stream2.getWritten();
                _ = win32.TextOut(
                    hdc,
                    (2 * i + 5) * @divTrunc(cxGrid, 2),
                    2 * cyGrid + 2,
                    @ptrCast(written2),
                    @intCast(written2.len),
                );
            }
            stream2.reset();
            writer2.print("-{X}", .{i}) catch unreachable;
            const written2 = stream2.getWritten();
            _ = win32.TextOut(
                hdc,
                3 * @divTrunc(cxGrid, 2),
                (i + 3) * cyGrid + 2,
                @ptrCast(written2),
                @intCast(written2.len),
            );
        }

        // ASCII characters

        var y: i32 = 0;
        while (y < 16) : (y += 1) {
            var x: i32 = 0;
            while (x < 8) : (x += 1) {
                const c: u8 = @intCast(16 * x + y);
                _ = win32.TextOut(
                    hdc,
                    (2 * x + 5) * @divTrunc(cxGrid, 2),
                    (y + 3) * cyGrid + 2,
                    @ptrCast(&c),
                    @intCast(1),
                );
            }
        }
    }

    pub fn OnDestroy(_: *Handler, _: HWND) void {
        win32.PostQuitMessage(0);
    }
};

const HANDLE_WM_CREATE = windowsx.HANDLE_WM_CREATE;
const HANDLE_WM_DISPLAYCHANGE = windowsx.HANDLE_WM_DISPLAYCHANGE;
const HANDLE_WM_VSCROLL = windowsx.HANDLE_WM_VSCROLL;
const HANDLE_WM_KEYDOWN = windowsx.HANDLE_WM_KEYDOWN;
const HANDLE_WM_PAINT = windowsx.HANDLE_WM_PAINT;
const HANDLE_WM_DESTROY = windowsx.HANDLE_WM_DESTROY;

fn WndProc(hwnd: HWND, message: u32, wParam: WPARAM, lParam: LPARAM) callconv(WINAPI) LRESULT {
    const state = struct {
        var handler = Handler{};
    };

    return switch (message) {
        win32.WM_CREATE => HANDLE_WM_CREATE(hwnd, wParam, lParam, Handler, &state.handler),
        win32.WM_DISPLAYCHANGE => HANDLE_WM_DISPLAYCHANGE(hwnd, wParam, lParam, Handler, &state.handler),
        win32.WM_VSCROLL => HANDLE_WM_VSCROLL(hwnd, wParam, lParam, Handler, &state.handler),
        win32.WM_KEYDOWN => HANDLE_WM_KEYDOWN(hwnd, wParam, lParam, Handler, &state.handler),
        win32.WM_PAINT => HANDLE_WM_PAINT(hwnd, wParam, lParam, Handler, &state.handler),
        win32.WM_DESTROY => HANDLE_WM_DESTROY(hwnd, wParam, lParam, Handler, &state.handler),
        else => win32.DefWindowProc(hwnd, message, wParam, lParam),
    };
}
