## `Builder`: appends instructions to a basic block.

import llvm_c;
import "context";
import "enums";
import "support";
import "values";

## An instruction builder (`LLVMBuilderRef`). Move it to a block with
## `position_at_end`, then each call appends one instruction there and
## returns its result. It is disposed when the last reference to it goes
## away.
##
## Every method that makes a value takes an optional `name` for it (`%sum`
## in IR); without one LLVM numbers it (`%0`).
##
## @example
##     var context = llvm.Context();
##     var module = llvm.Module(context, "main");
##     var i32 = context.int32_type();
##     var add = module.add_function("add", llvm.Type.function(i32, [i32, i32]));
##     var builder = llvm.Builder(context);
##     builder.position_at_end(context.append_block(add, "entry"));
##     builder.return_value(builder.add(add.param(0), add.param(1), "sum"));
export struct Builder {
    var _handle: Handle<__ptr<void>>;
    ## The context the builder makes instructions in.
    var context: Context { get; }

    ## Creates a builder that is not positioned anywhere yet.
    ##
    ## @param context the context of the modules it builds into
    construct(context: Context) {
        this.context = context;
        _handle = Handle<__ptr<void>>(
            llvm_c.LLVMCreateBuilderInContext(context.ref), (builder) => llvm_c.LLVMDisposeBuilder(builder)
        );
    }

    destruct {
        # Before `context` is released, which may dispose it.
        _handle.release();
    }

    ## The LLVM-C handle, for calls into `llvm_c`.
    var ref: __ptr<void> {
        get {
            return _handle.value;
        }
    }

    ## Makes later instructions go at the end of `block`.
    ##
    ## @param block the block to append to
    position_at_end(block: BasicBlock) {
        llvm_c.LLVMPositionBuilderAtEnd(ref, block.ref);
    }

    ## Returns the block instructions go into, or a null block when the
    ## builder is not positioned.
    ##
    ## @returns the block
    insert_block(): BasicBlock {
        return BasicBlock(llvm_c.LLVMGetInsertBlock(ref));
    }

    ## Gives the instructions built from now on a source location, until it
    ## is changed or cleared.
    ##
    ## @param location the location, from `DebugBuilder.location`
    set_location(location: Metadata) {
        llvm_c.LLVMSetCurrentDebugLocation2(ref, location.ref);
    }

    ## Stops giving new instructions a source location.
    clear_location() {
        llvm_c.LLVMSetCurrentDebugLocation2(ref, __null);
    }

    # Terminators

    ## Builds `ret` with a value.
    ##
    ## @param value the value to return
    ## @returns the instruction
    return_value(value: Value): Value {
        return Value(llvm_c.LLVMBuildRet(ref, value.ref));
    }

    ## Builds `ret void`.
    ##
    ## @returns the instruction
    return_void(): Value {
        return Value(llvm_c.LLVMBuildRetVoid(ref));
    }

    ## Builds an unconditional branch (`br label`).
    ##
    ## @param destination the block to branch to
    ## @returns the instruction
    branch(destination: BasicBlock): Value {
        return Value(llvm_c.LLVMBuildBr(ref, destination.ref));
    }

    ## Builds a conditional branch (`br i1`).
    ##
    ## @param condition an `i1` value
    ## @param then_block the block when `condition` is true
    ## @param else_block the block when it is false
    ## @returns the instruction
    conditional_branch(condition: Value, then_block: BasicBlock, else_block: BasicBlock): Value {
        return Value(llvm_c.LLVMBuildCondBr(ref, condition.ref, then_block.ref, else_block.ref));
    }

    ## Builds a `switch`; add its cases with `Value.add_case`.
    ##
    ## @param value the integer switched on
    ## @param otherwise the block when no case matches
    ## @param case_count how many cases will be added, to reserve room
    ## @returns the instruction
    switch_on(value: Value, otherwise: BasicBlock, case_count: uint = 0): Value {
        return Value(llvm_c.LLVMBuildSwitch(ref, value.ref, otherwise.ref, case_count));
    }

    ## Builds `unreachable`.
    ##
    ## @returns the instruction
    unreachable(): Value {
        return Value(llvm_c.LLVMBuildUnreachable(ref));
    }

    # Arithmetic

