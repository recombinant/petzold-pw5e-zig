// Message Crackers as per the original windowsx.h
const win32 = struct {
    usingnamespace @import("win32").zig;
    usingnamespace @import("win32").foundation;
    usingnamespace @import("win32").graphics.gdi;
    usingnamespace @import("win32").ui.windows_and_messaging;
    usingnamespace @import("win32").ui.input.keyboard_and_mouse;
};
const BOOL = win32.BOOL;
const TCHAR = win32.TCHAR;
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

const WINAPI = @import("std").os.windows.WINAPI;
const forwarder_type = fn (hWnd: ?HWND, msg: u32, wParam: WPARAM, lParam: LPARAM) callconv(WINAPI) LRESULT;

// 0x0001 WM_CREATE
// pub fn OnCreate(self: *T, hwnd: HWND, cs: *CREATESTRUCT) LRESULT
pub fn HANDLE_WM_CREATE(hwnd: HWND, _: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const ptr = @intToPtr(*CREATESTRUCT, @bitCast(usize, lParam));
    return if (handler.OnCreate(hwnd, ptr) == 0) 0 else -1;
}

// 0x0002 WM_DESTROY
// pub fn OnDestroy(self: *T, hwnd: HWND) void
pub fn HANDLE_WM_DESTROY(hwnd: HWND, _: WPARAM, _: LPARAM, comptime T: type, handler: *T) LRESULT {
    handler.OnDestroy(hwnd);
    return 0;
}

// 0x0005 WM_SIZE
// pub fn OnSize(self: *T, hwnd: HWND, state: u32, cxClient: i32, cyClient: i32) void
pub fn HANDLE_WM_SIZE(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const state = @truncate(u32, wParam);
    const cxClient = @truncate(i16, lParam);
    const cyClient = @truncate(i16, lParam >> 16);
    handler.OnSize(hwnd, state, cxClient, cyClient);
    return 0;
}

// 0x000f WM_PAINT
// pub fn OnPaint(self: *T, hwnd: HWND) void
pub fn HANDLE_WM_PAINT(hwnd: HWND, _: WPARAM, _: LPARAM, comptime T: type, handler: *T) LRESULT {
    handler.OnPaint(hwnd);
    return 0;
}

// 0x007E WM_DISPLAYCHANGE
// pub fn OnDisplayChange(self: *T, hwnd:  HWND, bitsPerPixel: u32, cxScreen: u32, cyScreen: u32) void
pub fn HANDLE_WM_DISPLAYCHANGE(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const bitsPerPixel = @truncate(u32, wParam);
    const cxScreen = @bitCast(u16, @truncate(i16, lParam));
    const cyScreen = @bitCast(u16, @truncate(i16, lParam >> 16));
    handler.OnDisplayChange(hwnd, bitsPerPixel, cxScreen, cyScreen);
    return 0;
}

// 0x0100 WM_KEYDOWN
// pub fn OnKey(self: *T, hwnd: HWND, vk: VIRTUAL_KEY, fDown: bool, cRepeat: i32, flags: u32) void
pub fn HANDLE_WM_KEYDOWN(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const cRepeat = @truncate(i16, lParam);
    const flags = @bitCast(u16, @truncate(i16, lParam >> 16));
    const vk = @intToEnum(VIRTUAL_KEY, @truncate(u16, wParam));
    handler.OnKey(hwnd, vk, true, cRepeat, flags);
    return 0;
}

// 0x0101 WM_KEYUP
// pub fn OnKey(self: *T, hwnd: HWND, vk: VIRTUAL_KEY, fDown: bool, cRepeat: i32, flags: u32) void
pub fn HANDLE_WM_KEYUP(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const cRepeat = @truncate(i16, lParam);
    const flags = @bitCast(u16, @truncate(i16, lParam >> 16));
    const vk = @intToEnum(VIRTUAL_KEY, @truncate(u16, wParam));
    handler.OnKey(hwnd, vk, false, cRepeat, flags);
    return 0;
}

// 0x0102 WM_CHAR
// pub fn OnChar(self: *T, hwnd: HWND, ch: TCHAR, cRepeat: i32) void
pub fn HANDLE_WM_CHAR(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const ch = @truncate(TCHAR, wParam);
    const cRepeat = @truncate(i16, lParam);
    handler.OnChar(hwnd, ch, cRepeat);
    return 0;
}

// 0x0103 WM_DEADCHAR
// pub fn OnDeadChar(self: *T, hwnd: HWND, ch: TCHAR, cRepeat: i32) void
pub fn HANDLE_WM_DEADCHAR(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const ch = @truncate(TCHAR, wParam);
    const cRepeat = @truncate(i16, lParam);
    handler.OnDeadChar(hwnd, ch, cRepeat);
    return 0;
}

