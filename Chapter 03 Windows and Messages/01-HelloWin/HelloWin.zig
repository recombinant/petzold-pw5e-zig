// Transliterated from Charles Petzold's Programming Windows 5e
// https://www.charlespetzold.com/pw5/index.html
//
// Chapter 3 - HelloWin
//
// The original source code copyright:
//
// ------------------------------------------------------------
//  HelloWin.c -- Displays "Hello, Windows 98!" in client area
//                (c) Charles Petzold, 1998
// ------------------------------------------------------------
pub const UNICODE = true;

const std = @import("std");

const WINAPI = std.os.windows.WINAPI;

const win32 = struct {
    usingnamespace @import("win32").zig;
    usingnamespace @import("win32").system.library_loader;
    usingnamespace @import("win32").foundation;
    usingnamespace @import("win32").system.system_services;
    usingnamespace @import("win32").ui.windows_and_messaging;
    usingnamespace @import("win32").graphics.gdi;
    usingnamespace @import("win32").media.audio;
};
const BOOL = win32.BOOL;
const L = win32.L;
const HINSTANCE = win32.HINSTANCE;
const CW_USEDEFAULT = win32.CW_USEDEFAULT;
const MSG = win32.MSG;
const HWND = win32.HWND;
const HDC = win32.HDC;
const HICON = win32.HICON;
const HCURSOR = win32.HCURSOR;
const WNDCLASSEX = win32.WNDCLASSEX;
const WNDCLASS_STYLES = win32.WNDCLASS_STYLES;
const WINDOW_EX_STYLE = win32.WINDOW_EX_STYLE;
const WINDOW_STYLE = win32.WINDOW_STYLE;
const IDI_APPLICATION = win32.IDI_APPLICATION;
const IDC_ARROW = win32.IDC_ARROW;
const IMAGE_ICON = win32.IMAGE_ICON;
const IMAGE_CURSOR = win32.IMAGE_CURSOR;
const IMAGE_FLAGS = win32.IMAGE_FLAGS;
const WHITE_BRUSH = win32.WHITE_BRUSH;

const windowsx = @import("windowsx").windowsx;

pub export fn wWinMain(
    hInstance: HINSTANCE,
    _: ?HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
    _ = pCmdLine;

    const app_name = L("HelloWin");
    const wndclassex = WNDCLASSEX{
        .cbSize = @sizeOf(WNDCLASSEX),
        .style = WNDCLASS_STYLES.initFlags(.{ .HREDRAW = 1, .VREDRAW = 1 }),
        .lpfnWndProc = WndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hInstance,
        .hIcon = @ptrCast(HICON, win32.LoadImage(null, IDI_APPLICATION, IMAGE_ICON, 0, 0, IMAGE_FLAGS.initFlags(.{ .SHARED = 1, .DEFAULTSIZE = 1 }))),
        .hCursor = @ptrCast(HCURSOR, win32.LoadImage(null, IDC_ARROW, IMAGE_CURSOR, 0, 0, IMAGE_FLAGS.initFlags(.{ .SHARED = 1, .DEFAULTSIZE = 1 }))),
        .hbrBackground = windowsx.GetStockBrush(WHITE_BRUSH),
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
        WINDOW_EX_STYLE.initFlags(.{}),
        lpClassName,
        L("The Hello Program"),
        win32.WINDOW_STYLE.initFlags(.{
            .TILEDWINDOW = 1, // .OVERLAPPEDWINDOW equivalent
            .SYSMENU = 1,
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

    std.debug.print("normal exit", .{});

    return @bitCast(c_int, @truncate(c_uint, msg.wParam)); // WM_QUIT
}

fn WndProc(
    hwnd: HWND,
    message: u32,
    wParam: win32.WPARAM,
    lParam: win32.LPARAM,
) callconv(WINAPI) win32.LRESULT {
    switch (message) {
        win32.WM_CREATE => {
            const data = @embedFile("HelloWin.wav");
            const pointer = @intToPtr([*:0]const u16, @ptrToInt(data));
            _ = win32.PlaySound(pointer, null, win32.SND_MEMORY | win32.SND_ASYNC);
            // _ = win32.PlaySound(L("HelloWin.wav"), null, win32.SND_FILENAME | win32.SND_ASYNC);
            return 0; // message processed
        },

        win32.WM_PAINT => {
            var ps: win32.PAINTSTRUCT = undefined;
            const hdc: ?HDC = win32.BeginPaint(hwnd, &ps);

            var rect: win32.RECT = undefined;
            _ = win32.GetClientRect(hwnd, &rect);

            _ = win32.DrawText(
                hdc,
                L("Hello, Windows 98!"),
                -1,
                &rect,
                win32.DRAW_TEXT_FORMAT.initFlags(.{ .SINGLELINE = 1, .CENTER = 1, .VCENTER = 1 }),
            );

            _ = win32.EndPaint(hwnd, &ps);
            return 0; // message processed
        },

        win32.WM_DESTROY => {
            win32.PostQuitMessage(0);
            return 0; // message processed
        },
        else => return win32.DefWindowProc(hwnd, message, wParam, lParam),
    }
}
