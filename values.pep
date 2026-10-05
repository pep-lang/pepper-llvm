## The handles a context owns: types, values (constants, functions,
## globals, instructions), basic blocks and attributes.
##
## These are small value structs around an LLVM-C pointer (`ref`). They own
## nothing: each stays valid while the `Context` (and, for a function,
## global or instruction, the `Module`) it came from is alive, so keep those
## alive while you use them.

import "enums";
import "llvm_c" as llvm_c;
import "support";

## An LLVM type (`LLVMTypeRef`). Get one from a `Context` (`int32_type()`,
## `pointer_type()`, ...), `Type.function`, or a value's `value_type()`.
[Value]
export struct Type {
    ## The LLVM-C handle; null for no type.
    var ref: __ptr<void>;

    ## Wraps an LLVM-C type handle.
    ##
    ## @param ref the `LLVMTypeRef`, or null
    construct(this.ref = __null) {}

    ## Returns a function type.
    ##
    ## @param result the return type
    ## @param params the parameter types
    ## @param variadic whether the function takes C variadic arguments after `params`
    ## @returns the function type
    ## @example
    ##     var context = llvm.Context();
    ##     var i32 = context.int32_type();
    ##     var add = llvm.Type.function(i32, [i32, i32]);   # i32 (i32, i32)
    static function(result: Type, params: Type[], variadic: bool = false): Type {
        var refs = _types(params);
        return Type(llvm_c.LLVMFunctionType(result.ref, refs.data(), refs.count, variadic ? 1 : 0));
    }

    ## Reports whether this is the null handle.
    ##
    ## @returns true when `ref` is null
    is_null(): bool {
        return ref == __null;
    }

    ## Returns what kind of type this is.
    ##
    ## @returns the kind
    kind(): TypeKind {
        return TypeKind.from_value(llvm_c.LLVMGetTypeKind(ref)).value();
    }

    ## Returns the type as LLVM IR text, such as `i32` or `{ i8, ptr }`.
    ##
    ## @returns the IR text
    to_string(): String {
        return _take_message(llvm_c.LLVMPrintTypeToString(ref));
    }

    ## Returns an integer type's width in bits.
    ##
    ## @returns the width
    int_width(): uint {
        return llvm_c.LLVMGetIntTypeWidth(ref);
    }

    ## Returns an array type of `count` elements of this type.
    ##
    ## @param count the number of elements
    ## @returns the array type
    array_type(count: ulong): Type {
        return Type(llvm_c.LLVMArrayType2(ref, count));
    }

    ## Returns a vector type of `count` elements of this type.
    ##
    ## @param count the number of elements
    ## @returns the vector type
    vector_type(count: uint): Type {
        return Type(llvm_c.LLVMVectorType(ref, count));
    }

    ## Sets the fields of a struct type made with `Context.named_struct_type`.
    ##
    ## @param fields the field types
    ## @param packed whether the fields have no padding between them
    set_body(fields: Type[], packed: bool = false) {
        var refs = _types(fields);
        llvm_c.LLVMStructSetBody(ref, refs.data(), refs.count, packed ? 1 : 0);
    }

    ## Returns an integer constant of this type.
    ##
    ## @param value the value; truncated to the type's width
    ## @returns the constant
    const_int(value: long): Value {
        return Value(llvm_c.LLVMConstInt(ref, value as ulong, 1));
    }

    ## Returns an integer constant of this type from unsigned bits.
    ##
    ## @param value the value; truncated to the type's width
    ## @returns the constant
    const_uint(value: ulong): Value {
        return Value(llvm_c.LLVMConstInt(ref, value, 0));
    }

    ## Returns a floating-point constant of this type.
    ##
    ## @param value the value
    ## @returns the constant
    const_real(value: double): Value {
        return Value(llvm_c.LLVMConstReal(ref, value));
    }