// 0x0104 WM_SYSKEYDOWN
// pub fn OnSysKey(self: *T, hwnd: HWND, vk: VIRTUAL_KEY, fDown: bool, cRepeat: i32, flags: u32) void
pub fn HANDLE_WM_SYSKEYDOWN(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const cRepeat = @truncate(i16, lParam);
    const flags = @bitCast(u16, @truncate(i16, lParam >> 16));
    const vk = @intToEnum(VIRTUAL_KEY, @truncate(u16, wParam));
    handler.OnSysKey(hwnd, vk, true, cRepeat, flags);
    return 0;
}

// 0x0105 WM_SYSKEYUP
// OnSysKey(self: *T, hwnd: HWND, vk: VIRTUAL_KEY, fDown: bool, cRepeat: i32, flags: u32) void
pub fn HANDLE_WM_SYSKEYUP(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const cRepeat = @truncate(i16, lParam);
    const flags = @bitCast(u16, @truncate(i16, lParam >> 16));
    const vk = @intToEnum(VIRTUAL_KEY, @truncate(u16, wParam));
    handler.OnSysKey(hwnd, vk, false, cRepeat, flags);
    return 0;
}

// 0x0106 WM_SYSCHAR
// pub fn OnSysChar(self: *T, hwnd: HWND, ch: TCHAR, cRepeat: i32) void
pub fn HANDLE_WM_SYSCHAR(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const ch = @truncate(TCHAR, wParam);
    const cRepeat = @truncate(i16, lParam);
    handler.OnSysChar(hwnd, ch, cRepeat);
    return 0;
}

// 0x0107 WM_SYSDEADCHAR
// pub fn OnSysDeadChar(self: *T, hwnd: HWND, ch: TCHAR, cRepeat: i32) void
pub fn HANDLE_WM_SYSDEADCHAR(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const ch = @truncate(TCHAR, wParam);
    const cRepeat = @truncate(i16, lParam);
    handler.OnSysDeadChar(hwnd, ch, cRepeat);
    return 0;
}

// 0x0114 WM_HSCROLL
// pub fn OnHScroll(self: *T, hwnd: HWND, hwndCtrl: ?HWND, code: u32, pos: i32) void
pub fn HANDLE_WM_HSCROLL(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const hwndCtrl = @intToPtr(?HWND, @bitCast(usize, lParam));
    const code = @truncate(u16, wParam);
    const pos = @bitCast(i16, @truncate(u16, wParam >> 16));
    handler.OnHScroll(hwnd, hwndCtrl, code, pos);
    return 0;
}

pub fn FORWARD_WM_HSCROLL(hwnd: HWND, hwndCtrl: ?HWND, code: u32, pos: i32, forwarder: forwarder_type) void {
    const wParam = @as(WPARAM, ((@bitCast(u32, pos) & 0xffff) << 16) | (code & 0xffff));
    const lParam = @bitCast(LPARAM, @ptrToInt(hwndCtrl));
    _ = forwarder(hwnd, win32.WM_HSCROLL, wParam, lParam);
}

// 0x0115 WM_VSCROLL
// pub fn OnVScroll(self: *T, hwnd: HWND, hwndCtrl: ?HWND, code: u32, pos: i32) void
pub fn HANDLE_WM_VSCROLL(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const hwndCtrl = @intToPtr(?HWND, @bitCast(usize, lParam));
    const code = @truncate(u16, wParam);
    const pos = @bitCast(i16, @truncate(u16, wParam >> 16));
    handler.OnVScroll(hwnd, hwndCtrl, code, pos);
    return 0;
}

pub fn FORWARD_WM_VSCROLL(hwnd: HWND, hwndCtrl: ?HWND, code: u32, pos: i32, forwarder: forwarder_type) void {
    const wParam = @as(WPARAM, ((@bitCast(u32, pos) & 0xffff) << 16) | (code & 0xffff));
    const lParam = @bitCast(LPARAM, @ptrToInt(hwndCtrl));
    _ = forwarder(hwnd, win32.WM_VSCROLL, wParam, lParam);
}

// 0x0200 WM_MOUSEMOVE
// pub fn OnMouseMove(self: *T, hwnd: HWND, x: i32, y: i32, keyFlags: u32) void
pub fn HANDLE_WM_MOUSEMOVE(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const x = @truncate(i16, lParam);
    const y = @truncate(i16, lParam >> 16);
    const keyFlags = @truncate(u32, wParam);
    handler.OnMouseMove(hwnd, x, y, keyFlags);
    return 0;
}