    ## Builds integer addition (`add`).
    ##
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns the result
    add(left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildBinOp(ref, 8, left.ref, right.ref, _c_string(name)));
    }

    ## Builds integer subtraction (`sub`).
    ##
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns the result
    sub(left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildBinOp(ref, 10, left.ref, right.ref, _c_string(name)));
    }

    ## Builds integer multiplication (`mul`).
    ##
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns the result
    mul(left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildBinOp(ref, 12, left.ref, right.ref, _c_string(name)));
    }

    ## Builds signed integer division (`sdiv`).
    ##
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns the result
    signed_divide(left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildBinOp(ref, 15, left.ref, right.ref, _c_string(name)));
    }

    ## Builds unsigned integer division (`udiv`).
    ##
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns the result
    unsigned_divide(left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildBinOp(ref, 14, left.ref, right.ref, _c_string(name)));
    }

    ## Builds signed integer remainder (`srem`).
    ##
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns the result
    signed_remainder(left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildBinOp(ref, 18, left.ref, right.ref, _c_string(name)));
    }

    ## Builds unsigned integer remainder (`urem`).
    ##
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns the result
    unsigned_remainder(left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildBinOp(ref, 17, left.ref, right.ref, _c_string(name)));
    }

    ## Builds floating-point addition (`fadd`).
    ##
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns the result
    float_add(left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildBinOp(ref, 9, left.ref, right.ref, _c_string(name)));
    }

    ## Builds floating-point subtraction (`fsub`).
    ##
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns the result
    float_sub(left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildBinOp(ref, 11, left.ref, right.ref, _c_string(name)));
    }

    ## Builds floating-point multiplication (`fmul`).
    ##
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns the result
    float_mul(left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildBinOp(ref, 13, left.ref, right.ref, _c_string(name)));
    }

    ## Builds floating-point division (`fdiv`).
    ##
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns the result
    float_divide(left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildBinOp(ref, 16, left.ref, right.ref, _c_string(name)));
    }

    ## Builds floating-point remainder (`frem`).
    ##
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns the result
    float_remainder(left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildBinOp(ref, 19, left.ref, right.ref, _c_string(name)));
    }

    ## Builds a left shift (`shl`).
    ##
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns the result
    shift_left(left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildBinOp(ref, 20, left.ref, right.ref, _c_string(name)));
    }

    ## Builds a right shift that fills with zeros (`lshr`).
    ##
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns the result
    logical_shift_right(left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildBinOp(ref, 21, left.ref, right.ref, _c_string(name)));
    }

    ## Builds a right shift that copies the sign bit (`ashr`).
    ##
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns the result
    arithmetic_shift_right(left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildBinOp(ref, 22, left.ref, right.ref, _c_string(name)));
    }

    ## Builds a bitwise and (`and`).
    ##
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns the result
    bit_and(left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildBinOp(ref, 23, left.ref, right.ref, _c_string(name)));
    }

    ## Builds a bitwise or (`or`).
    ##
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns the result
    bit_or(left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildBinOp(ref, 24, left.ref, right.ref, _c_string(name)));
    }

    ## Builds a bitwise exclusive or (`xor`).
    ##
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns the result
    bit_xor(left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildBinOp(ref, 25, left.ref, right.ref, _c_string(name)));
    }
    ## Builds integer addition that cannot overflow as signed (`add nsw`).
    ##
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns the result
    nsw_add(left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildNSWAdd(ref, left.ref, right.ref, _c_string(name)));
    }

    ## Builds integer subtraction that cannot overflow as signed (`sub nsw`).
    ##
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns the result
    nsw_sub(left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildNSWSub(ref, left.ref, right.ref, _c_string(name)));
    }

    ## Builds integer multiplication that cannot overflow as signed (`mul nsw`).
    ##
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns the result
    nsw_mul(left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildNSWMul(ref, left.ref, right.ref, _c_string(name)));
    }

    ## Builds integer negation (`sub 0, value`).
    ##
    ## @param value the operand
    ## @param name the result's name
    ## @returns the result
    negate(value: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildNeg(ref, value.ref, _c_string(name)));
    }

    ## Builds floating-point negation (`fneg`).
    ##
    ## @param value the operand
    ## @param name the result's name
    ## @returns the result
    float_negate(value: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildFNeg(ref, value.ref, _c_string(name)));
    }

    ## Builds a bitwise not (`xor value, -1`).
    ##
    ## @param value the operand
    ## @param name the result's name
    ## @returns the result
    bit_not(value: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildNot(ref, value.ref, _c_string(name)));
    }

    # Comparisons

    ## Builds an integer or pointer comparison (`icmp`).
    ##
    ## @param predicate the comparison
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns an `i1`
    compare(predicate: IntPredicate, left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildICmp(ref, predicate as int, left.ref, right.ref, _c_string(name)));
    }

    ## Builds a floating-point comparison (`fcmp`).
    ##
    ## @param predicate the comparison
    ## @param left the left operand
    ## @param right the right operand, of the same type
    ## @param name the result's name
    ## @returns an `i1`
    float_compare(predicate: RealPredicate, left: Value, right: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildFCmp(ref, predicate as int, left.ref, right.ref, _c_string(name)));
    }

    ## Builds `select`: `then_value` when `condition` is true, else `else_value`.
    ##
    ## @param condition an `i1` value
    ## @param then_value the result when true
    ## @param else_value the result when false, of the same type
    ## @param name the result's name
    ## @returns the result
    select(condition: Value, then_value: Value, else_value: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildSelect(ref, condition.ref, then_value.ref, else_value.ref, _c_string(name)));
    }

    # Conversions

    ## Converts an integer to a narrower integer type (`trunc`).
    ##
    ## @param value the value to convert
    ## @param value_type the type to convert to
    ## @param name the result's name
    ## @returns the converted value
    truncate(value: Value, value_type: Type, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildCast(ref, 30, value.ref, value_type.ref, _c_string(name)));
    }

    ## Converts an integer to a wider type, filling with zeros (`zext`).
    ##
    ## @param value the value to convert
    ## @param value_type the type to convert to
    ## @param name the result's name
    ## @returns the converted value
    zero_extend(value: Value, value_type: Type, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildCast(ref, 31, value.ref, value_type.ref, _c_string(name)));
    }

    ## Converts an integer to a wider type, copying the sign bit (`sext`).
    ##
    ## @param value the value to convert
    ## @param value_type the type to convert to
    ## @param name the result's name
    ## @returns the converted value
    sign_extend(value: Value, value_type: Type, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildCast(ref, 32, value.ref, value_type.ref, _c_string(name)));
    }

    ## Converts a floating-point value to an unsigned integer (`fptoui`).
    ##
    ## @param value the value to convert
    ## @param value_type the type to convert to
    ## @param name the result's name
    ## @returns the converted value
    float_to_unsigned(value: Value, value_type: Type, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildCast(ref, 33, value.ref, value_type.ref, _c_string(name)));
    }

    ## Converts a floating-point value to a signed integer (`fptosi`).
    ##
    ## @param value the value to convert
    ## @param value_type the type to convert to
    ## @param name the result's name
    ## @returns the converted value
    float_to_signed(value: Value, value_type: Type, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildCast(ref, 34, value.ref, value_type.ref, _c_string(name)));
    }

    ## Converts an unsigned integer to floating point (`uitofp`).
    ##
    ## @param value the value to convert
    ## @param value_type the type to convert to
    ## @param name the result's name
    ## @returns the converted value
    unsigned_to_float(value: Value, value_type: Type, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildCast(ref, 35, value.ref, value_type.ref, _c_string(name)));
    }

    ## Converts a signed integer to floating point (`sitofp`).
    ##
    ## @param value the value to convert
    ## @param value_type the type to convert to
    ## @param name the result's name
    ## @returns the converted value
    signed_to_float(value: Value, value_type: Type, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildCast(ref, 36, value.ref, value_type.ref, _c_string(name)));
    }

    ## Converts a floating-point value to a narrower type (`fptrunc`).
    ##
    ## @param value the value to convert
    ## @param value_type the type to convert to
    ## @param name the result's name
    ## @returns the converted value
    float_truncate(value: Value, value_type: Type, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildCast(ref, 37, value.ref, value_type.ref, _c_string(name)));
    }

    ## Converts a floating-point value to a wider type (`fpext`).
    ##
    ## @param value the value to convert
    ## @param value_type the type to convert to
    ## @param name the result's name
    ## @returns the converted value
    float_extend(value: Value, value_type: Type, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildCast(ref, 38, value.ref, value_type.ref, _c_string(name)));
    }

    ## Converts a pointer to an integer (`ptrtoint`).
    ##
    ## @param value the value to convert
    ## @param value_type the type to convert to
    ## @param name the result's name
    ## @returns the converted value
    pointer_to_int(value: Value, value_type: Type, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildCast(ref, 39, value.ref, value_type.ref, _c_string(name)));
    }

    ## Converts an integer to a pointer (`inttoptr`).
    ##
    ## @param value the value to convert
    ## @param value_type the type to convert to
    ## @param name the result's name
    ## @returns the converted value
    int_to_pointer(value: Value, value_type: Type, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildCast(ref, 40, value.ref, value_type.ref, _c_string(name)));
    }

    ## Converts a value to another type of the same size, keeping its bits (`bitcast`).
    ##
    ## @param value the value to convert
    ## @param value_type the type to convert to
    ## @param name the result's name
    ## @returns the converted value
    bit_cast(value: Value, value_type: Type, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildCast(ref, 41, value.ref, value_type.ref, _c_string(name)));
    }

    # Memory

    ## Builds `alloca`: stack space for one `type` in the current function.
    ##
    ## @param value_type the type to make room for
    ## @param name the result's name
    ## @returns the address
    alloca(value_type: Type, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildAlloca(ref, value_type.ref, _c_string(name)));
    }

    ## Builds `load`.
    ##
    ## @param value_type the type to load
    ## @param pointer the address
    ## @param name the result's name
    ## @returns the loaded value
    load(value_type: Type, pointer: Value, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildLoad2(ref, value_type.ref, pointer.ref, _c_string(name)));
    }

    ## Builds `store`.
    ##
    ## @param value the value to store
    ## @param pointer the address
    ## @returns the instruction
    store(value: Value, pointer: Value): Value {
        return Value(llvm_c.LLVMBuildStore(ref, value.ref, pointer.ref));
    }

    ## Builds `getelementptr`: the address of an element inside `pointer`.
    ##
    ## @param value_type the type `pointer` points to, which the indices step through
    ## @param pointer the base address
    ## @param indices the indices, the first stepping over whole `type`s
    ## @param in_bounds whether the result stays inside the same object (`inbounds`)
    ## @param name the result's name
    ## @returns the address
    element_pointer(
        value_type: Type, pointer: Value, indices: Value[], in_bounds: bool = true, name: String = ""
    ): Value {
        var refs = _values(indices);
        if (in_bounds) {
            return Value(
                llvm_c.LLVMBuildInBoundsGEP2(ref, value_type.ref, pointer.ref, refs.data(), refs.count, _c_string(name))
            );
        }
        return Value(llvm_c.LLVMBuildGEP2(ref, value_type.ref, pointer.ref, refs.data(), refs.count, _c_string(name)));
    }

    ## Builds the address of a struct's field.
    ##
    ## @param value_type the struct type
    ## @param pointer the struct's address
    ## @param index the field's position
    ## @param name the result's name
    ## @returns the address
    field_pointer(value_type: Type, pointer: Value, index: uint, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildStructGEP2(ref, value_type.ref, pointer.ref, index, _c_string(name)));
    }

    ## Builds a private global holding `text` and a NUL byte, and returns
    ## its address.
    ##
    ## @param text the string
    ## @param name the global's name
    ## @returns the address
    global_string(text: String, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildGlobalString(ref, _c_string(text), _c_string(name)));
    }

    # Aggregates

    ## Builds `extractvalue`: an element of a struct or array value.
    ##
    ## @param aggregate the struct or array
    ## @param index the element's position
    ## @param name the result's name
    ## @returns the element
    extract_value(aggregate: Value, index: uint, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildExtractValue(ref, aggregate.ref, index, _c_string(name)));
    }

    ## Builds `insertvalue`: a copy of a struct or array value with one
    ## element replaced.
    ##
    ## @param aggregate the struct or array
    ## @param element the new element
    ## @param index the element's position
    ## @param name the result's name
    ## @returns the new aggregate
    insert_value(aggregate: Value, element: Value, index: uint, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildInsertValue(ref, aggregate.ref, element.ref, index, _c_string(name)));
    }

    # Calls and phis

    ## Builds `call`.
    ##
    ## @param function_type the callee's function type
    ## @param function the function to call (a function, or a pointer to one)
    ## @param arguments the arguments
    ## @param name the result's name; leave it empty when the function returns `void`
    ## @returns the call's result
    call(function_type: Type, function: Value, arguments: Value[], name: String = ""): Value {
        var refs = _values(arguments);
        return Value(
            llvm_c.LLVMBuildCall2(ref, function_type.ref, function.ref, refs.data(), refs.count, _c_string(name))
        );
    }

    ## Builds an empty `phi`; add its edges with `Value.add_incoming`.
    ##
    ## @param value_type the value's type
    ## @param name the result's name
    ## @returns the phi
    phi(value_type: Type, name: String = ""): Value {
        return Value(llvm_c.LLVMBuildPhi(ref, value_type.ref, _c_string(name)));
    }
}
