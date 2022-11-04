# petzold-pw5e-zig
[Zig](https://ziglang.org/) transliteration of Charles Petzold's excellent book Programming Windows 5th Edition ISBN-10 157231995X

---

Not much content yet. The Zig (beta) release is at 0.10.0 at the time of writing.

The code works with Zig 0.9.1 - it requires tweaking to work with 0.10.0 and that won't happen until after [zigwin32](https://github.com/marlersoft/zigwin32) has been updated to work with Zig 0.10.0

---

Notes
-----
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