    ## Returns this type's zero value (`0`, `0.0`, `null`, `zeroinitializer`).
    ##
    ## @returns the constant
    zero(): Value {
        return Value(llvm_c.LLVMConstNull(ref));
    }

    ## Returns this type's `undef` value.
    ##
    ## @returns the constant
    undef(): Value {
        return Value(llvm_c.LLVMGetUndef(ref));
    }

    ## Returns this type's `poison` value.
    ##
    ## @returns the constant
    poison(): Value {
        return Value(llvm_c.LLVMGetPoison(ref));
    }

    ## Returns a constant of this struct type, which may be named (for a
    ## literal struct type, `Context.const_struct` works too).
    ##
    ## @param fields the field values, each a constant of its field's type
    ## @returns the constant
    const_struct(fields: Value[]): Value {
        var refs = _values(fields);
        return Value(llvm_c.LLVMConstNamedStruct(ref, refs.data(), refs.count));
    }

    ## Returns an array constant whose elements have this type.
    ##
    ## @param elements the elements, each a constant of this type
    ## @returns the constant
    const_array(elements: Value[]): Value {
        var refs = _values(elements);
        return Value(llvm_c.LLVMConstArray2(ref, refs.data(), refs.count as ulong));
    }

    ## Returns whether this is the same type as `other`.
    ##
    ## @param other the other type
    ## @returns true when both handles are the same type
    same(other: Type): bool {
        return ref == other.ref;
    }

    ## Returns a struct type's name, or "" for a literal struct.
    ##
    ## @returns the name
    struct_name(): String {
        return _copy_string(llvm_c.LLVMGetStructName(ref));
    }

    ## Returns the number of a struct type's fields.
    ##
    ## @returns the count
    field_count(): uint {
        return llvm_c.LLVMCountStructElementTypes(ref);
    }

    ## Returns a struct type's field type.
    ##
    ## @param index the field's position
    ## @returns the type
    field(index: uint): Type {
        return Type(llvm_c.LLVMStructGetTypeAtIndex(ref, index));
    }

    ## Returns whether a struct type has no body yet.
    ##
    ## @returns true when it is opaque
    is_opaque(): bool {
        return llvm_c.LLVMIsOpaqueStruct(ref) != 0;
    }

    ## Returns an array's or vector's element type.
    ##
    ## @returns the element type
    element_type(): Type {
        return Type(llvm_c.LLVMGetElementType(ref));
    }

    ## Returns an array type's length.
    ##
    ## @returns the length
    array_length(): ulong {
        return llvm_c.LLVMGetArrayLength2(ref);
    }

    ## Returns a vector type's length.
    ##
    ## @returns the length
    vector_size(): uint {
        return llvm_c.LLVMGetVectorSize(ref);
    }

    ## Returns a function type's result type.
    ##
    ## @returns the result type
    return_type(): Type {
        return Type(llvm_c.LLVMGetReturnType(ref));
    }

    ## Returns a function type's parameter types.
    ##
    ## @returns the types
    param_types(): Type[] {
        var count = llvm_c.LLVMCountParamTypes(ref);
        var refs = _RefArray(count);
        llvm_c.LLVMGetParamTypes(ref, refs.data());
        var types = Array<Type>();
        for (var index in 0..count) {
            types.append(Type(refs.data()[index]));
        }
        return types;
    }

    ## Returns the integer constant of this type with every bit set.
    ##
    ## @returns the constant
    all_ones(): Value {
        return Value(llvm_c.LLVMConstAllOnes(ref));
    }

    ## Returns this type's size as a constant `i64`.
    ##
    ## @returns the constant
    size_constant(): Value {
        return Value(llvm_c.LLVMSizeOf(ref));
    }

    ## Returns whether a function type takes variadic arguments.
    is_variadic(): bool {
        return llvm_c.LLVMIsFunctionVarArg(ref) != 0;
    }
}

## An LLVM value (`LLVMValueRef`): a constant, function, global variable,
## parameter or instruction.
[Value]
export struct Value {
    ## The LLVM-C handle; null for no value.
    var ref: __ptr<void>;

