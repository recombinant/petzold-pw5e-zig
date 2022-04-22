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
const DRAWITEMSTRUCT = win32.DRAWITEMSTRUCT;

// ----------------------------------------------------------------------------
// WinNls.h

// String based NLS APIs
pub const LOCALE_NAME_USER_DEFAULT: ?[*:0]const TCHAR = null;
pub const LOCALE_NAME_INVARIANT: ?[*:0]const TCHAR = win32.L("");
pub const LOCALE_NAME_SYSTEM_DEFAULT: ?[*:0]const TCHAR = win32.L("!x-sys-default-locale");

// ----------------------------------------------------------------------------
// WinGdi.h
pub const COLORREF = u32;
pub fn RGB(r: u8, g: u8, b: u8) COLORREF {
    return @as(u32, b) << 16 | @as(u32, g) << 8 | r;
}

pub fn GetRValue(rgb: COLORREF) u8 {
    return @truncate(u8, rgb);
}
pub fn GetGValue(rgb: COLORREF) u8 {
    return @truncate(u8, rgb >> 8);
}
pub fn GetBValue(rgb: COLORREF) u8 {
    return @truncate(u8, rgb >> 16);
}

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

// 0x0007 WM_SETFOCUS
// pub fn OnSetFocus(self: *T,  hwnd: HWND, hwndOldFocus: ?HWND) void
pub fn HANDLE_WM_SETFOCUS(hwnd: HWND, wParam: WPARAM, _: LPARAM, comptime T: type, handler: *T) LRESULT {
    handler.OnSetFocus(hwnd, @intToPtr(?HWND, wParam));
    return 0;
}

// 0x0008 WM_KILLFOCUS
// pub fn OnKillFocus(self: *T,  hwnd: HWND, hwndNewFocus: ?HWND) void
pub fn HANDLE_WM_KILLFOCUS(hwnd: HWND, wParam: WPARAM, _: LPARAM, comptime T: type, handler: *T) LRESULT {
    handler.OnKillFocus(hwnd, @intToPtr(?HWND, wParam));
    return 0;
}

// 0x000A WM_ENABLE
// pub fn OnEnable(hwnd: HWND, fEnable: bool) void
pub fn HANDLE_WM_ENABLE(hwnd: HWND, wParam: WPARAM, _: LPARAM, comptime T: type, handler: *T) LRESULT {
    const fEnable: bool = if (wParam != 0) true else false;
    handler.OnEnable(hwnd, fEnable);
    return 0;
}

pub fn FORWARD_WM_ENABLE(hwnd: HWND, fEnable: bool, forwarder: forwarder_type) void {
    const wParam: BOOL = if (fEnable) TRUE else FALSE;
    _ = forwarder(hwnd, win32.WM_ENABLE, wParam, 0);
}

// TODO: 0x000B WM_SETREDRAW
// TODO: 0x000C WM_SETTEXT
// TODO: 0x000D WM_GETTEXT
// TODO: 0x000E WM_GETTEXTLENGTH

// 0x000f WM_PAINT
// pub fn OnPaint(self: *T, hwnd: HWND) void
pub fn HANDLE_WM_PAINT(hwnd: HWND, _: WPARAM, _: LPARAM, comptime T: type, handler: *T) LRESULT {
    handler.OnPaint(hwnd);
    return 0;
}

pub fn FORWARD_WM_PAINT(hwnd: HWND, forwarder: forwarder_type) void {
    _ = forwarder(hwnd, win32.WM_PAINT, 0, 0);
}

// 0x0010 WM_CLOSE
// pub fn OnClose(self: *T, hwnd: HWND) void
pub fn HANDLE_WM_CLOSE(hwnd: HWND, _: WPARAM, _: LPARAM, comptime T: type, handler: *T) LRESULT {
    handler.OnClose(hwnd);
    return 0;
}

pub fn FORWARD_WM_CLOSE(hwnd: HWND, forwarder: forwarder_type) void {
    _ = forwarder(hwnd, win32.WM_CLOSE, 0, 0);
}

