## Targets: registering the host's backend, `TargetMachine`, and compiling
## a module to an object file.

import "enums";
import "ir_module";
import "llvm_c" as llvm_c;
import "support";
import "symbols";
import "values";

## Registers the backend for the host's architecture (x86-64 or AArch64).
## `TargetMachine.create` registers every backend itself, so call this
## only to use `llvm_c` target functions directly. Calling it again does
## nothing.
[Target(Arch(x64))]
export initialize_native_target() {
    llvm_c.LLVMInitializeX86TargetInfo();
    llvm_c.LLVMInitializeX86Target();
    llvm_c.LLVMInitializeX86TargetMC();
    llvm_c.LLVMInitializeX86AsmPrinter();
}

## Registers the backend for the host's architecture (x86-64 or AArch64).
## `TargetMachine.create` registers every backend itself, so call this
## only to use `llvm_c` target functions directly. Calling it again does
## nothing.
[Target(Arch(aarch64))]
export initialize_native_target() {
    llvm_c.LLVMInitializeAArch64TargetInfo();
    llvm_c.LLVMInitializeAArch64Target();
    llvm_c.LLVMInitializeAArch64TargetMC();
    llvm_c.LLVMInitializeAArch64AsmPrinter();
}

## Returns the names of the backends LLVM 20 can be built with, as
## `initialize_target` takes them. A given LLVM build has some of them;
## the official builds and Linux distributions' have all but the
## experimental ones.
##
## @returns the backend names
export known_backends(): String[] {
    return [
        "AArch64",
        "AMDGPU",
        "ARC",
        "ARM",
        "AVR",
        "BPF",
        "CSKY",
        "DirectX",
        "Hexagon",
        "Lanai",
        "LoongArch",
        "M68k",
        "Mips",
        "MSP430",
        "NVPTX",
        "PowerPC",
        "RISCV",
        "Sparc",
        "SPIRV",
        "SystemZ",
        "VE",
        "WebAssembly",
        "X86",
        "XCore",
        "Xtensa",
    ];
}

## Registers one backend, so target machines for its triples can be made:
## `ARM` covers `armv7-*` and `thumbv7em-*`, `RISCV` covers `riscv32-*` and
## `riscv64-*`, `WebAssembly` covers `wasm32-*`, and so on. Calling it
## again does nothing.
##
## @param name the backend's name, as `known_backends()` lists it
## @returns Ok, or an Err when the LLVM library was built without that backend
## @example
##     llvm.initialize_target("RISCV").value();
##     var machine = llvm.TargetMachine.create("riscv64-unknown-linux-gnu").value();
export initialize_target(name: String): Result<void> {
    # TargetInfo, Target and TargetMC make the backend; the assembly
    # printer (object emission) and parser are there for nearly every one.
    var required = ["TargetInfo", "Target", "TargetMC"];
    var functions = Array<__ptr<void>>();
    for (var part in required) {
        var function = _llvm_symbol($"LLVMInitialize{name}{part}");
        if (function == __null) {
            return Result<void>.err(Error($"the LLVM library has no '{name}' backend"));
        }
        functions.append(function);
    }
    for (var part in ["AsmPrinter", "AsmParser"]) {
        var function = _llvm_symbol($"LLVMInitialize{name}{part}");
        if (function != __null) {
            functions.append(function);
        }
    }
    for (var function in functions) {
        var initialize = function as extern () => void;
        initialize();
    }
    return Result<void>.ok();
}

## Registers every backend the LLVM library was built with.
##
## @returns the names of the backends registered, from `known_backends()`
export initialize_all_targets(): String[] {
    var registered = Array<String>();
    for (var name in known_backends()) {
        if (initialize_target(name).is_ok()) {
            registered.append(name);
        }
    }
    return registered;
}

## Returns the short names of the registered targets, as LLVM spells them
## in triples and `-march` (`x86-64`, `aarch64`, `riscv64`, `wasm32`, ...).
## One backend registers several (`X86` registers `x86` and `x86-64`).
##
## @returns the target names
export registered_targets(): String[] {
    var names = Array<String>();
    var target = llvm_c.LLVMGetFirstTarget();
    while (target != __null) {
        names.append(_copy_string(llvm_c.LLVMGetTargetName(target)));
        target = llvm_c.LLVMGetNextTarget(target);
    }
    return names;
}

