//
const win32 = struct {
    usingnamespace @import("win32").foundation;
    usingnamespace @import("win32").graphics.gdi;
    usingnamespace @import("win32").ui.windows_and_messaging;
};
const BOOL = win32.BOOL;
const HWND = win32.HWND;
const WPARAM = win32.WPARAM;
const LPARAM = win32.LPARAM;
const LRESULT = win32.LRESULT;
const HDC = win32.HDC;
const HGDIOBJ = win32.HGDIOBJ;
const HBRUSH = win32.HBRUSH;
const CREATESTRUCT = win32.CREATESTRUCT;

pub fn DeleteBrush(hbr: HBRUSH) BOOL {
    return win32.DeleteObject(@as(HGDIOBJ, hbr));
}

pub fn SelectBrush(hdc: HDC, hbr: HBRUSH) ?HBRUSH {
    // https://docs.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-selectobject#return-value
    // TODO: HGDI_ERROR is a third possible return alternative.
    return @as(?HBRUSH, win32.SelectObject(hdc, @as(HGDIOBJ, hbr)));
}

pub fn GetStockBrush(hbrush: win32.GET_STOCK_OBJECT_FLAGS) ?HBRUSH {
    return @as(?HBRUSH, win32.GetStockObject(hbrush));
}

pub fn HANDLE_WM_CREATE(hwnd: HWND, _: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const ptr: *CREATESTRUCT = @intToPtr(*CREATESTRUCT, @bitCast(WPARAM, lParam));
    return if (handler.OnCreate(hwnd, ptr) == 0) 0 else -1;
}

pub fn HANDLE_WM_SIZE(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const state = @truncate(u32, wParam);
    const cx: i32 = @truncate(i16, lParam);
    const cy: i32 = @truncate(i16, lParam >> 16);
    handler.OnSize(hwnd, state, cx, cy);
    return 0;
}

pub fn HANDLE_WM_HSCROLL(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const hwndCtrl = @intToPtr(?HWND, @bitCast(usize, lParam));
    const code: u32 = @truncate(u16, wParam);
    const pos: i32 = @bitCast(i16, @truncate(u16, wParam >> 16));
    handler.OnHScroll(hwnd, hwndCtrl, code, pos);
    return 0;
}

pub fn HANDLE_WM_VSCROLL(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const hwndCtrl = @intToPtr(?HWND, @bitCast(usize, lParam));
    const code: u32 = @truncate(u16, wParam);
    const pos: i32 = @bitCast(i16, @truncate(u16, wParam >> 16));
    handler.OnVScroll(hwnd, hwndCtrl, code, pos);
    return 0;
}

pub fn HANDLE_WM_PAINT(hwnd: HWND, _: WPARAM, _: LPARAM, comptime T: type, handler: *T) LRESULT {
    handler.OnPaint(hwnd);
    return 0;
}

pub fn HANDLE_WM_DESTROY(hwnd: HWND, _: WPARAM, _: LPARAM, comptime T: type, handler: *T) LRESULT {
    handler.OnDestroy(hwnd);
    return 0;
}