    ## Wraps an LLVM-C value handle.
    ##
    ## @param ref the `LLVMValueRef`, or null
    construct(this.ref = __null) {}

    ## Reports whether this is the null handle.
    ##
    ## @returns true when `ref` is null
    is_null(): bool {
        return ref == __null;
    }

    ## Returns the value's type.
    ##
    ## @returns the type
    value_type(): Type {
        return Type(llvm_c.LLVMTypeOf(ref));
    }

    ## Returns the value's name, or "" when it has none.
    ##
    ## @returns the name
    name(): String {
        var length = _RefArray(1);
        var text = llvm_c.LLVMGetValueName2(ref, unsafe_cast<__ptr<ulong>>(length.data()));
        return String(text, unsafe_cast<ulong>(length.data()[0]));
    }

    ## Names the value; LLVM adds a number when the name is taken.
    ##
    ## @param name the new name
    set_name(name: String) {
        llvm_c.LLVMSetValueName2(ref, _c_string(name), name.size);
    }

    ## Returns the value as LLVM IR text.
    ##
    ## @returns the IR text
    to_string(): String {
        return _take_message(llvm_c.LLVMPrintValueToString(ref));
    }

    ## Returns a function's parameter.
    ##
    ## @param index the parameter's position
    ## @returns the parameter
    ## @panics if `index` is not less than `param_count()`
    param(index: uint): Value {
        assert(index < param_count(), "Value.param: index out of range");
        return Value(llvm_c.LLVMGetParam(ref, index));
    }

    ## Returns the number of a function's parameters.
    ##
    ## @returns the count
    param_count(): uint {
        return llvm_c.LLVMCountParams(ref);
    }

    ## Returns a global's linkage.
    ##
    ## @returns the linkage
    linkage(): Linkage {
        return Linkage.from_value(llvm_c.LLVMGetLinkage(ref)).value();
    }

    ## Sets a function's or global variable's linkage.
    ##
    ## @param linkage the linkage
    set_linkage(linkage: Linkage) {
        llvm_c.LLVMSetLinkage(ref, linkage as int);
    }

    ## Sets a function's calling convention.
    ##
    ## @param convention the calling convention
    set_call_convention(convention: CallConvention) {
        llvm_c.LLVMSetFunctionCallConv(ref, convention as uint);
    }

    ## Gives a global variable its initial value.
    ##
    ## @param value a constant of the variable's type
    set_initializer(value: Value) {
        llvm_c.LLVMSetInitializer(ref, value.ref);
    }

    ## Returns a global variable's initial value.
    ##
    ## @returns the initializer, or Empty for a declaration
    initializer(): Value? {
        var value = llvm_c.LLVMGetInitializer(ref);
        if (value == __null) {
            return Optional<Value>.Empty;
        }
        return Optional<Value>.Value(Value(value));
    }

    ## Deletes a global variable from its module.
    delete_global() {
        llvm_c.LLVMDeleteGlobal(ref);
    }

    ## Puts a global in the object file section named `name`, exactly as
    ## given.
    ##
    ## @param name the section, such as `.init_array`
    set_section(name: String) {
        llvm_c.LLVMSetSection(ref, _c_string(name));
    }

    ## Marks a global variable constant, or not.
    ##
    ## @param constant whether the variable is constant
    set_global_constant(constant: bool) {
        llvm_c.LLVMSetGlobalConstant(ref, constant ? 1 : 0);
    }

    ## Adds an attribute to the function itself, such as `nounwind`.
    ##
    ## @param attribute the attribute, from `Context.attribute`
    add_function_attribute(attribute: Attribute) {
        llvm_c.LLVMAddAttributeAtIndex(ref, 0xFFFFFFFF as uint, attribute.ref);
    }

