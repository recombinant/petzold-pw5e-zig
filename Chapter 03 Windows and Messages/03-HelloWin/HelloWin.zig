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
const std = @import("std");

const win32 = @import("win32").everything;
const windowsx = @import("windowsx");

pub export fn wWinMain(
    hInstance: win32.HINSTANCE,
    _: ?win32.HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(.winapi) c_int {
    _ = pCmdLine;

    const app_name = win32.L("HelloWin");
    const wndclassex: win32.WNDCLASSEXW = .{
        .cbSize = @sizeOf(win32.WNDCLASSEXW),
        .style = win32.WNDCLASS_STYLES{ .HREDRAW = 1, .VREDRAW = 1 },
        .lpfnWndProc = WndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hInstance,
        .hIcon = @ptrCast(win32.LoadImageW(null, win32.IDI_APPLICATION, win32.IMAGE_ICON, 0, 0, win32.IMAGE_FLAGS{ .SHARED = 1, .DEFAULTSIZE = 1 })),
        .hCursor = @ptrCast(win32.LoadImageW(null, win32.IDC_ARROW, win32.IMAGE_CURSOR, 0, 0, win32.IMAGE_FLAGS{ .SHARED = 1, .DEFAULTSIZE = 1 })),
        .hbrBackground = windowsx.GetStockBrush(win32.WHITE_BRUSH),
        .lpszMenuName = null,
        .lpszClassName = app_name,
        .hIconSm = null,
    };

    const atom: u16 = win32.RegisterClassExW(&wndclassex);
    if (0 == atom) {
        std.log.err("failed RegisterClassEx()", .{});
        return 0; // premature exit
    }

    // If a memory align panic occurs with CreateWindowExW() then look at:
    // https://github.com/marlersoft/zigwin32gen/issues/9

    const hwnd = win32.CreateWindowExW(
        // https://docs.microsoft.com/en-us/windows/win32/winmsg/extended-window-styles
        win32.WINDOW_EX_STYLE{},
        @ptrFromInt(atom),
        win32.L("The Hello Program"),
        win32.WS_OVERLAPPEDWINDOW,
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
        std.log.err("failed CreateWindowEx(), error {t}", .{win32.GetLastError()});
        return 0; // premature exit
    }

    _ = win32.ShowWindow(hwnd, @bitCast(nCmdShow));
    if (0 == win32.UpdateWindow(hwnd)) {
        std.log.err("failed UpdateWindow()", .{});
        return 0; // premature exit
    }

    var msg: win32.MSG = undefined;
    var ret: win32.BOOL = win32.GetMessageW(&msg, null, 0, 0); // three states: -1, 0 or non-zero

    while (0 != ret) {
        if (-1 == ret) {
            // handle the error and/or exit
            // for error call GetLastError();
            std.log.err("failed message loop, error {t}", .{win32.GetLastError()});
            return 0;
        } else {
            _ = win32.TranslateMessage(&msg);
            _ = win32.DispatchMessageW(&msg);
        }
        ret = win32.GetMessageW(&msg, null, 0, 0);
    }

    return @bitCast(@as(c_uint, @truncate(msg.wParam))); // WM_QUIT
}

fn WndProc(hwnd: win32.HWND, message: u32, wParam: win32.WPARAM, lParam: win32.LPARAM) callconv(.winapi) win32.LRESULT {
    switch (message) {
        win32.WM_CREATE => {
            const data = @embedFile("HelloWin.wav");
            _ = win32.PlaySoundW(@ptrCast(@alignCast(data)), null, win32.SND_FLAGS{ .MEMORY = 1, .ASYNC = 1 });
            return 0; // message processed
        },
        win32.WM_PAINT => {
            var ps: win32.PAINTSTRUCT = undefined;
            const hdc: ?win32.HDC = win32.BeginPaint(hwnd, &ps);

            var rect: win32.RECT = undefined;
            _ = win32.GetClientRect(hwnd, &rect);

            _ = win32.DrawTextW(
                hdc,
                win32.L("Hello, Windows 98!"),
                -1,
                &rect,
                win32.DRAW_TEXT_FORMAT{ .SINGLELINE = 1, .CENTER = 1, .VCENTER = 1 },
            );

            _ = win32.EndPaint(hwnd, &ps);
            return 0; // message processed
        },
        win32.WM_DESTROY => {
            win32.PostQuitMessage(0);
            return 0; // message processed
        },
        else => return win32.DefWindowProcW(hwnd, message, wParam, lParam),
    }
}
