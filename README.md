# pepper-llvm

LLVM C API bindings for [Pepper](https://github.com/justinboswell/pepper),
so a compiler written in Pepper can build LLVM IR, optimize it and emit
object files.

Two modules:

- **`llvm`** (the package's root): Pepper types over LLVM. `Context`,
  `Module`, `Builder`, `TargetMachine`, `DebugBuilder` and `Jit` free their
  LLVM object when the last reference goes away (each holds a runtime
  `Handle<T>`); `Type`, `Value`, `BasicBlock` and `Attribute` are plain
  value handles, valid while their context and module live.
- **`llvm.llvm_c`** (the `llvm_c` folder): the raw `extern` declarations,
  one per LLVM-C function, with LLVM's names and C's types. Use it for
  anything `llvm` does not wrap yet; every wrapper exposes its LLVM-C
  pointer as `ref`.

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

Add it to a project's `pep.toml`:

```toml
[dependencies]
llvm = { github = "justinboswell/pepper-llvm", branch = "main" }
```

```pepper
import llvm;
import llvm.llvm_c;     # only for functions the wrappers do not cover
```

Without a `pep.toml`, put a folder named `llvm` holding this repository
on the import path (`pepper build -I packages main.pep`, with
`packages/llvm` a checkout or a link to one).

Importing either module links LLVM 20, the version the Pepper compiler
builds with:

| Platform | Library | Setup |
|---|---|---|
| Linux | `libLLVM-20.so` | `apt install llvm-20-dev`; nothing else |
| macOS | Homebrew's `libLLVM.dylib` | `brew install llvm@20`, then pass `-L $(brew --prefix llvm@20)/lib` |
| Windows | `LLVM-C.dll` | pass `-L <LLVM>\lib` (for `LLVM-C.lib`), and keep `<LLVM>\bin` on `PATH` to run |

## Tests

```sh
tests/run.sh path/to/pepper
```

runs the `[Test]` functions in `tests/` with `pepper test`
(`llvm_test.pep`, `jit_test.pep`, `debug_info_test.pep`), then the
factorial example end to end. `LLVM_LIB` names the folder of the LLVM
library to link where the table above passes `-L` (on macOS it defaults
to Homebrew's), and `AR` the archiver for the example's library (`ar`,
or `llvm-ar` on Windows).

## Design

- **Hand-written**, not generated from the headers: only what a compiler
  needs, with the rest addable one `extern` at a time.
- **One LLVM version, 20**, matching the Pepper compiler's default. The core
  and target declarations avoid functions added after LLVM 18; debug info
  uses LLVM 19's debug records (`LLVMDIBuilderInsertDeclareRecordAtEnd`),
  and the JIT uses `LLVMOrcThreadSafeContextGetContext`, which LLVM 21
  removes. Only 20 is tested.
- **A package**, not part of the runtime: few programs need LLVM, and
  linking it is heavy.
- **Ownership**: wrappers hold a `Handle<__ptr<void>>`; a `Module` or
  `Builder` holds its `Context` and releases its own handle first in its
  destructor, so the context always outlives them.
- **Every backend**: `TargetMachine.create(triple)` takes any triple the
  library has a backend for (`riscv64-unknown-linux-gnu`,
  `arm64-apple-macosx14.0.0`, `wasm32-unknown-unknown`,
  `x86_64-pc-windows-msvc`, ...). Which backends exist depends on how LLVM
  was built, so their `LLVMInitialize<Name>*` functions are looked up at run
  time (`dlsym`, `GetProcAddress`) rather than declared, and
  `initialize_target(name)` reports a missing one as an error.

## Debug info and JIT

`DebugBuilder(module)` emits DWARF (or CodeView with `use_codeview()`):
create a file and compile unit, attach a `function(...)` to each `Value`
with `set_subprogram`, and set `builder.set_location(...)` before emitting
instructions. Call `finalize()` before verifying the module.

`Jit.create()` runs code in-process: build the module in a
`Context(thread_safe = true)`, `add_module` it (the JIT takes ownership),
then `lookup(name)` returns the function's address to cast to an
`extern (...) => R` type and call.

## Not yet covered

- Intrinsics lookup, inline assembly, atomics and exception handling.
- Debug info covers files, compile units, functions, basic, pointer and
  struct types, lexical blocks, variables and locations; other `DIBuilder`
  calls are addable the same way.

## Releasing

CI (`.github/workflows/ci.yml`) runs the tests on Linux, macOS and
Windows for every push to `main` and every pull request. To release, set
`version` in `pep.toml`, merge, then push the matching tag
(`git tag v1.0.0 && git push origin v1.0.0`): CI tests the tag and
publishes a GitHub release for it. `pepper package add` and `pepper
package update` find versions by their tags.

## License

Apache-2.0; see [LICENSE](LICENSE).