// TODO: 0x0011 WM_QUERYENDSESSION
// TODO: 0x0012 WM_QUIT
// TODO: 0x0013 WM_QUERYOPEN
// TODO: 0x0014 WM_ERASEBKGND
// TODO: 0x0015 WM_SYSCOLORCHANGE
// TODO: 0x0016 WM_ENDSESSION
// TODO: 0x0018 WM_SHOWWINDOW

// 0x001A WM_SETTINGCHANGE
// pub fn OnSettingChange(self: *T, hwnd: HWND, uiAction: SYSTEM_PARAMETERS_INFO_ACTION, lpszSectionName: ?[*:0]const TCHAR) void
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

// 0x002B WM_DRAWITEM
// pub fn OnDrawItem(self: *T, hwnd: HWND, lpDrawItem: *const DRAWITEMSTRUCT) void
pub fn HANDLE_WM_DRAWITEM(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LPARAM {
    const L = packed struct {
        lpDrawItem: *const DRAWITEMSTRUCT,
    };
    const crackedL = @ptrCast(*const L, &lParam);
    handler.OnDrawItem(hwnd, crackedL.lpDrawItem);
    return 0;
}

// TODO: 0x0030 WM_SETFONT
// TODO: 0x0031 WM_GETFONT
// TODO: 0x004E WM_NOTIFY
// TODO: 0x0051 WM_INPUTLANGCHANGE

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

// TODO: 0x0081 WM_NCCREATE
// TODO: 0x0082 WM_NCDESTROY
// TODO: 0x0083 WM_NCCALCSIZE
// TODO: 0x0084 WM_NCHITTEST
// TODO: 0x0085 WM_NCPAINT
// TODO: 0x0086 WM_NCACTIVATE

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

pub fn FORWARD_WM_KEYDOWN(hwnd: HWND, vk: VIRTUAL_KEY, cRepeat: i16, flags: u16, forwarder: forwarder_type) void {
    const crackedW align(@alignOf(WPARAM)) = KeyW{ .vk = vk };
    const crackedL align(@alignOf(LPARAM)) = KeyL{ .cRepeat = cRepeat, .flags = flags };
    const wParamPtr = @ptrCast(*const WPARAM, &crackedW);
    const lParamPtr = @ptrCast(*const LPARAM, &crackedL);
    _ = forwarder(hwnd, win32.WM_KEYDOWN, wParamPtr.*, lParamPtr.*);
}

// 0x0101 WM_KEYUP
// pub fn OnKey(self: *T, hwnd: HWND, vk: VIRTUAL_KEY, fDown: bool, cRepeat: i16, flags: u16) void
pub fn HANDLE_WM_KEYUP(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const KeyW, &wParam);
    const crackedL = @ptrCast(*const KeyL, &lParam);
    handler.OnKey(hwnd, crackedW.vk, false, crackedL.cRepeat, crackedL.flags);
    return 0;
}

pub fn FORWARD_WM_KEYUP(hwnd: HWND, vk: VIRTUAL_KEY, cRepeat: i16, flags: u16, forwarder: forwarder_type) void {
    const crackedW align(@alignOf(WPARAM)) = KeyW{ .vk = vk };
    const crackedL align(@alignOf(LPARAM)) = KeyL{ .cRepeat = cRepeat, .flags = flags };
    const wParamPtr = @ptrCast(*const WPARAM, &crackedW);
    const lParamPtr = @ptrCast(*const LPARAM, &crackedL);
    _ = forwarder(hwnd, win32.WM_KEYUP, wParamPtr.*, lParamPtr.*);
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

pub fn FORWARD_WM_SYSKEYDOWN(hwnd: HWND, vk: VIRTUAL_KEY, cRepeat: i16, flags: u16, forwarder: forwarder_type) void {
    const crackedW align(@alignOf(WPARAM)) = KeyW{ .vk = vk };
    const crackedL align(@alignOf(LPARAM)) = KeyL{ .cRepeat = cRepeat, .flags = flags };
    const wParamPtr = @ptrCast(*const WPARAM, &crackedW);
    const lParamPtr = @ptrCast(*const LPARAM, &crackedL);
    _ = forwarder(hwnd, win32.WM_SYSKEYDOWN, wParamPtr.*, lParamPtr.*);
}

// 0x0105 WM_SYSKEYUP
// OnSysKey(self: *T, hwnd: HWND, vk: VIRTUAL_KEY, fDown: bool, cRepeat: i16, flags: u16) void
pub fn HANDLE_WM_SYSKEYUP(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const KeyW, &wParam);
    const crackedL = @ptrCast(*const KeyL, &lParam);
    handler.OnSysKey(hwnd, crackedW.vk, false, crackedL.cRepeat, crackedL.flags);
    return 0;
}

