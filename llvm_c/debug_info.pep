## The parts of `llvm-c/DebugInfo.h` a compiler needs to emit DWARF and
## CodeView: the `DIBuilder`, files, compile units, functions, types,
## variables, scopes and locations.
##
## Every `LLVMMetadataRef` and `LLVMDIBuilderRef` is `void*`;
## `LLVMDWARFSourceLanguage`, `LLVMDWARFEmissionKind`, `LLVMDIFlags` and
## `LLVMModuleFlagBehavior` are `int`; `LLVMDWARFTypeEncoding` is `uint`.
## Names are passed with their length in bytes.

## Creates a debug info builder for a module; finalize it before the module
## is verified or emitted.
##
## @param module the module
## @returns the builder
export extern void* LLVMCreateDIBuilder(void* module);

## Destroys a debug info builder.
##
## @param builder the builder
export extern void LLVMDisposeDIBuilder(void* builder);

## Resolves the debug info the builder made; call it once, when done.
##
## @param builder the builder
export extern void LLVMDIBuilderFinalize(void* builder);

## Returns the version of the debug info format, for the `Debug Info
## Version` module flag.
##
## @returns the version
export extern uint LLVMDebugMetadataVersion();

## Adds a module flag, such as `Debug Info Version` or `Dwarf Version`.
##
## @param module the module
## @param behavior the `LLVMModuleFlagBehavior` when modules are linked
## @param key the flag's name
## @param length the name's length
## @param value the flag's value
export extern void LLVMAddModuleFlag(void* module, int behavior, char* key, ulong length, void* value);

## Wraps a value (such as an integer constant) as metadata.
##
## @param value the value
## @returns the metadata
export extern void* LLVMValueAsMetadata(void* value);

## Describes a source file.
##
## @param builder the builder
## @param name the file name
## @param name_length the name's length
## @param directory the directory
## @param directory_length the directory's length
## @returns the file
export extern void* LLVMDIBuilderCreateFile(
    void* builder, char* name, ulong name_length, char* directory, ulong directory_length
);

## Describes a compile unit.
##
## @param builder the builder
## @param language the `LLVMDWARFSourceLanguage`
## @param file the main file
## @param producer the compiler's name and version
## @param producer_length the producer's length
## @param optimized nonzero when optimized
## @param flags the command-line flags
## @param flags_length the flags' length
## @param runtime_version the runtime version (Objective-C), or 0
## @param split_name the split DWARF file name, or empty
## @param split_name_length its length
## @param kind the `LLVMDWARFEmissionKind`
## @param dwo_id the split DWARF id, or 0
## @param split_debug_inlining nonzero to emit inlining info in split DWARF
## @param debug_info_for_profiling nonzero for profiling-friendly info
## @param sysroot the system root, or empty
## @param sysroot_length its length
## @param sdk the SDK name, or empty
## @param sdk_length its length
## @returns the compile unit
export extern void* LLVMDIBuilderCreateCompileUnit(
    void* builder,
    int language,
    void* file,
    char* producer,
    ulong producer_length,
    int optimized,
    char* flags,
    ulong flags_length,
    uint runtime_version,
    char* split_name,
    ulong split_name_length,
    int kind,
    uint dwo_id,
    int split_debug_inlining,
    int debug_info_for_profiling,
    char* sysroot,
    ulong sysroot_length,
    char* sdk,
    ulong sdk_length
);

## Describes a function (a `DISubprogram`).
##
## @param builder the builder
## @param scope the enclosing scope (a file or compile unit)
## @param name the source name
## @param name_length its length
## @param linkage_name the symbol name
## @param linkage_name_length its length
## @param file the file
## @param line the line it is declared on
## @param subroutine_type its type, from `LLVMDIBuilderCreateSubroutineType`
## @param local_to_unit nonzero when not visible outside the compile unit
## @param definition nonzero for a definition
## @param scope_line the line its body starts on
## @param flags the `LLVMDIFlags`
## @param optimized nonzero when optimized
## @returns the subprogram
export extern void* LLVMDIBuilderCreateFunction(
    void* builder,
    void* scope,
    char* name,
    ulong name_length,
    char* linkage_name,
    ulong linkage_name_length,
    void* file,
    uint line,
    void* subroutine_type,
    int local_to_unit,
    int definition,
    uint scope_line,
    int flags,
    int optimized
);

## Describes a function type: its return type first, then its parameters.
##
## @param builder the builder
## @param file the file
## @param types the types, the return type first (null for `void`)
## @param count the number of types
## @param flags the `LLVMDIFlags`
## @returns the type
export extern void* LLVMDIBuilderCreateSubroutineType(void* builder, void* file, void** types, uint count, int flags);

## Describes a basic type such as `int` or `double`.
##
## @param builder the builder
## @param name the type's name
## @param name_length its length
## @param size_in_bits the size in bits
## @param encoding the `DW_ATE_*` encoding
## @param flags the `LLVMDIFlags`
## @returns the type
export extern void* LLVMDIBuilderCreateBasicType(
    void* builder, char* name, ulong name_length, ulong size_in_bits, uint encoding, int flags
);

