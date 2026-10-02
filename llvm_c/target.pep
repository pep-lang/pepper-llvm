## The parts of `llvm-c/Target.h`, `TargetMachine.h`, `Error.h` and
## `Transforms/PassBuilder.h` that a compiler needs: registering the host's
## backend, target machines, object emission, data layouts and the
## optimization pipeline.
##
## LLVM's `LLVMInitializeNativeTarget` and `LLVMInitializeAll*` are inline
## functions in its headers, so they cannot be bound. The host's backend is
## declared here; every other backend's `LLVMInitialize<Name>*` functions
## exist only when LLVM was built with that backend, so `llvm` looks them
## up at run time instead (`llvm.initialize_target`).

# Backends

## Registers the x86 target description.
[Target(Arch(x64))]
export extern void LLVMInitializeX86TargetInfo();

## Registers the x86 target.
[Target(Arch(x64))]
export extern void LLVMInitializeX86Target();

## Registers the x86 machine-code layer.
[Target(Arch(x64))]
export extern void LLVMInitializeX86TargetMC();

## Registers the x86 assembly printer, which object emission needs.
[Target(Arch(x64))]
export extern void LLVMInitializeX86AsmPrinter();

## Registers the AArch64 target description.
[Target(Arch(aarch64))]
export extern void LLVMInitializeAArch64TargetInfo();

## Registers the AArch64 target.
[Target(Arch(aarch64))]
export extern void LLVMInitializeAArch64Target();

## Registers the AArch64 machine-code layer.
[Target(Arch(aarch64))]
export extern void LLVMInitializeAArch64TargetMC();

## Registers the AArch64 assembly printer, which object emission needs.
[Target(Arch(aarch64))]
export extern void LLVMInitializeAArch64AsmPrinter();

# Hosts and targets

## Returns the first registered target, or null when none is registered.
##
## @returns the target
export extern void* LLVMGetFirstTarget();

## Returns the registered target after `target`, or null after the last.
##
## @param target a target
## @returns the next target
export extern void* LLVMGetNextTarget(void* target);

## Returns a target's short name, such as `x86-64` or `riscv64`; LLVM owns
## the string.
##
## @param target the target
## @returns the name
export extern char* LLVMGetTargetName(void* target);

## Returns a target's description; LLVM owns the string.
##
## @param target the target
## @returns the description
export extern char* LLVMGetTargetDescription(void* target);

## Returns the host's target triple; free it with `LLVMDisposeMessage`.
##
## @returns the triple
export extern char* LLVMGetDefaultTargetTriple();

## Returns the host CPU's name; free it with `LLVMDisposeMessage`.
##
## @returns the CPU name
export extern char* LLVMGetHostCPUName();

## Returns the host CPU's features (`+sse4.2,...`); free it with
## `LLVMDisposeMessage`.
##
## @returns the feature string
export extern char* LLVMGetHostCPUFeatures();

## Returns a triple in LLVM's normal form; free it with `LLVMDisposeMessage`.
##
## @param triple the triple
## @returns the normalized triple
export extern char* LLVMNormalizeTargetTriple(char* triple);

## Finds the registered target for a triple.
##
## @param triple the triple
## @param target receives the target
## @param message receives the reason on failure; free it with `LLVMDisposeMessage`
## @returns nonzero on failure
export extern int LLVMGetTargetFromTriple(char* triple, void** target, char** message);

# Target machines

## Creates a target machine.
##
## @param target the target from `LLVMGetTargetFromTriple`
## @param triple the triple
## @param cpu the CPU name, or empty for the default
## @param features the feature string, or empty
## @param level the `LLVMCodeGenOptLevel`
## @param reloc the `LLVMRelocMode`
## @param code_model the `LLVMCodeModel`
## @returns the target machine
export extern void* LLVMCreateTargetMachine(
    void* target, char* triple, char* cpu, char* features, int level, int reloc, int code_model
);

