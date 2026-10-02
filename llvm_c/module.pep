## Raw bindings to the LLVM C API (LLVM-C): one `extern` per C function,
## with LLVM's own names and C's types.
##
## Most programs use the `llvm` module instead, which wraps these in Pepper
## types that free what they own. Import `llvm_c` for a function the
## wrappers do not cover yet; its handles are the `ref` field of the
## wrappers' types (`llvm.Type`, `llvm.Value`, `llvm.Module.ref`, ...).
##
## Importing the module links LLVM 20 (see `link.pep` for each platform).

export * from "link";
export * from "core";
export * from "target";
export * from "debug_info";
export * from "orc";
