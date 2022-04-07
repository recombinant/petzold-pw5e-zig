// Message Crackers as per the original windowsx.h
const win32 = struct {
    usingnamespace @import("win32").foundation;
    usingnamespace @import("win32").graphics.gdi;
    usingnamespace @import("win32").ui.windows_and_messaging;
};
const BOOL = win32.BOOL;
const FALSE = win32.FALSE;
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

// 0x0001
// pub fn OnCreate(self: *T, hwnd: HWND, cs: *CREATESTRUCT) LRESULT
pub fn HANDLE_WM_CREATE(hwnd: HWND, _: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const ptr: *CREATESTRUCT = @intToPtr(*CREATESTRUCT, @bitCast(usize, lParam));
    return if (handler.OnCreate(hwnd, ptr) == 0) 0 else -1;
}

// 0x0002
// pub fn OnDestroy(self: *T, hwnd: HWND) void
pub fn HANDLE_WM_DESTROY(hwnd: HWND, _: WPARAM, _: LPARAM, comptime T: type, handler: *T) LRESULT {
    handler.OnDestroy(hwnd);
    return 0;
}

// 0x0005
// pub fn OnSize(self: *T, hwnd: HWND, state: u32, cx: i32, cy: i32) void
pub fn HANDLE_WM_SIZE(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const state = @truncate(u32, wParam);
    const cx: i32 = @truncate(i16, lParam);
    const cy: i32 = @truncate(i16, lParam >> 16);
    handler.OnSize(hwnd, state, cx, cy);
    return 0;
}

// 0x000f
// pub fn OnPaint(self: *T, hwnd: HWND) void
pub fn HANDLE_WM_PAINT(hwnd: HWND, _: WPARAM, _: LPARAM, comptime T: type, handler: *T) LRESULT {
    handler.OnPaint(hwnd);
    return 0;
}

// 0x0114
// pub fn OnHScroll(self: *T, hwnd: HWND, hwndCtrl: ?HWND, code: u32, pos: i32) void
pub fn HANDLE_WM_HSCROLL(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const hwndCtrl = @intToPtr(?HWND, @bitCast(usize, lParam));
    const code: u32 = @truncate(u16, wParam);
    const pos: i32 = @bitCast(i16, @truncate(u16, wParam >> 16));
    handler.OnHScroll(hwnd, hwndCtrl, code, pos);
    return 0;
}

// 0x0115
// pub fn OnVScroll(self: *T, hwnd: HWND, hwndCtrl: ?HWND, code: u32, pos: i32) void
pub fn HANDLE_WM_VSCROLL(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const hwndCtrl = @intToPtr(?HWND, @bitCast(usize, lParam));
    const code: u32 = @truncate(u16, wParam);
    const pos: i32 = @bitCast(i16, @truncate(u16, wParam >> 16));
    handler.OnVScroll(hwnd, hwndCtrl, code, pos);
    return 0;
}

// 0x0200
// pub fn OnMouseMove(self: *T, hwnd: HWND, x: i32, y: i32, keyFlags: u32) void
pub fn HANDLE_WM_MOUSEMOVE(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const x: i32 = @truncate(i16, lParam);
    const y: i32 = @truncate(i16, lParam >> 16);
    const keyFlags = @truncate(u32, wParam);
    handler.OnMouseMove(hwnd, x, y, keyFlags);
    return 0;
}

// 0x0201
// pub fn OnLButtonDown(self: *T, hwnd: HWND, fDoubleClick: BOOL, x: i32, y: i32, keyFlags: u32) void
pub fn HANDLE_WM_LBUTTONDOWN(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const x: i32 = @truncate(i16, lParam);
    const y: i32 = @truncate(i16, lParam >> 16);
    const keyFlags = @truncate(u32, wParam);
    handler.OnLButtonDown(hwnd, FALSE, x, y, keyFlags);
    return 0;
}

// 0x0204
// pub fn OnRButtonDown(self: *T, hwnd: HWND, fDoubleClick: BOOL, x: i32, y: i32, keyFlags: u32) void
pub fn HANDLE_WM_RBUTTONDOWN(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const x: i32 = @truncate(i16, lParam);
    const y: i32 = @truncate(i16, lParam >> 16);
    const keyFlags = @truncate(u32, wParam);
    handler.OnRButtonDown(hwnd, FALSE, x, y, keyFlags);
    return 0;
}
