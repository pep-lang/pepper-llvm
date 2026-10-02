## Targets: registering the host's backend, `TargetMachine`, and compiling
## a module to an object file.

import llvm_c;
import "enums";
import "ir_module";
import "support";
import "values";

## Registers the backend for the host's architecture (x86-64 or AArch64),
## which `TargetMachine` needs. Calling it again does nothing.
[Target(Arch(x64))]
export initialize_native_target() {
    llvm_c.LLVMInitializeX86TargetInfo();
    llvm_c.LLVMInitializeX86Target();
    llvm_c.LLVMInitializeX86TargetMC();
    llvm_c.LLVMInitializeX86AsmPrinter();
}

## Registers the backend for the host's architecture (x86-64 or AArch64),
## which `TargetMachine` needs. Calling it again does nothing.
[Target(Arch(aarch64))]
export initialize_native_target() {
    llvm_c.LLVMInitializeAArch64TargetInfo();
    llvm_c.LLVMInitializeAArch64Target();
    llvm_c.LLVMInitializeAArch64TargetMC();
    llvm_c.LLVMInitializeAArch64AsmPrinter();
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
    var numbers = parts.data() as __ptr<uint>;
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
    ## features. Registers the host's backend first.
    ##
    ## @param level how hard code generation optimizes
    ## @param reloc how code addresses itself; position-independent by default, as for PIE executables
    ## @param code_model which addresses code may reach directly
    ## @returns the machine, or an Err when LLVM has no backend for the host
    static host(
        level: OptLevel = OptLevel.O2, reloc: RelocMode = RelocMode.Pic, code_model: CodeModel = CodeModel.Default
    ): Result<TargetMachine> {
        initialize_native_target();
        return create(default_triple(), host_cpu(), host_features(), level, reloc, code_model);
    }

    ## Creates a target machine for a triple. Register its backend first
    ## (`initialize_native_target` for the host's).
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
        var target = _OutPointer();
        var message = _OutPointer();
        if (llvm_c.LLVMGetTargetFromTriple(_c_string(triple), target.data(), message.data() as __ptr<__ptr<char>>)
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
            ref, module.ref, _c_string(path), kind as int, message.data() as __ptr<__ptr<char>>
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
            ref, module.ref, kind as int, message.data() as __ptr<__ptr<char>>, buffer.data()
        )
            != 0) {
            return Result<u8[]>.err(Error(_take_message(message.get() as __ptr<char>)));
        }
        var owned = Handle<__ptr<void>>(buffer.get(), (memory) => llvm_c.LLVMDisposeMemoryBuffer(memory));
        var start = llvm_c.LLVMGetBufferStart(owned.value) as __ptr<u8>;
        var size = llvm_c.LLVMGetBufferSize(owned.value);
        var bytes = Array<u8>(size);
        for (var index in 0..size) {
            bytes.append(start[index]);
        }
        return Result<u8[]>.ok(bytes);
    }
}
