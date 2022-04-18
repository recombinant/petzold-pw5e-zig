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
const SYSTEM_PARAMETERS_INFO_ACTION = win32.SYSTEM_PARAMETERS_INFO_ACTION;

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
    const L = packed struct {
        createstruct: *CREATESTRUCT,
    };
    const crackedL = @ptrCast(*const L, &lParam);
    // TODO: There is probably a better way of handling the return success/fail.
    return if (handler.OnCreate(hwnd, crackedL.createstruct) == 0) 0 else -1;
}

// 0x0002 WM_DESTROY
// pub fn OnDestroy(self: *T, hwnd: HWND) void
pub fn HANDLE_WM_DESTROY(hwnd: HWND, _: WPARAM, _: LPARAM, comptime T: type, handler: *T) LRESULT {
    handler.OnDestroy(hwnd);
    return 0;
}

// 0x0005 WM_SIZE
// pub fn OnSize(self: *T, hwnd: HWND, state: u32, cxClient: i16, cyClient: i16) void
pub fn HANDLE_WM_SIZE(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const W = packed struct {
        state: u32,
    };
    const L = packed struct {
        cxClient: i16,
        cyClient: i16,
    };
    const crackedW = @ptrCast(*const W, &wParam);
    const crackedL = @ptrCast(*const L, &lParam);
    handler.OnSize(hwnd, crackedW.state, crackedL.cxClient, crackedL.cyClient);
    // const state = @truncate(u32, wParam);
    // const cxClient = @truncate(i16, lParam);
    // const cyClient = @truncate(i16, lParam >> 16);
    // handler.OnSize(hwnd, state, cxClient, cyClient);
    return 0;
}

// 0x000f WM_PAINT
// pub fn OnPaint(self: *T, hwnd: HWND) void
pub fn HANDLE_WM_PAINT(hwnd: HWND, _: WPARAM, _: LPARAM, comptime T: type, handler: *T) LRESULT {
    handler.OnPaint(hwnd);
    return 0;
}

// 0x001A WM_SETTINGCHANGE
// pub fn OnSettingChange(self: *T, hwnd: hwnd, uiAction: SYSTEM_PARAMETERS_INFO_ACTION, lpszSectionName: ?[*:0]const TCHAR) void
pub fn HANDLE_WM_SETTINGCHANGE(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const W = packed struct {
        uiAction: SYSTEM_PARAMETERS_INFO_ACTION,
    };
    const L = packed struct {
        lpszSectionName: ?[*:0]const TCHAR,
    };
    const crackedW = @ptrCast(*const W, &wParam);
    const crackedL = @ptrCast(*const L, &lParam);
    handler.OnSettingChange(hwnd, crackedW.uiAction, crackedL.lpszSectionName);
    return 0;
}

// 0x007E WM_DISPLAYCHANGE
// pub fn OnDisplayChange(self: *T, hwnd:  HWND, bitsPerPixel: u32, cxScreen: u16, cyScreen: u16) void
pub fn HANDLE_WM_DISPLAYCHANGE(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const W = packed struct {
        bitsPerPixel: u32,
    };
    const L = packed struct {
        cxScreen: u16,
        cyScreen: u16,
    };
    const crackedW = @ptrCast(*const W, &wParam);
    const crackedL = @ptrCast(*const L, &lParam);
    handler.OnDisplayChange(hwnd, crackedW.bitsPerPixel, crackedL.cxScreen, crackedL.cyScreen);
    return 0;
}

// ---------------------------------------------------- Key
// --------------------------------------------------- Char
// https://stackoverflow.com/questions/8161741/handling-keyboard-input-in-win32-wm-char-or-wm-keydown-wm-keyup

const KeyW = packed struct {
    vk: VIRTUAL_KEY,
};
const KeyL = packed struct {
    cRepeat: i16,
    flags: u16,
};

const CharW = packed struct {
    ch: TCHAR,
};
const CharL = packed struct {
    cRepeat: i16,
};

