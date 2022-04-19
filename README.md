# petzold-pw5e-zig
[Zig](https://ziglang.org/) transliteration of Charles Petzold's excellent book Programming Windows 5th Edition ISBN-10 157231995X

---

Not much content yet. The Zig (beta) release is at 0.9.1 at the time of writing.

---

There is a set of Zig bindings for Win32 located at https://github.com/marlersoft/zigwin32 so work is now proceeding.

Notes
-----
- There is no WIN32_LEAN_AND_MEAN. Zig is quick enough.

- https://github.com/marlersoft/zigwin32gen/issues/9 causes occasional memory align panics with CreateWindowExW and other functions. To fix `align(1)` needs to be added to the offending parameter in the zigwin32 declarations.
  - `CreateWindowExW()`, `CreateWindowExA()` - 2nd (*lpClassName*) parameter
  - `LoadImageW()`, `LoadImageA()` - 2nd (*name*) parameter
- `TextOutW()`, `TextOutA()` the `lpString` parameter does not need to be zero terminated.
- `IDC_ARROW` is present in zigwin32, but `IDC_WAIT` and others have been skipped. Probably to avoid the `align(1)` issues.
- `LoadIcon` & `LoadCursor` have been superseded by the `LoadImage` function.
