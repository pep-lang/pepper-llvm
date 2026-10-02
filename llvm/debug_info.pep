## `DebugBuilder`: debug info (DWARF, or CodeView on Windows) for a module,
## so debuggers can map machine code back to source lines, functions,
## types and variables.

import llvm_c;
import "enums";
import "ir_module";
import "support";
import "values";

# DIFlagPrototyped: a function declared with its parameter types.
const _FLAG_PROTOTYPED = 256;
# LLVMModuleFlagBehaviorWarning: linking modules that disagree warns.
const _FLAG_BEHAVIOR_WARNING = 1;

## Makes the debug info of one module (`LLVMDIBuilderRef`). Make one per
## module, describe the compile unit, then each function, type and
## variable, attach locations to instructions, and call `finalize()`
## before verifying or emitting the module.
##
## It adds the `Debug Info Version` module flag, which LLVM needs to keep
## the debug info; `set_dwarf_version` and `use_codeview` add the others a
## platform's debugger expects.
##
## @example
##     var debug = llvm.DebugBuilder(module);
##     var file = debug.file("main.pep", "/src");
##     var unit = debug.compile_unit(file, "pepper 0.2");
##     var int_type = debug.basic_type("int", 32, llvm.DwarfEncoding.Signed);
##     var signature = debug.subroutine_type(file, int_type, [int_type]);
##     var info = debug.function(unit, "twice", file, 3, signature);
##     function.set_subprogram(info);
##     builder.set_location(debug.location(4, 12, info));
##     # ... build the body ...
##     debug.finalize();
export struct DebugBuilder {
    var _handle: Handle<__ptr<void>>;
    ## The module the debug info belongs to.
    var module: Module { get; }

    ## Creates a debug info builder for `module`, and adds the
    ## `Debug Info Version` module flag.
    ##
    ## @param module the module
    construct(module: Module) {
        this.module = module;
        _handle = Handle<__ptr<void>>(
            llvm_c.LLVMCreateDIBuilder(module.ref), (builder) => llvm_c.LLVMDisposeDIBuilder(builder)
        );
        _add_flag("Debug Info Version", llvm_c.LLVMDebugMetadataVersion());
    }

    destruct {
        # Before `module` is released, which may dispose it.
        _handle.release();
    }

    ## The LLVM-C handle, for calls into `llvm_c`.
    var ref: __ptr<void> {
        get {
            return _handle.value;
        }
    }

    _add_flag(name: String, value: uint) {
        var constant = llvm_c.LLVMConstInt(llvm_c.LLVMInt32TypeInContext(module.context.ref), value as ulong, 0);
        llvm_c.LLVMAddModuleFlag(
            module.ref, _FLAG_BEHAVIOR_WARNING, _c_string(name), name.size, llvm_c.LLVMValueAsMetadata(constant)
        );
    }

    ## Sets the DWARF version to emit (the `Dwarf Version` module flag), as
    ## Linux and macOS debuggers expect; 5 is current, 4 the most widely read.
    ##
    ## @param version the DWARF version
    set_dwarf_version(version: uint) {
        _add_flag("Dwarf Version", version);
    }

    ## Emits CodeView, which Windows debuggers read, instead of DWARF (the
    ## `CodeView` module flag).
    use_codeview() {
        _add_flag("CodeView", 1);
    }

    ## Resolves the debug info made so far. Call it once, after the last
    ## function is described and before the module is verified or emitted.
    finalize() {
        llvm_c.LLVMDIBuilderFinalize(ref);
    }

    ## Describes a source file.
    ##
    ## @param name the file's name, as the compiler was given it
    ## @param directory the directory the name is relative to
    ## @returns the file
    file(name: String, directory: String): Metadata {
        return Metadata(
            llvm_c.LLVMDIBuilderCreateFile(ref, _c_string(name), name.size, _c_string(directory), directory.size)
        );
    }