pub fn FORWARD_WM_SYSKEYUP(hwnd: HWND, vk: VIRTUAL_KEY, cRepeat: i16, flags: u16, forwarder: forwarder_type) void {
    const crackedW align(@alignOf(WPARAM)) = KeyW{ .vk = vk };
    const crackedL align(@alignOf(LPARAM)) = KeyL{ .cRepeat = cRepeat, .flags = flags };
    const wParamPtr = @ptrCast(*const WPARAM, &crackedW);
    const lParamPtr = @ptrCast(*const LPARAM, &crackedL);
    _ = forwarder(hwnd, win32.WM_SYSKEYUP, wParamPtr.*, lParamPtr.*);
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

// --------------------------------------------------------

// TODO: 0x0110 WM_INITDIALOG

// 0x0111 WM_COMMAND
// pub fn OnCommand(self: *T, hwnd: HWND, id: i16, hwndCtl: ?HWND, codeNotify: u16) void
pub fn HANDLE_WM_COMMAND(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const W = packed struct {
        id: i16,
        codeNotitfy: u16,
    };
    const L = packed struct {
        hwndCtrl: ?HWND,
    };
    const crackedW = @ptrCast(*const W, &wParam);
    const crackedL = @ptrCast(*const L, &lParam);
    handler.OnCommand(hwnd, crackedW.id, crackedW.hwnd, crackedW.codeNotify);
    return 0;
}

// TODO: 0x0112 WM_SYSCOMMAND

// 0x0113 WM_TIMER
// pub fn OnTimer(self: *T, hwnd: HWND, id: usize) void
pub fn HANDLE_WM_TIMER(hwnd: HWND, wParam: WPARAM, _: LPARAM, comptime T: type, handler: *T) LRESULT {
    const W = packed struct { id: usize };
    const crackedW = @ptrCast(*const W, &wParam);
    handler.OnTimer(hwnd, crackedW.id);
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

// --------------------------------------------------------

// TODO: 0x0117 WM_INITMENUPOPUP
// TODO: 0x0132 WM_CTLCOLORMSGBOX
// TODO: 0x0133 WM_CTLCOLOREDIT
// TODO: 0x0134 WM_CTLCOLORLISTBOX
// TODO: 0x0135 WM_CTLCOLORBTN
// TODO: 0x0136 WM_CTLCOLORDLG
// TODO: 0x0137 WM_CTLCOLORSCROLLBAR
// TODO: 0x0138 WM_CTLCOLORSTATIC

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

pub fn FORWARD_WM_MOUSEMOVE(hwnd: HWND, x: i16, y: i16, keyFlags: u32, forwarder: forwarder_type) void {
    const crackedW align(@alignOf(WPARAM)) = MouseW{ .keyFlags = keyFlags };
    const crackedL align(@alignOf(LPARAM)) = MouseL{ .x = x, .y = y };
    const wParamPtr = @ptrCast(*const WPARAM, &crackedW);
    const lParamPtr = @ptrCast(*const LPARAM, &crackedL);
    _ = forwarder(hwnd, win32.WM_MOUSEMOVE, wParamPtr.*, lParamPtr.*);
}

// 0x0201 WM_LBUTTONDOWN
// pub fn OnLButtonDown(self: *T, hwnd: HWND, fDoubleClick: bool, x: i16, y: i16, keyFlags: u32) void
pub fn HANDLE_WM_LBUTTONDOWN(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const MouseW, &wParam);
    const crackedL = @ptrCast(*const MouseL, &lParam);
    handler.OnLButtonDown(hwnd, false, crackedL.x, crackedL.y, crackedW.keyFlags);
    return 0;
}

pub fn FORWARD_WM_LBUTTONDOWN(hwnd: HWND, fDoubleClick: bool, x: i16, y: i16, keyFlags: u32, forwarder: forwarder_type) void {
    const crackedW align(@alignOf(WPARAM)) = MouseW{ .keyFlags = keyFlags };
    const crackedL align(@alignOf(LPARAM)) = MouseL{ .x = x, .y = y };
    const wParamPtr = @ptrCast(*const WPARAM, &crackedW);
    const lParamPtr = @ptrCast(*const LPARAM, &crackedL);
    const msg = if (fDoubleClick) win32.WM_LBUTTONDBLCLK else win32.WM_LBUTTONDOWN;
    _ = forwarder(hwnd, msg, wParamPtr.*, lParamPtr.*);
}

// 0x0202 WM_LBUTTONUP
// pub fn OnLButtonUp(self: *T, hwnd: HWND, x: i16, y: i16, keyFlags: u32) void
pub fn HANDLE_WM_LBUTTONUP(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const MouseW, &wParam);
    const crackedL = @ptrCast(*const MouseL, &lParam);
    handler.OnLButtonUp(hwnd, crackedL.x, crackedL.y, crackedW.keyFlags);
    return 0;
}

