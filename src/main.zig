const std = @import("std");
const WINAPI = std.os.windows.WINAPI;

pub const UNICODE = true;
const win32 = struct {
    usingnamespace @import("win32").zig;
    usingnamespace @import("win32").foundation;
    usingnamespace @import("win32").system.system_services;
    usingnamespace @import("win32").ui.windows_and_messaging;
    usingnamespace @import("win32").ui.input.keyboard_and_mouse;
};
const console = @import("win32").system.console;
const HWND = win32.HWND;

var caps_pressed: bool = false;
var shift_pressed: bool = false;

pub fn kbHookProc(nCode: i32, wParam: win32.WPARAM, lParam: win32.LPARAM) callconv(WINAPI) win32.LRESULT {
    if (nCode < 0) {
        return win32.CallNextHookEx(null, nCode, wParam, lParam);
    }

    const pKeyData: *win32.KBDLLHOOKSTRUCT = @ptrFromInt(@as(usize, @bitCast(lParam)));
    const vkey = @as(win32.VIRTUAL_KEY, @enumFromInt(pKeyData.vkCode));
    switch (vkey) {
        win32.VK_CAPITAL => return processCaps(nCode, wParam, lParam),
        win32.VK_SHIFT => return processShift(nCode, wParam, lParam),
        else => return win32.CallNextHookEx(null, nCode, wParam, lParam),
    }
}

fn processCaps(nCode: i32, wParam: win32.WPARAM, lParam: win32.LPARAM) win32.LRESULT {
    _ = nCode;
    _ = lParam;
    switch (wParam) {
        win32.WM_KEYDOWN => {
            if (caps_pressed) {
                return -1;
            } else {
                caps_pressed = true;
                //TODO: if shift pressed then instead of switching layout toggle caps lock
                switchLayout();
                return -1;
            }
        },
        win32.WM_KEYUP, win32.WM_SYSKEYUP => {
            if (caps_pressed) {
                caps_pressed = false;
                return -1;
            } else {
                return -1;
            }
        },
        win32.WM_SYSKEYDOWN => {
            if (caps_pressed) {
                return -1;
            } else {
                caps_pressed = true;
                return -1;
            }
        },
        else => unreachable,
    }
}

fn processShift(nCode: i32, wParam: win32.WPARAM, lParam: win32.LPARAM) win32.LRESULT {
    switch (wParam) {
        win32.WM_KEYDOWN, win32.WM_SYSKEYDOWN => {
            shift_pressed = true;
            return win32.CallNextHookEx(null, nCode, wParam, lParam);
        },
        win32.WM_KEYUP, win32.WM_SYSKEYUP => {
            shift_pressed = false;
            return win32.CallNextHookEx(null, nCode, wParam, lParam);
        },
        else => unreachable,
    }
}

var ALT_SHIFT = alt_shift_generate: {
    var sequence = [_]win32.INPUT{std.mem.zeroInit(win32.INPUT, .{})} ** 4;
    sequence[0].type = win32.INPUT_KEYBOARD;
    sequence[0].Anonymous.ki.wVk = win32.VK_MENU;
    sequence[1].type = win32.INPUT_KEYBOARD;
    sequence[1].Anonymous.ki.wVk = win32.VK_LSHIFT;
    sequence[2].type = win32.INPUT_KEYBOARD;
    sequence[2].Anonymous.ki.wVk = win32.VK_LSHIFT;
    sequence[2].Anonymous.ki.dwFlags = win32.KEYEVENTF_KEYUP;
    sequence[3].type = win32.INPUT_KEYBOARD;
    sequence[3].Anonymous.ki.wVk = win32.VK_MENU;
    sequence[3].Anonymous.ki.dwFlags = win32.KEYEVENTF_KEYUP;
    break :alt_shift_generate sequence;
};

fn switchLayout() void {
    const usent = win32.SendInput(4, &ALT_SHIFT, @sizeOf(win32.INPUT));
    if (usent != 4) {
        std.debug.print("Input not sent right! Error Code: {}\n", .{win32.GetLastError()});
    }
}

pub export fn wWinMain(
    hInstance: win32.HINSTANCE,
    _: ?win32.HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
    _ = hInstance;
    _ = pCmdLine;
    _ = nCmdShow;

    //TODO: make mutex to avoid running several copies of the program

    var kb_hook: ?win32.HHOOK = undefined;
    kb_hook = win32.SetWindowsHookEx(win32.WH_KEYBOARD_LL, &kbHookProc, null, 0) orelse std.debug.panic("Hook didn't work!!!", .{});
    defer _ = win32.UnhookWindowsHookEx(kb_hook);

    _ = console.FreeConsole();

    var msg: win32.MSG = undefined;
    while (win32.GetMessage(&msg, null, 0, 0) > 0) {
        _ = win32.TranslateMessage(&msg);
        _ = win32.DispatchMessage(&msg);
    }
    return @intCast(msg.wParam);
}

fn WindowProc(
    hwnd: HWND,
    uMsg: u32,
    wParam: win32.WPARAM,
    lParam: win32.LPARAM,
) callconv(WINAPI) win32.LRESULT {
    return win32.DefWindowProc(hwnd, uMsg, wParam, lParam);
}