// 0x0100 WM_KEYDOWN
// pub fn OnKey(self: *T, hwnd: HWND, vk: VIRTUAL_KEY, fDown: bool, cRepeat: i16, flags: u16) void
pub fn HANDLE_WM_KEYDOWN(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const KeyW, &wParam);
    const crackedL = @ptrCast(*const KeyL, &lParam);
    handler.OnKey(hwnd, crackedW.vk, true, crackedL.cRepeat, crackedL.flags);
    return 0;
}

// 0x0101 WM_KEYUP
// pub fn OnKey(self: *T, hwnd: HWND, vk: VIRTUAL_KEY, fDown: bool, cRepeat: i16, flags: u16) void
pub fn HANDLE_WM_KEYUP(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const KeyW, &wParam);
    const crackedL = @ptrCast(*const KeyL, &lParam);
    handler.OnKey(hwnd, crackedW.vk, false, crackedL.cRepeat, crackedL.flags);
    return 0;
}

// 0x0102 WM_CHAR
// pub fn OnChar(self: *T, hwnd: HWND, ch: TCHAR, cRepeat: i16) void
pub fn HANDLE_WM_CHAR(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const CharW, &wParam);
    const crackedL = @ptrCast(*const CharL, &lParam);
    handler.OnChar(hwnd, crackedW.ch, crackedL.cRepeat);
    return 0;
}

// 0x0103 WM_DEADCHAR
// pub fn OnDeadChar(self: *T, hwnd: HWND, ch: TCHAR, cRepeat: i16) void
pub fn HANDLE_WM_DEADCHAR(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const CharW, &wParam);
    const crackedL = @ptrCast(*const CharL, &lParam);
    handler.OnDeadChar(hwnd, crackedW.ch, crackedL.cRepeat);
    return 0;
}

// 0x0104 WM_SYSKEYDOWN
// pub fn OnSysKey(self: *T, hwnd: HWND, vk: VIRTUAL_KEY, fDown: bool, cRepeat: i16, flags: u16) void
pub fn HANDLE_WM_SYSKEYDOWN(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const KeyW, &wParam);
    const crackedL = @ptrCast(*const KeyL, &lParam);
    handler.OnSysKey(hwnd, crackedW.vk, true, crackedL.cRepeat, crackedL.flags);
    return 0;
}

// 0x0105 WM_SYSKEYUP
// OnSysKey(self: *T, hwnd: HWND, vk: VIRTUAL_KEY, fDown: bool, cRepeat: i16, flags: u16) void
pub fn HANDLE_WM_SYSKEYUP(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const KeyW, &wParam);
    const crackedL = @ptrCast(*const KeyL, &lParam);
    handler.OnSysKey(hwnd, crackedW.vk, false, crackedL.cRepeat, crackedL.flags);
    return 0;
}

// 0x0106 WM_SYSCHAR
// pub fn OnSysChar(self: *T, hwnd: HWND, ch: TCHAR, cRepeat: i16) void
pub fn HANDLE_WM_SYSCHAR(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const CharW, &wParam);
    const crackedL = @ptrCast(*const CharL, &lParam);
    handler.OnSysChar(hwnd, crackedW.ch, crackedL.cRepeat);
    return 0;
}

// 0x0107 WM_SYSDEADCHAR
// pub fn OnSysDeadChar(self: *T, hwnd: HWND, ch: TCHAR, cRepeat: i16) void
pub fn HANDLE_WM_SYSDEADCHAR(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const CharW, &wParam);
    const crackedL = @ptrCast(*const CharL, &lParam);
    handler.OnSysDeadChar(hwnd, crackedW.ch, crackedL.cRepeat);
    return 0;
}

// ------------------------------------------------- Scroll
const ScrollW = packed struct {
    code: u16,
    pos: i16,
};
const ScrollL = packed struct {
    hwndCtrl: ?HWND,
};