## Destroys a target machine.
##
## @param machine the target machine
export extern void LLVMDisposeTargetMachine(void* machine);

## Returns a target machine's triple; free it with `LLVMDisposeMessage`.
##
## @param machine the target machine
## @returns the triple
export extern char* LLVMGetTargetMachineTriple(void* machine);

## Creates the data layout a target machine uses; free it with
## `LLVMDisposeTargetData`.
##
## @param machine the target machine
## @returns the data layout
export extern void* LLVMCreateTargetDataLayout(void* machine);

## Destroys a data layout.
##
## @param data the data layout
export extern void LLVMDisposeTargetData(void* data);

## Returns a data layout as a string; free it with `LLVMDisposeMessage`.
##
## @param data the data layout
## @returns the layout string
export extern char* LLVMCopyStringRepOfTargetData(void* data);

## Sets a module's data layout.
##
## @param module the module
## @param data the data layout
export extern void LLVMSetModuleDataLayout(void* module, void* data);

## Returns a type's size in bytes, as an array element (with padding).
##
## @param data the data layout
## @param llvm_type the type
## @returns the size
export extern ulong LLVMABISizeOfType(void* data, void* llvm_type);

## Returns a type's ABI alignment in bytes.
##
## @param data the data layout
## @param llvm_type the type
## @returns the alignment
export extern uint LLVMABIAlignmentOfType(void* data, void* llvm_type);

## Returns the byte offset of a struct's field.
##
## @param data the data layout
## @param llvm_type the struct type
## @param index the field's position
## @returns the offset
export extern ulong LLVMOffsetOfElement(void* data, void* llvm_type, uint index);

## Compiles a module to an object or assembly file.
##
## @param machine the target machine
## @param module the module
## @param path the file to write
## @param kind the `LLVMCodeGenFileType`
## @param message receives the reason on failure; free it with `LLVMDisposeMessage`
## @returns nonzero on failure
export extern int LLVMTargetMachineEmitToFile(void* machine, void* module, char* path, int kind, char** message);

## Compiles a module to an object or assembly file in memory.
##
## @param machine the target machine
## @param module the module
## @param kind the `LLVMCodeGenFileType`
## @param message receives the reason on failure; free it with `LLVMDisposeMessage`
## @param buffer receives the output; free it with `LLVMDisposeMemoryBuffer`
## @returns nonzero on failure
export extern int LLVMTargetMachineEmitToMemoryBuffer(
    void* machine, void* module, int kind, char** message, void** buffer
);

## Returns a memory buffer's first byte.
##
## @param buffer the buffer
## @returns its bytes
export extern char* LLVMGetBufferStart(void* buffer);

## Returns a memory buffer's size in bytes.
##
## @param buffer the buffer
## @returns the size
export extern ulong LLVMGetBufferSize(void* buffer);

## Destroys a memory buffer.
##
## @param buffer the buffer
export extern void LLVMDisposeMemoryBuffer(void* buffer);

# Optimization

## Creates options for `LLVMRunPasses`.
##
## @returns the options
export extern void* LLVMCreatePassBuilderOptions();

## Destroys pass builder options.
##
## @param options the options
export extern void LLVMDisposePassBuilderOptions(void* options);

## Runs a pass pipeline (`opt -passes=` syntax, such as `default<O2>`) over
## a module.
##
## @param module the module
## @param passes the pipeline
## @param machine the target machine, or null
## @param options the options
## @returns null on success, else an error to read with `LLVMGetErrorMessage`
export extern void* LLVMRunPasses(void* module, char* passes, void* machine, void* options);

## Returns an error's message and frees the error; free the message with
## `LLVMDisposeErrorMessage`.
##
## @param error the error
## @returns the message
export extern char* LLVMGetErrorMessage(void* error);

## Frees a message from `LLVMGetErrorMessage`.
##
## @param message the message
export extern void LLVMDisposeErrorMessage(char* message);
