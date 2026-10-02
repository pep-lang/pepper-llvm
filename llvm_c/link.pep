## Which LLVM library a program that imports `llvm_c` links, per platform.
##
## The bindings are written against LLVM 20, the version the Pepper compiler
## itself builds with by default.
##
## - **Linux:** `libLLVM-20.so`, which `apt install llvm-20-dev` puts on the
##   linker's default search path.
## - **macOS:** `libLLVM.dylib` from Homebrew's `llvm@20`; pass its folder
##   with `-L $(brew --prefix llvm@20)/lib`.
## - **Windows:** `LLVM-C.dll`, through its import library `LLVM-C.lib`; pass
##   the LLVM install's `lib` folder with `-L`, and keep its `bin` folder on
##   `PATH` when the program runs.
##
## Each platform's `LLVMGetVersion` carries the `[Link]` attribute, so
## importing the module is enough to link the library.

## Reports the version of the LLVM library the program is running against.
##
## @param major receives the major version
## @param minor receives the minor version
## @param patch receives the patch version
[Target(OS(Linux))]
[Link("LLVM-20")]
export extern void LLVMGetVersion(uint* major, uint* minor, uint* patch);

## Reports the version of the LLVM library the program is running against.
##
## @param major receives the major version
## @param minor receives the minor version
## @param patch receives the patch version
[Target(OS(Mac))]
[Link("LLVM")]
export extern void LLVMGetVersion(uint* major, uint* minor, uint* patch);

## Reports the version of the LLVM library the program is running against.
##
## @param major receives the major version
## @param minor receives the minor version
## @param patch receives the patch version
[Target(OS(Windows))]
[Link("LLVM-C")]
export extern void LLVMGetVersion(uint* major, uint* minor, uint* patch);
