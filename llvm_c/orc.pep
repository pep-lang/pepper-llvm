## The parts of `llvm-c/Orc.h` and `LLJIT.h` needed to compile modules in
## memory and call them: ORC's LLJIT, thread-safe contexts and modules,
## and resolving the process's own symbols.
##
## Every `LLVMOrc*Ref` is `void*`; errors are `LLVMErrorRef` (`void*`, null
## for success), read with `LLVMGetErrorMessage`.

## Creates an LLJIT for the host.
##
## @param jit receives the JIT
## @param builder a builder with options, or null for the defaults
## @returns null on success, else an error
export extern void* LLVMOrcCreateLLJIT(void** jit, void* builder);

## Destroys an LLJIT and the code it compiled.
##
## @param jit the JIT
## @returns null on success, else an error
export extern void* LLVMOrcDisposeLLJIT(void* jit);

## Returns the JIT's main library, which modules are added to.
##
## @param jit the JIT
## @returns the library
export extern void* LLVMOrcLLJITGetMainJITDylib(void* jit);

## Returns the prefix the JIT's platform puts on symbol names (`_` on
## macOS, none elsewhere).
##
## @param jit the JIT
## @returns the prefix character, or 0
export extern char LLVMOrcLLJITGetGlobalPrefix(void* jit);

## Returns the JIT's target triple; the JIT owns the string.
##
## @param jit the JIT
## @returns the triple
export extern char* LLVMOrcLLJITGetTripleString(void* jit);

## Returns the JIT's data layout string; the JIT owns the string.
##
## @param jit the JIT
## @returns the data layout
export extern char* LLVMOrcLLJITGetDataLayoutStr(void* jit);

## Adds a module, taking ownership of it.
##
## @param jit the JIT
## @param library the library to add it to
## @param module the thread-safe module
## @returns null on success, else an error
export extern void* LLVMOrcLLJITAddLLVMIRModule(void* jit, void* library, void* module);

## Compiles what a symbol needs and returns its address.
##
## @param jit the JIT
## @param address receives the address
## @param name the symbol's name, without the platform's prefix
## @returns null on success, else an error
export extern void* LLVMOrcLLJITLookup(void* jit, ulong* address, char* name);

## Creates a thread-safe context, which owns an LLVM context.
##
## @returns the thread-safe context
export extern void* LLVMOrcCreateNewThreadSafeContext();

## Returns the LLVM context a thread-safe context owns.
##
## @param context the thread-safe context
## @returns the LLVM context
export extern void* LLVMOrcThreadSafeContextGetContext(void* context);

## Releases a thread-safe context; modules made in it keep it alive.
##
## @param context the thread-safe context
export extern void LLVMOrcDisposeThreadSafeContext(void* context);

## Wraps a module for the JIT, taking ownership of it.
##
## @param module the module, made in the thread-safe context's LLVM context
## @param context the thread-safe context
## @returns the thread-safe module
export extern void* LLVMOrcCreateNewThreadSafeModule(void* module, void* context);

## Destroys a thread-safe module that was not added to a JIT.
##
## @param module the thread-safe module
export extern void LLVMOrcDisposeThreadSafeModule(void* module);

## Creates a generator that resolves symbols from the running process
## (the C library and everything else it loaded).
##
## @param generator receives the generator
## @param global_prefix the JIT's global prefix
## @param filter a predicate on names, or null for every symbol
## @param filter_context the predicate's context, or null
## @returns null on success, else an error
export extern void* LLVMOrcCreateDynamicLibrarySearchGeneratorForProcess(
    void** generator, char global_prefix, void* filter, void* filter_context
);

## Adds a definition generator to a library, which takes ownership of it.
##
## @param library the library
## @param generator the generator
export extern void LLVMOrcJITDylibAddGenerator(void* library, void* generator);