    ## Describes the compile unit: the whole module's source. Make exactly
    ## one per module.
    ##
    ## @param file the main source file
    ## @param producer the compiler's name and version
    ## @param language the source language debuggers should assume
    ## @param optimized whether the code is optimized
    ## @param emission how much debug info to emit
    ## @returns the compile unit, the scope of top-level functions
    compile_unit(
        file: Metadata,
        producer: String,
        language: DwarfLanguage = DwarfLanguage.C,
        optimized: bool = false,
        emission: DebugEmission = DebugEmission.Full
    ): Metadata {
        return Metadata(
            llvm_c.LLVMDIBuilderCreateCompileUnit(
                ref,
                language as int,
                file.ref,
                _c_string(producer),
                producer.size,
                optimized ? 1 : 0,
                "",
                0,
                0,
                "",
                0,
                emission as int,
                0,
                0,
                0,
                "",
                0,
                "",
                0
            )
        );
    }

    ## Describes a function definition. Attach the result to the function
    ## with `Value.set_subprogram`; it is also the scope of the locations
    ## and variables inside the function.
    ##
    ## @param scope the enclosing scope: the compile unit, or a file
    ## @param name the function's source name
    ## @param file the file it is in
    ## @param line the line it is declared on
    ## @param subroutine_type its type, from `subroutine_type`
    ## @param linkage_name its symbol name, when it differs from `name`
    ## @param local whether it is private to the compile unit
    ## @param scope_line the line its body starts on; 0 for `line`
    ## @param optimized whether it is optimized
    ## @returns the function's debug info
    function(
        scope: Metadata,
        name: String,
        file: Metadata,
        line: uint,
        subroutine_type: Metadata,
        linkage_name: String = "",
        local: bool = false,
        scope_line: uint = 0,
        optimized: bool = false
    ): Metadata {
        var body_line = scope_line == 0 ? line : scope_line;
        return Metadata(
            llvm_c.LLVMDIBuilderCreateFunction(
                ref,
                scope.ref,
                _c_string(name),
                name.size,
                _c_string(linkage_name),
                linkage_name.size,
                file.ref,
                line,
                subroutine_type.ref,
                local ? 1 : 0,
                1,
                body_line,
                _FLAG_PROTOTYPED,
                optimized ? 1 : 0
            )
        );
    }

    ## Describes a function type.
    ##
    ## @param file the file
    ## @param result the return type; a null `Metadata()` for `void`
    ## @param params the parameter types
    ## @returns the type
    subroutine_type(file: Metadata, result: Metadata, params: Metadata[]): Metadata {
        var refs = _RefArray(params.count + 1);
        refs.set(0, result.ref);
        for (var index in 0..params.count) {
            refs.set(index + 1, params[index].ref);
        }
        return Metadata(llvm_c.LLVMDIBuilderCreateSubroutineType(ref, file.ref, refs.data(), refs.count, 0));
    }

    ## Describes a basic type, such as `int` or `double`.
    ##
    ## @param name the type's source name
    ## @param size_in_bits its size in bits
    ## @param encoding how its bits are read
    ## @returns the type
    basic_type(name: String, size_in_bits: ulong, encoding: DwarfEncoding): Metadata {
        return Metadata(
            llvm_c.LLVMDIBuilderCreateBasicType(ref, _c_string(name), name.size, size_in_bits, encoding as uint, 0)
        );
    }

    ## Describes a pointer type.
    ##
    ## @param pointee the type pointed to
    ## @param size_in_bits the pointer's size in bits
    ## @param name the type's name, if it has one
    ## @returns the type
    pointer_type(pointee: Metadata, size_in_bits: ulong, name: String = ""): Metadata {
        return Metadata(
            llvm_c.LLVMDIBuilderCreatePointerType(ref, pointee.ref, size_in_bits, 0, 0, _c_string(name), name.size)
        );
    }

    ## Describes a member of a struct, for `struct_type`.
    ##
    ## @param scope the file the struct is declared in
    ## @param name the member's name
    ## @param file the file
    ## @param line the line it is declared on
    ## @param size_in_bits its size in bits
    ## @param align_in_bits its alignment in bits
    ## @param offset_in_bits its offset in bits from the start of the struct
    ## @param member_type its type
    ## @returns the member
    member_type(
        scope: Metadata,
        name: String,
        file: Metadata,
        line: uint,
        size_in_bits: ulong,
        align_in_bits: uint,
        offset_in_bits: ulong,
        member_type: Metadata
    ): Metadata {
        return Metadata(
            llvm_c.LLVMDIBuilderCreateMemberType(
                ref,
                scope.ref,
                _c_string(name),
                name.size,
                file.ref,
                line,
                size_in_bits,
                align_in_bits,
                offset_in_bits,
                0,
                member_type.ref
            )
        );
    }

