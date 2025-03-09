const std = @import("std");
const build_options = @import("build_options");
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
const createMutex = @import("win32").system.threading.CreateMutexA;
const HWND = win32.HWND;

const kbHookProc = @import("kbhookproc.zig").kbHookProc;

pub export fn wWinMain(
    hInstance: win32.HINSTANCE,
    _: ?win32.HINSTANCE,
    pCmdLine: [*:0]u16,
    nCmdShow: u32,
) callconv(WINAPI) c_int {
    _ = hInstance;
    _ = pCmdLine;
    _ = nCmdShow;

    //make mutex to avoid running several copies of the program
    const mutexId = "caps switcher";
    _ = createMutex(null, 0, mutexId);
    if (win32.GetLastError() == win32.ERROR_ALREADY_EXISTS) @panic("Another instance is already running.");

    var kb_hook: ?win32.HHOOK = undefined;
    kb_hook = win32.SetWindowsHookEx(win32.WH_KEYBOARD_LL, &kbHookProc, null, 0);
    defer _ = win32.UnhookWindowsHookEx(kb_hook);

    if (build_options.is_debug == false) {
        _ = console.FreeConsole();
    }

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
