# petzold-pw5e-zig
[Zig](https://ziglang.org/) transliteration of the code in Charles Petzold's excellent book Programming Windows 5th Edition ISBN-10 157231995X - all 2.4kg of it (that's over 5lb).

# 2025/10/13
The following have been updated to the (near release) Zig 0.15.2 and a contemporaneous version of zigwin32 (2025/09/27):

- Chapter 1 Getting Started
  - 01-HelloMsg
- Chapter 2 An Introduction to Unicode
  - 02-ScrnSize
- Chapter 3 Windows and Messages
  - 03-HelloWin
- Chapter 4 An Exercise in Text Output
  - 04-SysMets1
  - 05-SysMets2
  - 06-SysMets3
- Chapter 5 Basic Drawing
  - 07-DevCaps1
  - 08-SineWave
  - 09-LineDemo
  - 10-Bezier
  - 11-AltWind
  - 12-WhatSize
  - 13-RandRect
  - 14-Clover
- Chapter 06 The Keyboard
  - 15-SysMets4
  - 16-KeyView1
  - 17-StokFon
  - 18-KeyView2
- Chapter 08 The Timer
  - 30-DigClock
  - 31-Clock

There remaining chapters need to be updated or committed. Some of the code is pre-Zig 0.9.1 and in
need of some TLC.


## 2025/01/10 Notes
zigwin32 requires patching to work with Zig 0.14 because of the .Struct -> .@"struct" etc. changes. If you got this far then that should not be too difficult.

[Windows UTF-8 works for recent releases of Windows](https://learn.microsoft.com/en-us/windows/apps/design/globalizing/use-utf8-code-page) allowing Zig to work directly with UTF-8 using the -A APIs rather than doing the WTF-16 dance with the cumbersome -W APIs. Unfortunately Zig only allows access to wWinMain and not WinMain so -W and -A APIs need to be mixed as appropriate.


# 2022/11/04
Not much content yet. The Zig (beta) release is at 0.10.0 at the time of writing.

The code works with Zig 0.9.1 - it requires tweaking to work with 0.10.0 and that won't happen until after [zigwin32](https://github.com/marlersoft/zigwin32) has been updated to work with Zig 0.10.0


## 2022/11/04 Notes
- This project uses [zigwin32](https://github.com/marlersoft/zigwin32) to eliminate importing the Windows header files directly. (Which is good as `@cImport()` has issues parsing the complexities of said Windows header files.)

- Unlike C/C++ there is no `WIN32_LEAN_AND_MEAN` to reduce the #include C header file burden. Zig is quick enough.

- https://github.com/marlersoft/zigwin32gen/issues/9 causes occasional memory align panics with CreateWindowExW and other functions. To fix `align(1)` needs to be added to the offending parameter in the zigwin32 declarations.
  - `CreateWindowExW()`, `CreateWindowExA()` - 2nd (*lpClassName*) parameter
  - `LoadImageW()`, `LoadImageA()` - 2nd (*name*) parameter
- `TextOutW()`, `TextOutA()` the `lpString` parameter does not need to be zero terminated.
- `IDC_ARROW` is present in zigwin32, but `IDC_WAIT` and others have been skipped. Probably to avoid the `align(1)` issues.
- `LoadIcon` & `LoadCursor` functions have been superseded by the `LoadImage` function.
- `GetWindowLongPtr`/`GetWindowLongPtr` functions are correctly mapped to `GetWindowLong`/`SetWindowLong` for 32 bit systems. No need to panic.
- There is no replacement for the `CreateWindow` macro in *WinUser.h* that maps to `CreateWindowEx`
- missing `StringCchCopy` and its ilk from *strsafe.h*