// 0x0114 WM_HSCROLL
// pub fn OnHScroll(self: *T, hwnd: HWND, hwndCtrl: ?HWND, code: u16, pos: i16) void
pub fn HANDLE_WM_HSCROLL(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const ScrollW, &wParam);
    const crackedL = @ptrCast(*const ScrollL, &lParam);
    handler.OnHScroll(hwnd, crackedL.hwndCtrl, crackedW.code, crackedW.pos);
    return 0;
}

pub fn FORWARD_WM_HSCROLL(hwnd: HWND, hwndCtrl: ?HWND, code: u16, pos: i16, forwarder: forwarder_type) void {
    const crackedW align(@alignOf(WPARAM)) = ScrollW{ .code = code, .pos = pos };
    const crackedL align(@alignOf(LPARAM)) = ScrollL{ .hwndCtrl = hwndCtrl };
    const wParamPtr = @ptrCast(*const WPARAM, &crackedW);
    const lParamPtr = @ptrCast(*const LPARAM, &crackedL);
    _ = forwarder(hwnd, win32.WM_HSCROLL, wParamPtr.*, lParamPtr.*);
}

// 0x0115 WM_VSCROLL
// pub fn OnVScroll(self: *T, hwnd: HWND, hwndCtrl: ?HWND, code: u16, pos: i16) void
pub fn HANDLE_WM_VSCROLL(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const ScrollW, &wParam);
    const crackedL = @ptrCast(*const ScrollL, &lParam);
    handler.OnVScroll(hwnd, crackedL.hwndCtrl, crackedW.code, crackedW.pos);
    return 0;
}

pub fn FORWARD_WM_VSCROLL(hwnd: HWND, hwndCtrl: ?HWND, code: u16, pos: i16, forwarder: forwarder_type) void {
    const crackedW align(@alignOf(WPARAM)) = ScrollW{ .code = code, .pos = pos };
    const crackedL align(@alignOf(LPARAM)) = ScrollL{ .hwndCtrl = hwndCtrl };
    const wParamPtr = @ptrCast(*const WPARAM, &crackedW);
    const lParamPtr = @ptrCast(*const LPARAM, &crackedL);
    _ = forwarder(hwnd, win32.WM_VSCROLL, wParamPtr.*, lParamPtr.*);
}

// -------------------------------------------------- Mouse

const MouseW = packed struct {
    keyFlags: u32,
};
const MouseL = packed struct {
    x: i16,
    y: i16,
};

// 0x0200 WM_MOUSEMOVE
// pub fn OnMouseMove(self: *T, hwnd: HWND, x: i16, y: i16, keyFlags: u32) void
pub fn HANDLE_WM_MOUSEMOVE(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const MouseW, &wParam);
    const crackedL = @ptrCast(*const MouseL, &lParam);
    handler.OnMouseMove(hwnd, crackedL.x, crackedL.y, crackedW.keyFlags);
    return 0;
}

// 0x0201 WM_LBUTTONDOWN
// pub fn OnLButtonDown(self: *T, hwnd: HWND, fDoubleClick: bool, x: i16, y: i16, keyFlags: u32) void
pub fn HANDLE_WM_LBUTTONDOWN(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const MouseW, &wParam);
    const crackedL = @ptrCast(*const MouseL, &lParam);
    handler.OnLButtonDown(hwnd, false, crackedL.x, crackedL.y, crackedW.keyFlags);
    return 0;
}

// 0x0202 WM_LBUTTONUP
// pub fn OnLButtonUp(self: *T, hwnd: HWND, x: i16, y: i16, keyFlags: u32) void
pub fn HANDLE_WM_LBUTTONUP(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const MouseW, &wParam);
    const crackedL = @ptrCast(*const MouseL, &lParam);
    handler.OnLButtonUp(hwnd, crackedL.x, crackedL.y, crackedW.keyFlags);
    return 0;
}

