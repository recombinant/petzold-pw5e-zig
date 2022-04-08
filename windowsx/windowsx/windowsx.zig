// Message Crackers as per the original windowsx.h
const win32 = struct {
    usingnamespace @import("win32").zig;
    usingnamespace @import("win32").foundation;
    usingnamespace @import("win32").graphics.gdi;
    usingnamespace @import("win32").ui.windows_and_messaging;
    usingnamespace @import("win32").ui.input.keyboard_and_mouse;
};
const BOOL = win32.BOOL;
const TRUE = win32.TRUE;
const FALSE = win32.FALSE;
const HWND = win32.HWND;
const WPARAM = win32.WPARAM;
const LPARAM = win32.LPARAM;
const LRESULT = win32.LRESULT;
const HDC = win32.HDC;
const HGDIOBJ = win32.HGDIOBJ;
const HBRUSH = win32.HBRUSH;
const HPEN = win32.HPEN;
const HFONT = win32.HFONT;
const CREATESTRUCT = win32.CREATESTRUCT;
const VIRTUAL_KEY = win32.VIRTUAL_KEY;

// ----------------------------------------------------------------------------

pub fn DeletePen(hbr: ?HPEN) BOOL {
    return win32.DeleteObject(@as(?HGDIOBJ, hbr));
}

pub fn SelectPen(hdc: ?HDC, hbr: ?HPEN) ?HPEN {
    // https://docs.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-selectobject#return-value
    // TODO: HGDI_ERROR is a third possible return alternative.
    return @as(?HPEN, win32.SelectObject(hdc, @as(?HGDIOBJ, hbr)));
}

pub fn GetStockPen(hpen: win32.GET_STOCK_OBJECT_FLAGS) ?HPEN {
    return @as(?HPEN, win32.GetStockObject(hpen));
}

// --------------------------------------------------------

pub fn DeleteBrush(hbr: ?HBRUSH) BOOL {
    return win32.DeleteObject(@as(?HGDIOBJ, hbr));
}

pub fn SelectBrush(hdc: ?HDC, hbr: ?HBRUSH) ?HBRUSH {
    // https://docs.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-selectobject#return-value
    // TODO: HGDI_ERROR is a third possible return alternative.
    return @as(?HBRUSH, win32.SelectObject(hdc, @as(?HGDIOBJ, hbr)));
}

pub fn GetStockBrush(hbrush: win32.GET_STOCK_OBJECT_FLAGS) ?HBRUSH {
    return @as(?HBRUSH, win32.GetStockObject(hbrush));
}

// --------------------------------------------------------

pub fn DeleteFont(hbr: ?HFONT) BOOL {
    return win32.DeleteObject(@as(?HGDIOBJ, hbr));
}

pub fn SelectFont(hdc: ?HDC, hbr: ?HFONT) ?HFONT {
    // https://docs.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-selectobject#return-value
    // TODO: HGDI_ERROR is a third possible return alternative.
    return @as(?HFONT, win32.SelectObject(hdc, @as(?HGDIOBJ, hbr)));
}

pub fn GetStockFont(hbrush: win32.GET_STOCK_OBJECT_FLAGS) ?HFONT {
    return @as(?HFONT, win32.GetStockObject(hbrush));
}

// ----------------------------------------------------------------------------

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

// 0x0100
// pub fn OnKey(self: *T, hwnd: HWND, vk: VIRTUAL_KEY, fDown: BOOL, cRepeat: i32, flags: u32) void
pub fn HANDLE_WM_KEYDOWN(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const cRepeat: i32 = @truncate(i16, lParam);
    const flags: u32 = @bitCast(u16, @truncate(i16, lParam >> 16));
    const vk = @intToEnum(VIRTUAL_KEY, @truncate(u16, wParam));
    handler.OnKey(hwnd, vk, TRUE, cRepeat, flags);
    return 0;
}

