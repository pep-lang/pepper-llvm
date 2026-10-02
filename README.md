# pepper-llvm

LLVM C API bindings for [Pepper](https://github.com/justinboswell/pepper)
(issue justinboswell/pepper#249), so a compiler written in Pepper can build
LLVM IR, optimize it and emit object files.

Two modules:

- **`llvm`**: Pepper types over LLVM. `Context`, `Module`, `Builder` and
  `TargetMachine` free their LLVM object when the last reference goes away
  (each holds a runtime `Handle<T>`); `Type`, `Value`, `BasicBlock` and
  `Attribute` are plain value handles, valid while their context and module
  live.
- **`llvm_c`**: the raw `extern` declarations, one per LLVM-C function, with
  LLVM's names and C's types. Use it for anything `llvm` does not wrap yet;
  every wrapper exposes its LLVM-C pointer as `ref`.

```pepper
import llvm;

main(): int {
    var context = llvm.Context();
    var module = llvm.Module(context, "demo");
    var i32 = context.int32_type();
    var add = module.add_function("add", llvm.Type.function(i32, [i32, i32]));
    var builder = llvm.Builder(context);
    builder.position_at_end(context.append_block(add, "entry"));
    builder.return_value(builder.add(add.param(0), add.param(1), "sum"));
    module.verify().value();

    var machine = llvm.TargetMachine.host().value();
    machine.configure(module);
    module.run_passes("default<O2>", machine).value();
    machine.emit_to_file(module, "demo.o").value();
    return 0;
}
```

`examples/factorial` builds a loop with phis, compiles it to an object
file, and links it into a second Pepper program.

## Using it

Until the package manager (justinboswell/pepper#217) exists, put this
repository on the import path:

```sh
pepper -I path/to/pepper-llvm main.pep -o main
```

Importing either module links LLVM 20, the version the Pepper compiler
builds with:

| Platform | Library | Setup |
|---|---|---|
| Linux | `libLLVM-20.so` | `apt install llvm-20-dev`; nothing else |
| macOS | Homebrew's `libLLVM.dylib` | `brew install llvm@20`, then pass `-L $(brew --prefix llvm@20)/lib` |
| Windows | `LLVM-C.dll` | pass `-L <LLVM>\lib` (for `LLVM-C.lib`), and keep `<LLVM>\bin` on `PATH` to run |

`-L` needs a Pepper compiler with justinboswell/pepper#371, which also adds
the `Handle<T>` the wrappers are built on.

## Tests

```sh
tests/run.sh path/to/pepper
```

runs `tests/llvm_test.pep` and the factorial example end to end.

## Decisions (from the open questions in #249)

- **Hand-written**, not generated from the headers: only what a compiler
  needs, with the rest addable one `extern` at a time.
- **One LLVM version, 20**, matching the Pepper compiler's default. The raw
  declarations avoid functions added after LLVM 18, so another version
  should only need the library names in `llvm_c/link.pep` changed (only 20
  is tested).
- **A package**, not part of the runtime: few programs need LLVM, and
  linking it is heavy.
- **Ownership**: wrappers hold a `Handle<__ptr<void>>`; a `Module` or
  `Builder` holds its `Context` and releases its own handle first in its
  destructor, so the context always outlives them.
- **Backends**: `initialize_native_target()` registers the host's (x86-64 or
  AArch64) only, since `LLVMInitializeNativeTarget` is a header inline that
  cannot be bound.

## Not yet covered

- Debug info (`DIBuilder`, for justinboswell/pepper#218).
- ORC JIT, intrinsics lookup, metadata, inline assembly, atomics, exception
  handling, and cross-compilation backends beyond the host's.
- A CI workflow. So far the tests have run on Linux x64 only; macOS and
  Windows linking follow the table above but are untested.