    ## Adds an attribute to a function's parameter, such as `noalias`.
    ##
    ## @param index the parameter's position
    ## @param attribute the attribute, from `Context.attribute`
    add_param_attribute(index: uint, attribute: Attribute) {
        llvm_c.LLVMAddAttributeAtIndex(ref, index + 1, attribute.ref);
    }

    ## Adds an attribute to a function's return value, such as `noalias`.
    ##
    ## @param attribute the attribute, from `Context.attribute`
    add_return_attribute(attribute: Attribute) {
        llvm_c.LLVMAddAttributeAtIndex(ref, 0, attribute.ref);
    }

    ## Adds incoming edges to a phi node, one per pair of `values` and
    ## `blocks`.
    ##
    ## @param values the value from each block
    ## @param blocks the blocks the values come from
    ## @panics if `values` and `blocks` differ in length
    add_incoming(values: Value[], blocks: BasicBlock[]) {
        assert(values.count == blocks.count, "Value.add_incoming: one block per value");
        var value_refs = _values(values);
        var block_refs = _RefArray(blocks.count);
        for (var index in 0..blocks.count) {
            block_refs.set(index, blocks[index].ref);
        }
        llvm_c.LLVMAddIncoming(ref, value_refs.data(), block_refs.data(), value_refs.count);
    }

    ## Adds a case to a switch instruction.
    ##
    ## @param on the constant the case matches
    ## @param destination the block to branch to
    add_case(on: Value, destination: BasicBlock) {
        llvm_c.LLVMAddCase(ref, on.ref, destination.ref);
    }

    ## Attaches a function's debug info (from `DebugBuilder.function`) to
    ## its definition.
    ##
    ## @param subprogram the function's debug info
    set_subprogram(subprogram: Metadata) {
        llvm_c.LLVMSetSubprogram(ref, subprogram.ref);
    }

    ## Sets an instruction's source location.
    ##
    ## @param location the location, from `DebugBuilder.location`
    set_location(location: Metadata) {
        llvm_c.LLVMInstructionSetDebugLoc(ref, location.ref);
    }

    ## Checks a function for errors, without printing them.
    ##
    ## @returns true when the function is well formed
    verify_function(): bool {
        return llvm_c.LLVMVerifyFunction(ref, 2) == 0;
    }

    ## Returns whether this is the same value as `other`.
    ##
    ## @param other the other value
    ## @returns true when both handles are the same value
    same(other: Value): bool {
        return ref == other.ref;
    }

    ## Returns whether the value is a constant.
    ##
    ## @returns true for a constant
    is_constant(): bool {
        return llvm_c.LLVMIsConstant(ref) != 0;
    }

    ## Returns whether the value is an integer constant.
    ##
    ## @returns true for a `ConstantInt`
    is_constant_int(): bool {
        return llvm_c.LLVMIsAConstantInt(ref) != __null;
    }

    ## Returns whether the value is a function.
    ##
    ## @returns true for a function
    is_function(): bool {
        return llvm_c.LLVMIsAFunction(ref) != __null;
    }

    ## Returns an integer constant's value, zero-extended.
    ##
    ## @returns the value
    zero_extended(): ulong {
        return llvm_c.LLVMConstIntGetZExtValue(ref);
    }

    ## Returns an integer constant's value, sign-extended.
    ##
    ## @returns the value
    sign_extended(): long {
        return llvm_c.LLVMConstIntGetSExtValue(ref);
    }

    ## Returns a function's or global's value type (a function's function
    ## type).
    ##
    ## @returns the type
    global_type(): Type {
        return Type(llvm_c.LLVMGlobalGetValueType(ref));
    }

    ## Returns a function's first basic block, or a null block.
    ##
    ## @returns the block
    first_block(): BasicBlock {
        return BasicBlock(llvm_c.LLVMGetFirstBasicBlock(ref));
    }

    ## Returns a function's last basic block, or a null block.
    ##
    ## @returns the block
    last_block(): BasicBlock {
        return BasicBlock(llvm_c.LLVMGetLastBasicBlock(ref));
    }