pub fn FORWARD_WM_LBUTTONUP(hwnd: HWND, x: i16, y: i16, keyFlags: u32, forwarder: forwarder_type) void {
    const crackedW align(@alignOf(WPARAM)) = MouseW{ .keyFlags = keyFlags };
    const crackedL align(@alignOf(LPARAM)) = MouseL{ .x = x, .y = y };
    const wParamPtr = @ptrCast(*const WPARAM, &crackedW);
    const lParamPtr = @ptrCast(*const LPARAM, &crackedL);
    _ = forwarder(hwnd, win32.WM_LBUTTONUP, wParamPtr.*, lParamPtr.*);
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

pub fn FORWARD_WM_RBUTTONDOWN(hwnd: HWND, fDoubleClick: bool, x: i16, y: i16, keyFlags: u32, forwarder: forwarder_type) void {
    const crackedW align(@alignOf(WPARAM)) = MouseW{ .keyFlags = keyFlags };
    const crackedL align(@alignOf(LPARAM)) = MouseL{ .x = x, .y = y };
    const wParamPtr = @ptrCast(*const WPARAM, &crackedW);
    const lParamPtr = @ptrCast(*const LPARAM, &crackedL);
    const msg = if (fDoubleClick) win32.WM_RBUTTONDBLCLK else win32.WM_RBUTTONDOWN;
    _ = forwarder(hwnd, msg, wParamPtr.*, lParamPtr.*);
}

// 0x0205
// pub fn OnRButtonUp(self: *T, hwnd: HWND, x: i16, y: i16, keyFlags: u32) void
pub fn HANDLE_WM_RBUTTONUP(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const MouseW, &wParam);
    const crackedL = @ptrCast(*const MouseL, &lParam);
    handler.OnRButtonUp(hwnd, crackedL.x, crackedL.y, crackedW.keyFlags);
    return 0;
}

