## `Context`: owns LLVM's types and constants, and makes the types, blocks
## and attributes of everything built in it.

import "llvm_c" as llvm_c;
import "support";
import "values";

## An LLVM context (`LLVMContextRef`), which owns the types and constants
## of the modules built in it. It is disposed when the last reference to it
## goes away; a `Module` or `Builder` made from it holds a reference, so it
## outlives them.
##
## A context is not thread-safe: use each one, and everything made in it,
## from one thread.
##
## @example
##     var context = llvm.Context();
##     var i32 = context.int32_type();
##     var answer = i32.const_int(42);   # i32 42
export struct Context {
    # Owns the LLVM context, or the ORC thread-safe context that owns it.
    var _handle: Handle<__ptr<void>>;
    var _ref: __ptr<void>;
    # The ORC thread-safe context, or null for a plain context.
    var _thread_safe: __ptr<void>;

    ## Creates an empty context.
    ##
    ## @param thread_safe whether to make it inside an ORC thread-safe
    ##   context, which a `Jit` needs for the modules it runs
    construct(thread_safe: bool = false) {
        if (thread_safe) {
            _thread_safe = llvm_c.LLVMOrcCreateNewThreadSafeContext();
            _ref = llvm_c.LLVMOrcThreadSafeContextGetContext(_thread_safe);
            _handle = Handle<__ptr<void>>(_thread_safe, (context) => llvm_c.LLVMOrcDisposeThreadSafeContext(context));
        } else {
            _ref = llvm_c.LLVMContextCreate();
            _handle = Handle<__ptr<void>>(_ref, (context) => llvm_c.LLVMContextDispose(context));
        }
    }

    ## The LLVM-C handle, for calls into `llvm_c`.
    var ref: __ptr<void> {
        get {
            return _ref;
        }
    }

    ## Reports whether the context was made for a `Jit` (`thread_safe`).
    ##
    ## @returns true for a thread-safe context
    is_thread_safe(): bool {
        return _thread_safe != __null;
    }

    ## Returns the 1-bit integer type, `i1`, which comparisons produce.
    ##
    ## @returns the type
    int1_type(): Type {
        return Type(llvm_c.LLVMInt1TypeInContext(ref));
    }

    ## Returns the 8-bit integer type, `i8`.
    ##
    ## @returns the type
    int8_type(): Type {
        return Type(llvm_c.LLVMInt8TypeInContext(ref));
    }

    ## Returns the 16-bit integer type, `i16`.
    ##
    ## @returns the type
    int16_type(): Type {
        return Type(llvm_c.LLVMInt16TypeInContext(ref));
    }

    ## Returns the 32-bit integer type, `i32`.
    ##
    ## @returns the type
    int32_type(): Type {
        return Type(llvm_c.LLVMInt32TypeInContext(ref));
    }

    ## Returns the 64-bit integer type, `i64`.
    ##
    ## @returns the type
    int64_type(): Type {
        return Type(llvm_c.LLVMInt64TypeInContext(ref));
    }

    ## Returns the integer type of `bits` bits.
    ##
    ## @param bits the width, from 1 to 2^23
    ## @returns the type
    int_type(bits: uint): Type {
        return Type(llvm_c.LLVMIntTypeInContext(ref, bits));
    }

    ## Returns the 32-bit floating-point type, `float`.
    ##
    ## @returns the type
    float_type(): Type {
        return Type(llvm_c.LLVMFloatTypeInContext(ref));
    }

    ## Returns the 64-bit floating-point type, `double`.
    ##
    ## @returns the type
    double_type(): Type {
        return Type(llvm_c.LLVMDoubleTypeInContext(ref));
    }

    ## Returns the `void` type.
    ##
    ## @returns the type
    void_type(): Type {
        return Type(llvm_c.LLVMVoidTypeInContext(ref));
    }

    ## Returns the pointer type, `ptr` (pointers carry no pointee type).
    ##
    ## @param address_space the address space; 0, the default, is ordinary memory
    ## @returns the type
    pointer_type(address_space: uint = 0): Type {
        return Type(llvm_c.LLVMPointerTypeInContext(ref, address_space));
    }

    ## Returns a literal struct type, such as `{ i32, ptr }`.
    ##
    ## @param fields the field types
    ## @param packed whether the fields have no padding between them
    ## @returns the type
    struct_type(fields: Type[], packed: bool = false): Type {
        var refs = _types(fields);
        return Type(llvm_c.LLVMStructTypeInContext(ref, refs.data(), refs.count, packed ? 1 : 0));
    }

    ## Returns a new named struct type with no fields yet; give it fields
    ## with `Type.set_body`. Named structs may refer to themselves.
    ##
    ## @param name the struct's name (`%name` in IR)
    ## @returns the type
    named_struct_type(name: String): Type {
        return Type(llvm_c.LLVMStructCreateNamed(ref, _c_string(name)));
    }