    ## Returns a function's basic blocks in order.
    ##
    ## @returns the blocks
    blocks(): BasicBlock[] {
        var blocks = Array<BasicBlock>();
        var block = first_block();
        while (!block.is_null()) {
            blocks.append(block);
            block = block.next();
        }
        return blocks;
    }

    ## Returns the number of a function's basic blocks.
    ##
    ## @returns the count
    block_count(): uint {
        return llvm_c.LLVMCountBasicBlocks(ref);
    }

    ## Returns whether anything uses the value.
    ##
    ## @returns true when it has a use
    has_uses(): bool {
        return llvm_c.LLVMGetFirstUse(ref) != __null;
    }

    ## Reports whether a function or global variable is only declared:
    ## a function without a body, a global without an initializer.
    ##
    ## @returns true for a declaration
    is_declaration(): bool {
        return llvm_c.LLVMIsDeclaration(ref) != 0;
    }

    ## Deletes a function from its module.
    delete_function() {
        llvm_c.LLVMDeleteFunction(ref);
    }

    ## Turns a function definition into a declaration: deletes its blocks,
    ## personality and debug subprogram, and makes it external.
    delete_body() {
        var block = llvm_c.LLVMGetFirstBasicBlock(ref);
        while (block != __null) {
            var next = llvm_c.LLVMGetNextBasicBlock(block);
            llvm_c.LLVMDeleteBasicBlock(block);
            block = next;
        }
        if (llvm_c.LLVMHasPersonalityFn(ref) != 0) {
            llvm_c.LLVMSetPersonalityFn(ref, __null);
        }
        llvm_c.LLVMSetSubprogram(ref, __null);
        llvm_c.LLVMSetLinkage(ref, Linkage.External as int);
    }

    ## Sets a function's or global variable's visibility to other objects
    ## linked with it.
    ##
    ## @param visibility the visibility
    set_visibility(visibility: Visibility) {
        llvm_c.LLVMSetVisibility(ref, visibility as int);
    }

    ## Puts a function or global variable in its module's comdat named
    ## `name` (any selection kind), adding the comdat when needed: the
    ## linker keeps one copy of a comdat's definitions across objects, which
    ## a `linkonce_odr` definition needs on Windows.
    ##
    ## @param name the comdat's name, usually the symbol's own
    set_comdat(name: String) {
        var comdat = llvm_c.LLVMGetOrInsertComdat(llvm_c.LLVMGetGlobalParent(ref), _c_string(name));
        llvm_c.LLVMSetComdat(ref, comdat);
    }

    ## Reports whether a function or global variable is in a comdat.
    ##
    ## @returns true when it is
    has_comdat(): bool {
        return llvm_c.LLVMGetComdat(ref) != __null;
    }

    ## Sets whether a global's address is significant: 0 for none, 1 for
    ## `local_unnamed_addr`, 2 for `unnamed_addr`.
    ##
    ## @param unnamed the setting
    set_unnamed_address(unnamed: int) {
        llvm_c.LLVMSetUnnamedAddress(ref, unnamed);
    }

    ## Returns whether a global's address is significant: 0 for none, 1 for
    ## `local_unnamed_addr`, 2 for `unnamed_addr`.
    ##
    ## @returns the setting
    unnamed_address(): int {
        return llvm_c.LLVMGetUnnamedAddress(ref);
    }

    ## Sets a global variable's `thread_local` mode (1 for the general
    ## dynamic model), or 0 for none.
    ##
    ## @param mode the mode
    set_thread_local_mode(mode: int) {
        llvm_c.LLVMSetThreadLocalMode(ref, mode);
    }

    ## Sets a global's, alloca's, load's or store's alignment.
    ##
    ## @param bytes the alignment
    set_alignment(bytes: uint) {
        llvm_c.LLVMSetAlignment(ref, bytes);
    }