// 0x0201 WM_LBUTTONDOWN
// pub fn OnLButtonDown(self: *T, hwnd: HWND, fDoubleClick: bool, x: i32, y: i32, keyFlags: u32) void
pub fn HANDLE_WM_LBUTTONDOWN(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const x = @truncate(i16, lParam);
    const y = @truncate(i16, lParam >> 16);
    const keyFlags = @truncate(u32, wParam);
    handler.OnLButtonDown(hwnd, false, x, y, keyFlags);
    return 0;
}

// 0x0202 WM_LBUTTONUP
// pub fn OnLButtonUp(self: *T, hwnd: HWND, x: i32, y: i32, keyFlags: u32) void
pub fn HANDLE_WM_LBUTTONUP(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const x = @truncate(i16, lParam);
    const y = @truncate(i16, lParam >> 16);
    const keyFlags = @truncate(u32, wParam);
    handler.OnLButtonUp(hwnd, x, y, keyFlags);
    return 0;
}

// 0x0203 WM_LBUTTONDBLCLK
// pub fn OnLButtonDown(self: *T, hwnd: HWND, fDoubleClick: bool, x: i32, y: i32, keyFlags: u32) void
pub fn HANDLE_WM_LBUTTONDBLCLK(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const x = @truncate(i16, lParam);
    const y = @truncate(i16, lParam >> 16);
    const keyFlags = @truncate(u32, wParam);
    handler.OnLButtonDown(hwnd, true, x, y, keyFlags);
    return 0;
}

// 0x0204 WM_RBUTTONDOWN
// pub fn OnRButtonDown(self: *T, hwnd: HWND, fDoubleClick: bool, x: i32, y: i32, keyFlags: u32) void
pub fn HANDLE_WM_RBUTTONDOWN(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const x = @truncate(i16, lParam);
    const y = @truncate(i16, lParam >> 16);
    const keyFlags = @truncate(u32, wParam);
    handler.OnRButtonDown(hwnd, false, x, y, keyFlags);
    return 0;
}

// 0x0205
// pub fn OnRButtonUp(self: *T, hwnd: HWND, x: i32, y: i32, keyFlags: u32) void
pub fn HANDLE_WM_RBUTTONUP(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const x = @truncate(i16, lParam);
    const y = @truncate(i16, lParam >> 16);
    const keyFlags = @truncate(u32, wParam);
    handler.OnRButtonUp(hwnd, x, y, keyFlags);
    return 0;
}

// 0x0206 WM_RBUTTONDBLCLK
// pub fn OnRButtonDown(self: *T, hwnd: HWND, fDoubleClick: bool, x: i32, y: i32, keyFlags: u32) void
pub fn HANDLE_WM_RBUTTONDBLCLK(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const x = @truncate(i16, lParam);
    const y = @truncate(i16, lParam >> 16);
    const keyFlags = @truncate(u32, wParam);
    handler.OnRButtonDown(hwnd, true, x, y, keyFlags);
    return 0;
}
// 0x0207 WM_MBUTTONDOWN
// pub fn OnMButtonDown(self: *T, hwnd: HWND, fDoubleClick: bool, x: i32, y: i32, keyFlags: u32) void
pub fn HANDLE_WM_MBUTTONDOWN(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const x = @truncate(i16, lParam);
    const y = @truncate(i16, lParam >> 16);
    const keyFlags = @truncate(u32, wParam);
    handler.OnMButtonDown(hwnd, false, x, y, keyFlags);
    return 0;
}

// 0x0208 WM_MBUTTONUP
// pub fn OnMButtonUp(self: *T, hwnd: HWND, x: i32, y: i32, keyFlags: u32) void
pub fn HANDLE_WM_MBUTTONUP(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const x = @truncate(i16, lParam);
    const y = @truncate(i16, lParam >> 16);
    const keyFlags = @truncate(u32, wParam);
    handler.OnMButtonUp(hwnd, x, y, keyFlags);
    return 0;
}

// 0x0209 WM_MBUTTONDBLCLK
// pub fn OnMButtonDown(self: *T, hwnd: HWND, fDoubleClick: bool, x: i32, y: i32, keyFlags: u32) void
pub fn HANDLE_WM_MBUTTONDBLCLK(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const x = @truncate(i16, lParam);
    const y = @truncate(i16, lParam >> 16);
    const keyFlags = @truncate(u32, wParam);
    handler.OnMButtonDown(hwnd, false, x, y, keyFlags);
    return 0;
}
