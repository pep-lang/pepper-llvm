## `Jit`: compiles modules in memory and returns the addresses of their
## functions, to call from the running program.

import llvm_c;
import "context";
import "ir_module";
import "support";
import "target";

## An ORC JIT (`LLVMOrcLLJITRef`) for the host. Add modules made in a
## thread-safe context (`Context(thread_safe = true)`), then `lookup` a
## function and cast its address to a C function pointer type to call it.
## Code it compiles can call the running program's C functions (`puts`,
## `malloc`, ...). It is disposed, with the code it compiled, when the last
## reference to it goes away.
##
## @example
##     var jit = llvm.Jit.create().value();
##     var context = llvm.Context(thread_safe = true);
##     var module = llvm.Module(context, "jitted");
##     # ... build `add(i32, i32): i32` ...
##     jit.add_module(module).value();
##     var add = jit.lookup("add").value() as extern (int, int) => int;
##     var five = add(2, 3);
export struct Jit {
    var _handle: Handle<__ptr<void>>;

    ## Takes ownership of an LLVM-C JIT handle; use `create` instead.
    ##
    ## @param ref the `LLVMOrcLLJITRef`
    construct(ref: __ptr<void>) {
        _handle = Handle<__ptr<void>>(
            ref,
            (jit) => {
                # Disposal reports an error only for code that failed to tear
                # down; there is no one left to tell.
                _take_error(llvm_c.LLVMOrcDisposeLLJIT(jit));
            }
        );
    }

    ## Creates a JIT for the host, which also resolves the running
    ## program's own C functions.
    ##
    ## @returns the JIT, or an Err with LLVM's reason
    static create(): Result<Jit> {
        initialize_native_target();
        var out = _OutPointer();
        var error = llvm_c.LLVMOrcCreateLLJIT(out.data(), __null);
        if (error != __null) {
            return Result<Jit>.err(Error(_take_error(error)));
        }
        var jit = Jit(out.get());
        var generator = _OutPointer();
        error = llvm_c.LLVMOrcCreateDynamicLibrarySearchGeneratorForProcess(
            generator.data(), llvm_c.LLVMOrcLLJITGetGlobalPrefix(jit.ref), __null, __null
        );
        if (error != __null) {
            return Result<Jit>.err(Error(_take_error(error)));
        }
        llvm_c.LLVMOrcJITDylibAddGenerator(llvm_c.LLVMOrcLLJITGetMainJITDylib(jit.ref), generator.get());
        return Result<Jit>.ok(jit);
    }

    ## The LLVM-C handle, for calls into `llvm_c`.
    var ref: __ptr<void> {
        get {
            return _handle.value;
        }
    }

    ## Returns the triple the JIT compiles for: the host's.
    ##
    ## @returns the triple
    triple(): String {
        return _copy_string(llvm_c.LLVMOrcLLJITGetTripleString(ref));
    }

    ## Returns the data layout the JIT compiles with.
    ##
    ## @returns the data layout
    data_layout(): String {
        return _copy_string(llvm_c.LLVMOrcLLJITGetDataLayoutStr(ref));
    }

    ## Adds a module, which the JIT compiles when one of its symbols is
    ## looked up. The JIT takes the module over: afterwards `module` is
    ## empty (`is_owned()` is false) and must not be used.
    ##
    ## @param module a module made in a thread-safe context
    ## @returns Ok, or an Err when the module's context is not thread-safe or a symbol is defined twice
    ## @panics if `module` was already given to a JIT
    add_module(module: Module): Result<void> {
        assert(module.is_owned(), "Jit.add_module: the module was already given to a JIT");
        if (!module.context.is_thread_safe()) {
            return Result<void>.err(
                Error("Jit.add_module: make the module's context with 'Context(thread_safe = true)'")
            );
        }
        var thread_safe = llvm_c.LLVMOrcCreateNewThreadSafeModule(module._handle.detach(), module.context._thread_safe);
        var error = llvm_c.LLVMOrcLLJITAddLLVMIRModule(ref, llvm_c.LLVMOrcLLJITGetMainJITDylib(ref), thread_safe);
        if (error != __null) {
            llvm_c.LLVMOrcDisposeThreadSafeModule(thread_safe);
            return Result<void>.err(Error(_take_error(error)));
        }
        return Result<void>.ok();
    }

    ## Compiles what a symbol needs, and returns its address. Cast it to
    ## the C function pointer type matching the function's signature
    ## (`as extern (int) => int`) to call it.
    ##
    ## @param name the function's or global's name
    ## @returns the address, or an Err when no added module or the program defines `name`
    lookup(name: String): Result<__ptr<void>> {
        var address = _RefArray(1);
        var error = llvm_c.LLVMOrcLLJITLookup(ref, address.data() as __ptr<ulong>, _c_string(name));
        if (error != __null) {
            return Result<__ptr<void>>.err(Error(_take_error(error)));
        }
        return Result<__ptr<void>>.ok(address.data()[0]);
    }
}