    ## Sets an instruction's metadata of kind `kind`.
    ##
    ## @param kind the kind, from `Context.metadata_kind`
    ## @param node the metadata, as a value (`Context.metadata_value`)
    set_metadata(kind: uint, node: Value) {
        llvm_c.LLVMSetMetadata(ref, kind, node.ref);
    }

    ## Returns an instruction's opcode (`LLVMOpcode`).
    ##
    ## @returns the opcode
    opcode(): int {
        return llvm_c.LLVMGetInstructionOpcode(ref);
    }

    ## Returns the instruction after this one, or a null value.
    ##
    ## @returns the instruction
    next_instruction(): Value {
        return Value(llvm_c.LLVMGetNextInstruction(ref));
    }

    ## Returns the block this instruction is in.
    ##
    ## @returns the block
    instruction_block(): BasicBlock {
        return BasicBlock(llvm_c.LLVMGetInstructionParent(ref));
    }

    ## Removes this instruction from its block and deletes it.
    erase() {
        llvm_c.LLVMInstructionEraseFromParent(ref);
    }

    ## Marks a load or store volatile.
    ##
    ## @param is_volatile whether it is volatile
    set_volatile(is_volatile: bool) {
        llvm_c.LLVMSetVolatile(ref, is_volatile ? 1 : 0);
    }

    ## Sets an atomic load's or store's ordering (`LLVMAtomicOrdering`).
    ##
    ## @param ordering the ordering
    set_ordering(ordering: int) {
        llvm_c.LLVMSetOrdering(ref, ordering);
    }

    ## Adds an attribute to a call instruction: to the call itself at
    ## index `0xFFFFFFFF`, its result at 0, an argument at its position
    ## plus 1.
    ##
    ## @param index the attribute index
    ## @param attribute the attribute
    add_call_attribute(index: uint, attribute: Attribute) {
        llvm_c.LLVMAddCallSiteAttribute(ref, index, attribute.ref);
    }

    ## Returns a constant integer converted to a pointer of `pointer_type`.
    ##
    ## @param pointer_type the pointer type
    ## @returns the constant
    const_int_to_pointer(pointer_type: Type): Value {
        return Value(llvm_c.LLVMConstIntToPtr(ref, pointer_type.ref));
    }

    ## Returns a constant `getelementptr` from this constant.
    ##
    ## @param source_type the type the indices step through
    ## @param indices the indices
    ## @returns the constant
    const_gep(source_type: Type, indices: Value[]): Value {
        var refs = _values(indices);
        return Value(llvm_c.LLVMConstGEP2(source_type.ref, ref, refs.data(), refs.count as uint));
    }

    ## Returns operand `index` of this user.
    ##
    ## @param index the operand's position
    ## @returns the operand
    operand(index: uint): Value {
        return Value(llvm_c.LLVMGetOperand(ref, index));
    }

    ## Returns how many operands this user has.
    operand_count(): uint {
        return llvm_c.LLVMGetNumOperands(ref) as uint;
    }

    ## Returns whether the value is an instruction.
    is_instruction(): bool {
        return llvm_c.LLVMIsAInstruction(ref) != __null;
    }

    ## Returns the source element type of a `getelementptr`.
    gep_source_type(): Type {
        return Type(llvm_c.LLVMGetGEPSourceElementType(ref));
    }

    ## Returns the function's intrinsic ID, or 0 when it is no intrinsic.
    intrinsic_id(): uint {
        return llvm_c.LLVMGetIntrinsicID(ref);
    }

    ## Returns whether the function's parameter `index` has enum attribute
    ## `name`.
    ##
    ## @param index the parameter's position
    ## @param name the attribute (`signext`)
    ## @returns whether it has it
    has_param_attribute(index: uint, name: String): bool {
        var kind = llvm_c.LLVMGetEnumAttributeKindForName(_c_string(name), name.size);
        return llvm_c.LLVMGetEnumAttributeAtIndex(ref, index + 1, kind) != __null;
    }