// 0x0101
// pub fn OnKey(self: *T, hwnd: HWND, vk: VIRTUAL_KEY, fDown: BOOL, cRepeat: i32, flags: u32) void
pub fn HANDLE_WM_KEYUP(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const cRepeat: i32 = @truncate(i16, lParam);
    const flags: u32 = @bitCast(u16, @truncate(i16, lParam >> 16));
    const vk = @intToEnum(VIRTUAL_KEY, @truncate(u16, wParam));
    handler.OnKey(hwnd, vk, FALSE, cRepeat, flags);
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

// 0x0202
// pub fn OnLButtonUp(self: *T, hwnd: HWND, x: i32, y: i32, keyFlags: u32) void
pub fn HANDLE_WM_LBUTTONUP(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const x: i32 = @truncate(i16, lParam);
    const y: i32 = @truncate(i16, lParam >> 16);
    const keyFlags = @truncate(u32, wParam);
    handler.OnLButtonUp(hwnd, x, y, keyFlags);
    return 0;
}

// 0x0203
// pub fn OnLButtonDown(self: *T, hwnd: HWND, fDoubleClick: BOOL, x: i32, y: i32, keyFlags: u32) void
pub fn HANDLE_WM_LBUTTONDBLCLK(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const x: i32 = @truncate(i16, lParam);
    const y: i32 = @truncate(i16, lParam >> 16);
    const keyFlags = @truncate(u32, wParam);
    handler.OnLButtonDown(hwnd, TRUE, x, y, keyFlags);
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

// 0x0205
// pub fn OnRButtonUp(self: *T, hwnd: HWND, x: i32, y: i32, keyFlags: u32) void
pub fn HANDLE_WM_RBUTTONUP(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const x: i32 = @truncate(i16, lParam);
    const y: i32 = @truncate(i16, lParam >> 16);
    const keyFlags = @truncate(u32, wParam);
    handler.OnRButtonUp(hwnd, x, y, keyFlags);
    return 0;
}

// 0x0206
// pub fn OnRButtonDown(self: *T, hwnd: HWND, fDoubleClick: BOOL, x: i32, y: i32, keyFlags: u32) void
pub fn HANDLE_WM_RBUTTONDBLCLK(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const x: i32 = @truncate(i16, lParam);
    const y: i32 = @truncate(i16, lParam >> 16);
    const keyFlags = @truncate(u32, wParam);
    handler.OnRButtonDown(hwnd, TRUE, x, y, keyFlags);
    return 0;
}
// 0x0207
// pub fn OnMButtonDown(self: *T, hwnd: HWND, fDoubleClick: BOOL, x: i32, y: i32, keyFlags: u32) void
pub fn HANDLE_WM_MBUTTONDOWN(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const x: i32 = @truncate(i16, lParam);
    const y: i32 = @truncate(i16, lParam >> 16);
    const keyFlags = @truncate(u32, wParam);
    handler.OnMButtonDown(hwnd, FALSE, x, y, keyFlags);
    return 0;
}

// 0x0208
// pub fn OnMButtonUp(self: *T, hwnd: HWND, x: i32, y: i32, keyFlags: u32) void
pub fn HANDLE_WM_MBUTTONUP(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const x: i32 = @truncate(i16, lParam);
    const y: i32 = @truncate(i16, lParam >> 16);
    const keyFlags = @truncate(u32, wParam);
    handler.OnMButtonUp(hwnd, x, y, keyFlags);
    return 0;
}

// 0x0209
// pub fn OnMButtonDown(self: *T, hwnd: HWND, fDoubleClick: BOOL, x: i32, y: i32, keyFlags: u32) void
pub fn HANDLE_WM_MBUTTONDBLCLK(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const x: i32 = @truncate(i16, lParam);
    const y: i32 = @truncate(i16, lParam >> 16);
    const keyFlags = @truncate(u32, wParam);
    handler.OnMButtonDown(hwnd, TRUE, x, y, keyFlags);
    return 0;
}