    ## Describes a struct type.
    ##
    ## @param scope the enclosing scope: the compile unit, or a file
    ## @param name the struct's name
    ## @param file the file
    ## @param line the line it is declared on
    ## @param size_in_bits its size in bits
    ## @param align_in_bits its alignment in bits
    ## @param members its members, from `member_type`
    ## @returns the type
    struct_type(
        scope: Metadata,
        name: String,
        file: Metadata,
        line: uint,
        size_in_bits: ulong,
        align_in_bits: uint,
        members: Metadata[]
    ): Metadata {
        var refs = _RefArray(members.count);
        for (var index in 0..members.count) {
            refs.set(index, members[index].ref);
        }
        return Metadata(
            llvm_c.LLVMDIBuilderCreateStructType(
                ref,
                scope.ref,
                _c_string(name),
                name.size,
                file.ref,
                line,
                size_in_bits,
                align_in_bits,
                0,
                __null,
                refs.data(),
                refs.count,
                0,
                __null,
                "",
                0
            )
        );
    }

    ## Describes a block scope (`{ ... }`) inside a function, for the
    ## variables declared in it.
    ##
    ## @param scope the enclosing function or block
    ## @param file the file
    ## @param line the line it starts on
    ## @param column the column it starts on
    ## @returns the block
    lexical_block(scope: Metadata, file: Metadata, line: uint, column: uint): Metadata {
        return Metadata(llvm_c.LLVMDIBuilderCreateLexicalBlock(ref, scope.ref, file.ref, line, column));
    }

    ## Describes a local variable; give it an address with `declare`.
    ##
    ## @param scope the function or block it is declared in
    ## @param name its name
    ## @param file the file
    ## @param line the line it is declared on
    ## @param variable_type its type
    ## @returns the variable
    local_variable(scope: Metadata, name: String, file: Metadata, line: uint, variable_type: Metadata): Metadata {
        return Metadata(
            llvm_c.LLVMDIBuilderCreateAutoVariable(
                ref, scope.ref, _c_string(name), name.size, file.ref, line, variable_type.ref, 1, 0, 0
            )
        );
    }

    ## Describes a function parameter; give it an address with `declare`.
    ##
    ## @param scope the function
    ## @param name its name
    ## @param number its position, counting from 1
    ## @param file the file
    ## @param line the line it is declared on
    ## @param variable_type its type
    ## @returns the variable
    parameter_variable(
        scope: Metadata, name: String, number: uint, file: Metadata, line: uint, variable_type: Metadata
    ): Metadata {
        return Metadata(
            llvm_c.LLVMDIBuilderCreateParameterVariable(
                ref, scope.ref, _c_string(name), name.size, number, file.ref, line, variable_type.ref, 1, 0
            )
        );
    }

    ## Records that a variable lives at `storage` (usually its `alloca`),
    ## at the end of `block`.
    ##
    ## @param storage the variable's address
    ## @param variable the variable, from `local_variable` or `parameter_variable`
    ## @param location where it is declared, from `location`
    ## @param block the block to record it in
    declare(storage: Value, variable: Metadata, location: Metadata, block: BasicBlock) {
        var expression = llvm_c.LLVMDIBuilderCreateExpression(ref, __null, 0);
        llvm_c.LLVMDIBuilderInsertDeclareRecordAtEnd(
            ref, storage.ref, variable.ref, expression, location.ref, block.ref
        );
    }

    ## Returns a source location, for `Builder.set_location` and
    ## `Value.set_location`.
    ##
    ## @param line the line, counting from 1
    ## @param column the column, counting from 1; 0 for none
    ## @param scope the function or block it is in
    ## @returns the location
    location(line: uint, column: uint, scope: Metadata): Metadata {
        return Metadata(llvm_c.LLVMDIBuilderCreateDebugLocation(module.context.ref, line, column, scope.ref, __null));
    }
}