## Returns the host's target triple, such as `x86_64-pc-linux-gnu`.
##
## @returns the triple
export default_triple(): String {
    return _take_message(llvm_c.LLVMGetDefaultTargetTriple());
}

## Returns the host CPU's name, such as `znver4` or `apple-m2`.
##
## @returns the CPU name
export host_cpu(): String {
    return _take_message(llvm_c.LLVMGetHostCPUName());
}

## Returns the host CPU's features, such as `+sse4.2,+avx2,...`.
##
## @returns the feature string
export host_features(): String {
    return _take_message(llvm_c.LLVMGetHostCPUFeatures());
}

## Returns the version of the LLVM library the program runs against, such
## as `20.1.2`.
##
## @returns the version
export version(): String {
    var parts = _RefArray(2);
    var numbers = unsafe_cast<__ptr<uint>>(parts.data());
    llvm_c.LLVMGetVersion(numbers, numbers + 1, numbers + 2);
    return $"{numbers[0]}.{numbers[1]}.{numbers[2]}";
}

## A target machine (`LLVMTargetMachineRef`): a target, CPU and options
## that modules are compiled for. It is disposed when the last reference to
## it goes away.
##
## @example
##     var machine = llvm.TargetMachine.host().value();
##     machine.configure(module);
##     module.run_passes("default<O2>", machine).value();
##     machine.emit_to_file(module, "main.o").value();
export struct TargetMachine {
    var _handle: Handle<__ptr<void>>;
    var _data: Handle<__ptr<void>>;

    construct(ref: __ptr<void>) {
        _handle = Handle<__ptr<void>>(ref, (machine) => llvm_c.LLVMDisposeTargetMachine(machine));
        _data = Handle<__ptr<void>>(
            llvm_c.LLVMCreateTargetDataLayout(ref), (data) => llvm_c.LLVMDisposeTargetData(data)
        );
    }

    destruct {
        # The data layout first: it was made from the machine.
        _data.release();
        _handle.release();
    }

    ## Creates a target machine for the host: its triple, CPU and CPU
    ## features.
    ##
    ## @param level how hard code generation optimizes
    ## @param reloc how code addresses itself; position-independent by default, as for PIE executables
    ## @param code_model which addresses code may reach directly
    ## @returns the machine, or an Err when LLVM has no backend for the host
    static host(
        level: OptLevel = OptLevel.O2, reloc: RelocMode = RelocMode.Pic, code_model: CodeModel = CodeModel.Default
    ): Result<TargetMachine> {
        return create(default_triple(), host_cpu(), host_features(), level, reloc, code_model);
    }

    ## Creates a target machine for any triple a backend of the LLVM
    ## library handles, such as `aarch64-apple-darwin`,
    ## `riscv64-unknown-linux-gnu`, `wasm32-unknown-unknown` or
    ## `x86_64-pc-windows-msvc`. Registers every backend first
    ## (`initialize_all_targets`).
    ##
    ## @param triple the target triple, such as `aarch64-apple-darwin`
    ## @param cpu the CPU name; empty for the target's generic CPU
    ## @param features the CPU features (`+avx2,-sse4a`); empty for the CPU's own
    ## @param level how hard code generation optimizes
    ## @param reloc how code addresses itself
    ## @param code_model which addresses code may reach directly
    ## @returns the machine, or an Err when no registered backend handles `triple`
    static create(
        triple: String,
        cpu: String = "",
        features: String = "",
        level: OptLevel = OptLevel.O2,
        reloc: RelocMode = RelocMode.Pic,
        code_model: CodeModel = CodeModel.Default
    ): Result<TargetMachine> {
        initialize_all_targets();
        var target = _OutPointer();
        var message = _OutPointer();
        if (llvm_c.LLVMGetTargetFromTriple(
            _c_string(triple), target.data(), unsafe_cast<__ptr<__ptr<char>>>(message.data())
        )
            != 0) {
            return Result<TargetMachine>.err(Error(_take_message(message.get() as __ptr<char>)));
        }
        var machine = llvm_c.LLVMCreateTargetMachine(
            target.get(),
            _c_string(triple),
            _c_string(cpu),
            _c_string(features),
            level as int,
            reloc as int,
            code_model as int
        );
        if (machine == __null) {
            return Result<TargetMachine>.err(Error($"cannot create a target machine for '{triple}'"));
        }
        return Result<TargetMachine>.ok(TargetMachine(machine));
    }