## Describes a pointer type.
##
## @param builder the builder
## @param pointee the type pointed to
## @param size_in_bits the pointer's size in bits
## @param align_in_bits the alignment in bits, or 0
## @param address_space the address space
## @param name the type's name, or empty
## @param name_length its length
## @returns the type
export extern void* LLVMDIBuilderCreatePointerType(
    void* builder,
    void* pointee,
    ulong size_in_bits,
    uint align_in_bits,
    uint address_space,
    char* name,
    ulong name_length
);

## Describes a struct type.
##
## @param builder the builder
## @param scope the enclosing scope
## @param name the struct's name
## @param name_length its length
## @param file the file
## @param line the line it is declared on
## @param size_in_bits the size in bits
## @param align_in_bits the alignment in bits
## @param flags the `LLVMDIFlags`
## @param derived_from the base type, or null
## @param elements the members, from `LLVMDIBuilderCreateMemberType`
## @param count the number of members
## @param runtime_language the runtime language (Objective-C), or 0
## @param vtable_holder the type holding the vtable, or null
## @param unique_id a unique identifier, or empty
## @param unique_id_length its length
## @returns the type
export extern void* LLVMDIBuilderCreateStructType(
    void* builder,
    void* scope,
    char* name,
    ulong name_length,
    void* file,
    uint line,
    ulong size_in_bits,
    uint align_in_bits,
    int flags,
    void* derived_from,
    void** elements,
    uint count,
    uint runtime_language,
    void* vtable_holder,
    char* unique_id,
    ulong unique_id_length
);

## Describes a member of a struct.
##
## @param builder the builder
## @param scope the struct (or file, before the struct exists)
## @param name the member's name
## @param name_length its length
## @param file the file
## @param line the line it is declared on
## @param size_in_bits the size in bits
## @param align_in_bits the alignment in bits
## @param offset_in_bits the offset in bits
## @param flags the `LLVMDIFlags`
## @param member_type the member's type
## @returns the member
export extern void* LLVMDIBuilderCreateMemberType(
    void* builder,
    void* scope,
    char* name,
    ulong name_length,
    void* file,
    uint line,
    ulong size_in_bits,
    uint align_in_bits,
    ulong offset_in_bits,
    int flags,
    void* member_type
);

## Describes a lexical block (a `{ ... }` scope) inside a function.
##
## @param builder the builder
## @param scope the enclosing scope
## @param file the file
## @param line the line it starts on
## @param column the column it starts on
## @returns the block
export extern void* LLVMDIBuilderCreateLexicalBlock(void* builder, void* scope, void* file, uint line, uint column);

## Describes a local variable.
##
## @param builder the builder
## @param scope the enclosing scope
## @param name the variable's name
## @param name_length its length
## @param file the file
## @param line the line it is declared on
## @param variable_type its type
## @param always_preserve nonzero to keep it even when optimized away
## @param flags the `LLVMDIFlags`
## @param align_in_bits the alignment in bits, or 0
## @returns the variable
export extern void* LLVMDIBuilderCreateAutoVariable(
    void* builder,
    void* scope,
    char* name,
    ulong name_length,
    void* file,
    uint line,
    void* variable_type,
    int always_preserve,
    int flags,
    uint align_in_bits
);

## Describes a function parameter.
##
## @param builder the builder
## @param scope the function
## @param name the parameter's name
## @param name_length its length
## @param number its position, counting from 1
## @param file the file
## @param line the line it is declared on
## @param variable_type its type
## @param always_preserve nonzero to keep it even when optimized away
## @param flags the `LLVMDIFlags`
## @returns the variable
export extern void* LLVMDIBuilderCreateParameterVariable(
    void* builder,
    void* scope,
    char* name,
    ulong name_length,
    uint number,
    void* file,
    uint line,
    void* variable_type,
    int always_preserve,
    int flags
);

## Describes a location expression (`DW_OP_*` operations); empty for a
## variable that is simply at its address.
##
## @param builder the builder
## @param operations the operations
## @param count the number of operations
## @returns the expression
export extern void* LLVMDIBuilderCreateExpression(void* builder, ulong* operations, ulong count);

## Declares that a variable lives at an address (`#dbg_declare`), at the end
## of a block.
##
## @param builder the builder
## @param storage the address (usually an `alloca`)
## @param variable the variable
## @param expression the location expression
## @param location the debug location of the declaration
## @param block the block to append to
## @returns the record
export extern void* LLVMDIBuilderInsertDeclareRecordAtEnd(
    void* builder, void* storage, void* variable, void* expression, void* location, void* block
);

## Makes a source location.
##
## @param context the context
## @param line the line
## @param column the column
## @param scope the scope it is in
## @param inlined_at where it was inlined, or null
## @returns the location
export extern void* LLVMDIBuilderCreateDebugLocation(
    void* context, uint line, uint column, void* scope, void* inlined_at
);

## Attaches a subprogram to a function definition.
##
## @param function the function
## @param subprogram the subprogram
export extern void LLVMSetSubprogram(void* function, void* subprogram);

## Sets the location the instruction builder gives the instructions it
## makes; null for none.
##
## @param builder the instruction builder
## @param location the location, or null
export extern void LLVMSetCurrentDebugLocation2(void* builder, void* location);

## Sets one instruction's location.
##
## @param instruction the instruction
## @param location the location
export extern void LLVMInstructionSetDebugLoc(void* instruction, void* location);