pub fn FORWARD_WM_RBUTTONUP(hwnd: HWND, x: i16, y: i16, keyFlags: u32, forwarder: forwarder_type) void {
    const crackedW align(@alignOf(WPARAM)) = MouseW{ .keyFlags = keyFlags };
    const crackedL align(@alignOf(LPARAM)) = MouseL{ .x = x, .y = y };
    const wParamPtr = @ptrCast(*const WPARAM, &crackedW);
    const lParamPtr = @ptrCast(*const LPARAM, &crackedL);
    _ = forwarder(hwnd, win32.WM_RBUTTONUP, wParamPtr.*, lParamPtr.*);
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

pub fn FORWARD_WM_MBUTTONDOWN(hwnd: HWND, fDoubleClick: bool, x: i16, y: i16, keyFlags: u32, forwarder: forwarder_type) void {
    const crackedW align(@alignOf(WPARAM)) = MouseW{ .keyFlags = keyFlags };
    const crackedL align(@alignOf(LPARAM)) = MouseL{ .x = x, .y = y };
    const wParamPtr = @ptrCast(*const WPARAM, &crackedW);
    const lParamPtr = @ptrCast(*const LPARAM, &crackedL);
    const msg = if (fDoubleClick) win32.WM_MBUTTONDBLCLK else win32.WM_MBUTTONDOWN;
    _ = forwarder(hwnd, msg, wParamPtr.*, lParamPtr.*);
}

// 0x0208 WM_MBUTTONUP
// pub fn OnMButtonUp(self: *T, hwnd: HWND, x: i16, y: i16, keyFlags: u32) void
pub fn HANDLE_WM_MBUTTONUP(hwnd: HWND, wParam: WPARAM, lParam: LPARAM, comptime T: type, handler: *T) LRESULT {
    const crackedW = @ptrCast(*const MouseW, &wParam);
    const crackedL = @ptrCast(*const MouseL, &lParam);
    handler.OnMButtonUp(hwnd, crackedL.x, crackedL.y, crackedW.keyFlags);
    return 0;
}

pub fn FORWARD_WM_MBUTTONUP(hwnd: HWND, x: i16, y: i16, keyFlags: u32, forwarder: forwarder_type) void {
    const crackedW align(@alignOf(WPARAM)) = MouseW{ .keyFlags = keyFlags };
    const crackedL align(@alignOf(LPARAM)) = MouseL{ .x = x, .y = y };
    const wParamPtr = @ptrCast(*const WPARAM, &crackedW);
    const lParamPtr = @ptrCast(*const LPARAM, &crackedL);
    _ = forwarder(hwnd, win32.WM_MBUTTONUP, wParamPtr.*, lParamPtr.*);
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

// --------------------------------------------------------

// TODO: 0x0220 WM_MDICREATE
// TODO: 0x0221 WM_MDIDESTROY
// TODO: 0x0222 WM_MDIACTIVATE
// TODO: 0x0223 WM_MDIRESTORE
// TODO: 0x0224 WM_MDINEXT
// TODO: 0x0225 WM_MDIMAXIMIZE
// TODO: 0x0226 WM_MDITILE
// TODO: 0x0227 WM_MDICASCADE
// TODO: 0x0228 WM_MDIICONARRANGE
// TODO: 0x0229 WM_MDIGETACTIVE
// TODO: 0x0230 WM_MDISETMENU
// TODO: 0x0300 WM_CUT
// TODO: 0x0301 WM_COPY
// TODO: 0x0302 WM_PASTE
// TODO: 0x0303 WM_CLEAR
// TODO: 0x0304 WM_UNDO
// TODO: 0x0307 WM_DESTROYCLIPBOARD
// TODO: 0x0308 WM_DRAWCLIPBOARD
// TODO: 0x0309 WM_PAINTCLIPBOARD
// TODO: 0x030A WM_VSCROLLCLIPBOARD
// TODO: 0x030B WM_SIZECLIPBOARD
// TODO: 0x030C WM_ASKCBFORMATNAME
// TODO: 0x030D WM_CHANGECBCHAIN
// TODO: 0x030F WM_QUERYNEWPALETTE
// TODO: 0x0310 WM_PALETTEISCHANGING
// TODO: 0x0311 WM_PALETTECHANGED