    ## The LLVM-C handle, for calls into `llvm_c`.
    var ref: __ptr<void> {
        get {
            return _handle.value;
        }
    }

    ## Returns the machine's target triple.
    ##
    ## @returns the triple
    triple(): String {
        return _take_message(llvm_c.LLVMGetTargetMachineTriple(ref));
    }

    ## Returns the machine's data layout string.
    ##
    ## @returns the data layout
    data_layout(): String {
        return _take_message(llvm_c.LLVMCopyStringRepOfTargetData(_data.value));
    }

    ## Sets a module's target triple and data layout to this machine's, which
    ## optimization and code generation expect.
    ##
    ## @param module the module
    configure(module: Module) {
        module.set_target_triple(triple());
        llvm_c.LLVMSetModuleDataLayout(module.ref, _data.value);
    }

    ## Returns the size of a `type` in bytes on this machine, as an array
    ## element (with padding).
    ##
    ## @param value_type a sized type
    ## @returns the size
    size_of(value_type: Type): ulong {
        return llvm_c.LLVMABISizeOfType(_data.value, value_type.ref);
    }

    ## Returns the alignment of a `type` in bytes on this machine.
    ##
    ## @param value_type a sized type
    ## @returns the alignment
    alignment_of(value_type: Type): uint {
        return llvm_c.LLVMABIAlignmentOfType(_data.value, value_type.ref);
    }

    ## Returns the byte offset of a struct's field on this machine.
    ##
    ## @param value_type the struct type
    ## @param index the field's position
    ## @returns the offset
    offset_of(value_type: Type, index: uint): ulong {
        return llvm_c.LLVMOffsetOfElement(_data.value, value_type.ref, index);
    }

    ## Compiles a module to an object (or assembly) file.
    ##
    ## @param module the module, configured for this machine
    ## @param path the file to write
    ## @param kind an object file or assembly text
    ## @returns Ok, or an Err with LLVM's reason
    emit_to_file(module: Module, path: String, kind: FileKind = FileKind.Object): Result<void> {
        var message = _OutPointer();
        if (llvm_c.LLVMTargetMachineEmitToFile(
            ref, module.ref, _c_string(path), kind as int, unsafe_cast<__ptr<__ptr<char>>>(message.data())
        )
            != 0) {
            return Result<void>.err(Error(_take_message(message.get() as __ptr<char>)));
        }
        return Result<void>.ok();
    }

    ## Compiles a module to an object (or assembly) file in memory.
    ##
    ## @param module the module, configured for this machine
    ## @param kind an object file or assembly text
    ## @returns the file's bytes, or an Err with LLVM's reason
    emit_to_memory(module: Module, kind: FileKind = FileKind.Object): Result<u8[]> {
        var message = _OutPointer();
        var buffer = _OutPointer();
        if (llvm_c.LLVMTargetMachineEmitToMemoryBuffer(
            ref, module.ref, kind as int, unsafe_cast<__ptr<__ptr<char>>>(message.data()), buffer.data()
        )
            != 0) {
            return Result<u8[]>.err(Error(_take_message(message.get() as __ptr<char>)));
        }
        var owned = Handle<__ptr<void>>(buffer.get(), (memory) => llvm_c.LLVMDisposeMemoryBuffer(memory));
        var start = unsafe_cast<__ptr<u8>>(llvm_c.LLVMGetBufferStart(owned.value));
        var size = llvm_c.LLVMGetBufferSize(owned.value);
        var bytes = Array<u8>(size);
        for (var index in 0..size) {
            bytes.append(start[index]);
        }
        return Result<u8[]>.ok(bytes);
    }

    ## Returns how many bytes a store of `value_type` writes on this machine.
    ##
    ## @param value_type a sized type
    ## @returns the size
    store_size_of(value_type: Type): ulong {
        return llvm_c.LLVMStoreSizeOfType(_data.value, value_type.ref);
    }
}