    ## Sets the global's DLL storage class: 0 default, 1 import, 2 export.
    ##
    ## @param storage the class
    set_dll_storage_class(storage: int) {
        llvm_c.LLVMSetDLLStorageClass(ref, storage);
    }
}

## Debug info metadata (`LLVMMetadataRef`): a file, compile unit,
## function, type, scope, variable or location, from a `DebugBuilder`.
[Value]
export struct Metadata {
    ## The LLVM-C handle; null for none (such as a `void` return type).
    var ref: __ptr<void>;

    ## Wraps an LLVM-C metadata handle.
    ##
    ## @param ref the `LLVMMetadataRef`, or null
    construct(this.ref = __null) {}

    ## Reports whether this is the null handle.
    ##
    ## @returns true when `ref` is null
    is_null(): bool {
        return ref == __null;
    }
}

## A basic block (`LLVMBasicBlockRef`): a run of instructions ending in a
## branch or return. Make one with `Context.append_block`.
[Value]
export struct BasicBlock {
    ## The LLVM-C handle; null for no block.
    var ref: __ptr<void>;

    ## Wraps an LLVM-C basic block handle.
    ##
    ## @param ref the `LLVMBasicBlockRef`, or null
    construct(this.ref = __null) {}

    ## Reports whether this is the null handle.
    ##
    ## @returns true when `ref` is null
    is_null(): bool {
        return ref == __null;
    }

    ## Returns the block's name.
    ##
    ## @returns the name
    name(): String {
        return _copy_string(llvm_c.LLVMGetBasicBlockName(ref));
    }

    ## Returns the function the block belongs to.
    ##
    ## @returns the function
    parent(): Value {
        return Value(llvm_c.LLVMGetBasicBlockParent(ref));
    }

    ## Returns the block's terminator (its last branch or return), or a null
    ## `Value` when it has none yet.
    ##
    ## @returns the terminator, or a null value
    terminator(): Value {
        return Value(llvm_c.LLVMGetBasicBlockTerminator(ref));
    }

    ## Returns whether this is the same block as `other`.
    ##
    ## @param other the other block
    ## @returns true when both handles are the same block
    same(other: BasicBlock): bool {
        return ref == other.ref;
    }

    ## Returns the block after this one in its function, or a null block.
    ##
    ## @returns the block
    next(): BasicBlock {
        return BasicBlock(llvm_c.LLVMGetNextBasicBlock(ref));
    }

    ## Returns the block's first instruction, or a null value.
    ##
    ## @returns the instruction
    first_instruction(): Value {
        return Value(llvm_c.LLVMGetFirstInstruction(ref));
    }

    ## Returns the block's last instruction, or a null value.
    ##
    ## @returns the instruction
    last_instruction(): Value {
        return Value(llvm_c.LLVMGetLastInstruction(ref));
    }

    ## Moves the block to just after `after`.
    ##
    ## @param after the block to follow
    move_after(after: BasicBlock) {
        llvm_c.LLVMMoveBasicBlockAfter(ref, after.ref);
    }
}

## A function or parameter attribute (`LLVMAttributeRef`). Make one with
## `Context.attribute`.
[Value]
export struct Attribute {
    ## The LLVM-C handle.
    var ref: __ptr<void>;

    ## Wraps an LLVM-C attribute handle.
    ##
    ## @param ref the `LLVMAttributeRef`
    construct(this.ref = __null) {}
}

# The handles of `types` as a C array.
export _types(types: Type[]): _RefArray {
    var refs = _RefArray(types.count);
    for (var index in 0..types.count) {
        refs.set(index, types[index].ref);
    }
    return refs;
}

# The handles of `values` as a C array.
export _values(values: Value[]): _RefArray {
    var refs = _RefArray(values.count);
    for (var index in 0..values.count) {
        refs.set(index, values[index].ref);
    }
    return refs;
}
