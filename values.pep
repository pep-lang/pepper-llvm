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