// 0x0203 WM_LBUTTONDBLCLK
// pub fn OnLButtonDown(self: *T, hwnd: HWND, fDoubleClick: bool, x: i16, y: i16, keyFlags: u32) void
pub fn HANDLE_WM_LBUTTONDBLCLK(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const MouseW, &wParam);
    const crackedL = @ptrCast(*const MouseL, &lParam);
    handler.OnLButtonDown(hwnd, true, crackedL.x, crackedL.y, crackedW.keyFlags);
    return 0;
}

// 0x0204 WM_RBUTTONDOWN
// pub fn OnRButtonDown(self: *T, hwnd: HWND, fDoubleClick: bool, x: i16, y: i16, keyFlags: u32) void
pub fn HANDLE_WM_RBUTTONDOWN(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const MouseW, &wParam);
    const crackedL = @ptrCast(*const MouseL, &lParam);
    handler.OnRButtonDown(hwnd, false, crackedL.x, crackedL.y, crackedW.keyFlags);
    return 0;
}

// 0x0205
// pub fn OnRButtonUp(self: *T, hwnd: HWND, x: i16, y: i16, keyFlags: u32) void
pub fn HANDLE_WM_RBUTTONUP(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const MouseW, &wParam);
    const crackedL = @ptrCast(*const MouseL, &lParam);
    handler.OnRButtonUp(hwnd, crackedL.x, crackedL.y, crackedW.keyFlags);
    return 0;
}

// 0x0206 WM_RBUTTONDBLCLK
// pub fn OnRButtonDown(self: *T, hwnd: HWND, fDoubleClick: bool, x: i16, y: i16, keyFlags: u32) void
pub fn HANDLE_WM_RBUTTONDBLCLK(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const MouseW, &wParam);
    const crackedL = @ptrCast(*const MouseL, &lParam);
    handler.OnRButtonDown(hwnd, true, crackedL.x, crackedL.y, crackedW.keyFlags);
    return 0;
}

// 0x0207 WM_MBUTTONDOWN
// pub fn OnMButtonDown(self: *T, hwnd: HWND, fDoubleClick: bool, x: i16, y: i16, keyFlags: u32) void
pub fn HANDLE_WM_MBUTTONDOWN(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const MouseW, &wParam);
    const crackedL = @ptrCast(*const MouseL, &lParam);
    handler.OnMButtonDown(hwnd, false, crackedL.x, crackedL.y, crackedW.keyFlags);
    return 0;
}

// 0x0208 WM_MBUTTONUP
// pub fn OnMButtonUp(self: *T, hwnd: HWND, x: i16, y: i16, keyFlags: u32) void
pub fn HANDLE_WM_MBUTTONUP(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const MouseW, &wParam);
    const crackedL = @ptrCast(*const MouseL, &lParam);
    handler.OnMButtonUp(hwnd, crackedL.x, crackedL.y, crackedW.keyFlags);
    return 0;
}

// 0x0209 WM_MBUTTONDBLCLK
// pub fn OnMButtonDown(self: *T, hwnd: HWND, fDoubleClick: bool, x: i16, y: i16, keyFlags: u32) void
pub fn HANDLE_WM_MBUTTONDBLCLK(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const MouseW, &wParam);
    const crackedL = @ptrCast(*const MouseL, &lParam);
    handler.OnMButtonDown(hwnd, true, crackedL.x, crackedL.y, crackedW.keyFlags);
    return 0;
}

// 0x020a WM_MOUSEWHEEL
// pub fn OnMouseWheel(self: *T, hwnd: HWND, x: i16, y: i16, zDelta: i16, fwKeys: u16) void
pub fn HANDLE_WM_MOUSEWHEEL(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const W = packed struct {
        fwKeys: u16,
        zDelta: i16,
    };
    const crackedW = @ptrCast(*const W, &wParam);
    const crackedL = @ptrCast(*const MouseL, &lParam);
    handler.OnMouseWheel(hwnd, crackedL.x, crackedL.y, crackedW.zDelta, crackedW.fwKeys);
    return 0;
}
