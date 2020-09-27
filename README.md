# petzold-pw5e-zig
Zig transliteration of Charles Petzold's Programming Windows 5th Edition

[Zig](https://ziglang.org/) transliteration of Charles Petzold's excellent book Programming Windows 5th Edition ISBN-10 157231995X

---

No content yet. Zig release is at 0.6.0 at the time of writing.

---

Zig has various [tiers](https://ziglang.org/#Support-Table).
- [Tier 1](https://ziglang.org/#Tier-1-Support) will work for (cross-)compiling Zig code for Microsoft Windows. Compiling from any other tier is a maybe.
- [Tier 1](https://ziglang.org/#Tier-1-Support) Microsoft Windows Operating Systems will run Zig compiled executables. Running other on any other tier has caveats.

The Microsoft Windows version of Zig ships using calls ["winternl.h"](https://docs.microsoft.com/en-us/windows/win32/devnotes/calling-internal-apis) functions which are not portable across versions of Microsoft Windows. The Zig standard library calls those functions and does not respond gracefully if a function has been changed or is missing from the Microsoft Windows Operating System on which it is being run.

If targeting [Tier 2](https://ziglang.org/#Tier-2-Support) or lower versions of Microsoft Windows and using the Zig standard libary `@import("std");` for anything other than `comptime` then test thoroughly on the target platform.