    ## Returns a constant array of the bytes of `text`.
    ##
    ## @param text the bytes
    ## @param null_terminated whether to add a NUL byte after them
    ## @returns the constant, of type `[n x i8]`
    const_string(text: String, null_terminated: bool = true): Value {
        return Value(llvm_c.LLVMConstStringInContext(ref, _c_string(text), text.size as uint, null_terminated ? 0 : 1));
    }

    ## Returns a constant of a literal struct type.
    ##
    ## @param fields the field values, each a constant
    ## @param packed whether the fields have no padding between them
    ## @returns the constant
    const_struct(fields: Value[], packed: bool = false): Value {
        var refs = _values(fields);
        return Value(llvm_c.LLVMConstStructInContext(ref, refs.data(), refs.count, packed ? 1 : 0));
    }

    ## Appends a new basic block to the end of a function.
    ##
    ## @param function the function
    ## @param name the block's name
    ## @returns the block
    append_block(function: Value, name: String = ""): BasicBlock {
        return BasicBlock(llvm_c.LLVMAppendBasicBlockInContext(ref, function.ref, _c_string(name)));
    }

    ## Returns an attribute by its IR name, such as `nounwind` or `noalias`.
    ##
    ## @param name the attribute's name
    ## @param value the attribute's integer value, for those that take one (`align`)
    ## @returns the attribute
    ## @panics if LLVM has no attribute named `name`
    attribute(name: String, value: ulong = 0): Attribute {
        var kind = llvm_c.LLVMGetEnumAttributeKindForName(_c_string(name), name.size);
        assert(kind != 0, $"Context.attribute: no attribute named '{name}'");
        return Attribute(llvm_c.LLVMCreateEnumAttribute(ref, kind, value));
    }

    ## Returns a string attribute (`"key"="value"`), such as `target-cpu`.
    ##
    ## @param key the attribute's key
    ## @param value the attribute's value
    ## @returns the attribute
    string_attribute(key: String, value: String): Attribute {
        return Attribute(
            llvm_c.LLVMCreateStringAttribute(
                ref, _c_string(key), key.size as uint, _c_string(value), value.size as uint
            )
        );
    }

    ## Creates a block and inserts it before `before`.
    ##
    ## @param before the block to insert before
    ## @param name the block's name
    ## @returns the new block
    insert_block(before: BasicBlock, name: String = ""): BasicBlock {
        return BasicBlock(llvm_c.LLVMInsertBasicBlockInContext(ref, before.ref, _c_string(name)));
    }

    ## Returns the kind of metadata named `name`, such as `tbaa`.
    ##
    ## @param name the kind's name
    ## @returns the kind
    metadata_kind(name: String): uint {
        return llvm_c.LLVMGetMDKindIDInContext(ref, _c_string(name), name.size as uint);
    }

    ## Returns a metadata string.
    ##
    ## @param text the string
    ## @returns the metadata
    metadata_string(text: String): Metadata {
        return Metadata(llvm_c.LLVMMDStringInContext2(ref, _c_string(text), text.size));
    }

    ## Returns a metadata tuple (`!{...}`).
    ##
    ## @param operands the operands
    ## @returns the metadata
    metadata_node(operands: Metadata[]): Metadata {
        var refs = _RefArray(operands.count);
        for (var index in 0..operands.count) {
            refs.set(index, operands[index].ref);
        }
        return Metadata(llvm_c.LLVMMDNodeInContext2(ref, refs.data(), refs.count as ulong));
    }

    ## Wraps metadata as a value, for `Value.set_metadata`.
    ##
    ## @param metadata the metadata
    ## @returns the value
    metadata_value(metadata: Metadata): Value {
        return Value(llvm_c.LLVMMetadataAsValue(ref, metadata.ref));
    }

    ## Wraps a constant as metadata.
    ##
    ## @param value the constant
    ## @returns the metadata
    constant_metadata(value: Value): Metadata {
        return Metadata(llvm_c.LLVMValueAsMetadata(value.ref));
    }

    ## Returns inline assembly in AT&T syntax that cannot unwind.
    ##
    ## @param function_type the assembly's function type
    ## @param assembly the assembly text
    ## @param constraints the operand constraints
    ## @param side_effects whether it has side effects
    ## @param align_stack whether it needs an aligned stack
    ## @returns the value to call
    inline_asm(
        function_type: Type, assembly: String, constraints: String, side_effects: bool, align_stack: bool
    ): Value {
        return Value(
            llvm_c.LLVMGetInlineAsm(
                function_type.ref,
                _c_string(assembly),
                assembly.size,
                _c_string(constraints),
                constraints.size,
                side_effects ? 1 : 0,
                align_stack ? 1 : 0,
                0,
                0
            )
        );
    }
}
