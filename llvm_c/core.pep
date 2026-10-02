## The parts of `llvm-c/Core.h`, `Analysis.h` and `BitWriter.h` that a
## compiler needs: contexts, modules, types, values, constants, basic
## blocks, the instruction builder, verification and bitcode output.
##
## Each declaration is the C function of the same name, with C's types:
## every `LLVM*Ref` handle is `void*`, `LLVMBool` and the enums are `int`,
## `unsigned` is `uint`, and `size_t` and `uint64_t` are `ulong`. See the
## LLVM-C headers for what each does. Strings LLVM returns as `char*` are
## freed with `LLVMDisposeMessage`; a returned `const char*` is not.

# Errors and messages

## Frees a string LLVM returned (`LLVMPrintModuleToString` and similar).
##
## @param message the string to free
export extern void LLVMDisposeMessage(char* message);

# Contexts

## Creates a context, which owns types and constants.
##
## @returns the new context
export extern void* LLVMContextCreate();

## Destroys a context and everything it owns.
##
## @param context the context to destroy
export extern void LLVMContextDispose(void* context);

## Returns the attribute kind for an attribute name such as `nounwind`, or 0.
##
## @param name the attribute's name
## @param length the name's length in bytes
## @returns the kind, or 0 for an unknown name
export extern uint LLVMGetEnumAttributeKindForName(char* name, ulong length);

## Creates an enum attribute (one with an optional integer value).
##
## @param context the context that owns the attribute
## @param kind the kind from `LLVMGetEnumAttributeKindForName`
## @param value the attribute's integer value, 0 for none
## @returns the attribute
export extern void* LLVMCreateEnumAttribute(void* context, uint kind, ulong value);

# Modules

## Creates an empty module in `context`.
##
## @param name the module's identifier
## @param context the context that owns its types
## @returns the new module
export extern void* LLVMModuleCreateWithNameInContext(char* name, void* context);

## Destroys a module and the functions and globals in it.
##
## @param module the module to destroy
export extern void LLVMDisposeModule(void* module);

## Returns the module's target triple; the module owns the string.
##
## @param module the module
## @returns the triple
export extern char* LLVMGetTarget(void* module);

## Sets the module's target triple.
##
## @param module the module
## @param triple the triple
export extern void LLVMSetTarget(void* module, char* triple);

## Returns the module's data layout string; the module owns the string.
##
## @param module the module
## @returns the data layout
export extern char* LLVMGetDataLayoutStr(void* module);

## Sets the module's data layout string.
##
## @param module the module
## @param layout the data layout
export extern void LLVMSetDataLayout(void* module, char* layout);

## Sets the source file name recorded in the module.
##
## @param module the module
## @param name the file name
## @param length the name's length in bytes
export extern void LLVMSetSourceFileName(void* module, char* name, ulong length);

## Returns the module's textual IR; free it with `LLVMDisposeMessage`.
##
## @param module the module
## @returns the IR text
export extern char* LLVMPrintModuleToString(void* module);

## Adds a function declaration to the module.
##
## @param module the module
## @param name the function's name
## @param llvm_type the function's type
## @returns the function
export extern void* LLVMAddFunction(void* module, char* name, void* llvm_type);

## Returns the function named `name`, or null.
##
## @param module the module
## @param name the function's name
## @returns the function, or null
export extern void* LLVMGetNamedFunction(void* module, char* name);

## Adds a global variable to the module.
##
## @param module the module
## @param llvm_type the variable's type
## @param name the variable's name
## @returns the global
export extern void* LLVMAddGlobal(void* module, void* llvm_type, char* name);

## Returns the global variable named `name`, or null.
##
## @param module the module
## @param name the variable's name
## @returns the global, or null
export extern void* LLVMGetNamedGlobal(void* module, char* name);

## Checks the module; with action 2 (return status) it only reports.
##
## @param module the module
## @param action 0 abort, 1 print, 2 return status
## @param message receives the problems found; free with `LLVMDisposeMessage`
## @returns nonzero when the module is broken
export extern int LLVMVerifyModule(void* module, int action, char** message);

## Checks one function.
##
## @param function the function
## @param action 0 abort, 1 print, 2 return status
## @returns nonzero when the function is broken
export extern int LLVMVerifyFunction(void* function, int action);

## Writes the module as bitcode.
##
## @param module the module
## @param path the file to write
## @returns 0 on success
export extern int LLVMWriteBitcodeToFile(void* module, char* path);

# Types

## Returns the type's kind (`LLVMTypeKind`).
##
## @param llvm_type the type
## @returns the kind
export extern int LLVMGetTypeKind(void* llvm_type);

## Returns the type as IR text; free it with `LLVMDisposeMessage`.
##
## @param llvm_type the type
## @returns the text
export extern char* LLVMPrintTypeToString(void* llvm_type);

## Returns the 1-bit integer type.
##
## @param context the context
## @returns the type
export extern void* LLVMInt1TypeInContext(void* context);

## Returns the 8-bit integer type.
##
## @param context the context
## @returns the type
export extern void* LLVMInt8TypeInContext(void* context);

## Returns the 16-bit integer type.
##
## @param context the context
## @returns the type
export extern void* LLVMInt16TypeInContext(void* context);

## Returns the 32-bit integer type.
##
## @param context the context
## @returns the type
export extern void* LLVMInt32TypeInContext(void* context);

## Returns the 64-bit integer type.
##
## @param context the context
## @returns the type
export extern void* LLVMInt64TypeInContext(void* context);

## Returns the integer type of `bits` bits.
##
## @param context the context
## @param bits the width
## @returns the type
export extern void* LLVMIntTypeInContext(void* context, uint bits);

## Returns an integer type's width in bits.
##
## @param llvm_type the integer type
## @returns the width
export extern uint LLVMGetIntTypeWidth(void* llvm_type);

## Returns the 32-bit floating-point type.
##
## @param context the context
## @returns the type
export extern void* LLVMFloatTypeInContext(void* context);

## Returns the 64-bit floating-point type.
##
## @param context the context
## @returns the type
export extern void* LLVMDoubleTypeInContext(void* context);

## Returns the void type.
##
## @param context the context
## @returns the type
export extern void* LLVMVoidTypeInContext(void* context);

## Returns the (opaque) pointer type in an address space.
##
## @param context the context
## @param address_space the address space, 0 by default
## @returns the type
export extern void* LLVMPointerTypeInContext(void* context, uint address_space);

## Returns a function type.
##
## @param result the return type
## @param params the parameter types
## @param count the number of parameters
## @param variadic nonzero for a C variadic function
## @returns the type
export extern void* LLVMFunctionType(void* result, void** params, uint count, int variadic);

## Returns a literal (unnamed) struct type.
##
## @param context the context
## @param fields the field types
## @param count the number of fields
## @param packed nonzero for no padding
## @returns the type
export extern void* LLVMStructTypeInContext(void* context, void** fields, uint count, int packed);

## Creates a named struct type with no body yet.
##
## @param context the context
## @param name the struct's name
## @returns the type
export extern void* LLVMStructCreateNamed(void* context, char* name);

## Sets a named struct's fields.
##
## @param llvm_type the struct type
## @param fields the field types
## @param count the number of fields
## @param packed nonzero for no padding
export extern void LLVMStructSetBody(void* llvm_type, void** fields, uint count, int packed);

## Returns an array type.
##
## @param element the element type
## @param count the number of elements
## @returns the type
export extern void* LLVMArrayType2(void* element, ulong count);

## Returns a vector type.
##
## @param element the element type
## @param count the number of elements
## @returns the type
export extern void* LLVMVectorType(void* element, uint count);

# Values

## Returns a value's type.
##
## @param value the value
## @returns the type
export extern void* LLVMTypeOf(void* value);

## Returns a value's name; the value owns the string.
##
## @param value the value
## @param length receives the name's length in bytes
## @returns the name
export extern char* LLVMGetValueName2(void* value, ulong* length);

## Sets a value's name.
##
## @param value the value
## @param name the name
## @param length the name's length in bytes
export extern void LLVMSetValueName2(void* value, char* name, ulong length);

## Returns the value as IR text; free it with `LLVMDisposeMessage`.
##
## @param value the value
## @returns the text
export extern char* LLVMPrintValueToString(void* value);

## Returns the number of a function's parameters.
##
## @param function the function
## @returns the count
export extern uint LLVMCountParams(void* function);

## Returns a function's parameter.
##
## @param function the function
## @param index the parameter's position
## @returns the parameter
export extern void* LLVMGetParam(void* function, uint index);

## Sets a function's calling convention (`LLVMCallConv`).
##
## @param function the function
## @param convention the calling convention
export extern void LLVMSetFunctionCallConv(void* function, uint convention);

## Adds an attribute to a function, its result (index 0), or a parameter
## (index 1 and up); `0xFFFFFFFF` is the function itself.
##
## @param function the function
## @param index where the attribute goes
## @param attribute the attribute
export extern void LLVMAddAttributeAtIndex(void* function, uint index, void* attribute);

## Returns a global's linkage (`LLVMLinkage`).
##
## @param global the global
## @returns the linkage
export extern int LLVMGetLinkage(void* global);

## Sets a global's linkage (`LLVMLinkage`).
##
## @param global the global
## @param linkage the linkage
export extern void LLVMSetLinkage(void* global, int linkage);

## Sets a global variable's initial value.
##
## @param global the global variable
## @param value the constant
export extern void LLVMSetInitializer(void* global, void* value);

## Marks a global variable constant.
##
## @param global the global variable
## @param constant nonzero for constant
export extern void LLVMSetGlobalConstant(void* global, int constant);

# Constants

## Returns an integer constant.
##
## @param llvm_type the integer type
## @param value the bits
## @param sign_extend nonzero to sign-extend `value` to the type's width
## @returns the constant
export extern void* LLVMConstInt(void* llvm_type, ulong value, int sign_extend);

## Returns a floating-point constant.
##
## @param llvm_type the floating-point type
## @param value the value
## @returns the constant
export extern void* LLVMConstReal(void* llvm_type, double value);

## Returns the zero value of a type.
##
## @param llvm_type the type
## @returns the constant
export extern void* LLVMConstNull(void* llvm_type);

## Returns the undefined value of a type.
##
## @param llvm_type the type
## @returns the constant
export extern void* LLVMGetUndef(void* llvm_type);

## Returns the poison value of a type.
##
## @param llvm_type the type
## @returns the constant
export extern void* LLVMGetPoison(void* llvm_type);

## Returns a byte-array constant.
##
## @param context the context
## @param text the bytes
## @param length the number of bytes
## @param no_terminator nonzero to leave out the trailing NUL
## @returns the constant
export extern void* LLVMConstStringInContext(void* context, char* text, uint length, int no_terminator);

## Returns a literal struct constant.
##
## @param context the context
## @param values the field values
## @param count the number of fields
## @param packed nonzero for no padding
## @returns the constant
export extern void* LLVMConstStructInContext(void* context, void** values, uint count, int packed);

## Returns a constant of a named struct type.
##
## @param llvm_type the struct type
## @param values the field values
## @param count the number of fields
## @returns the constant
export extern void* LLVMConstNamedStruct(void* llvm_type, void** values, uint count);

## Returns an array constant.
##
## @param element the element type
## @param values the elements
## @param count the number of elements
## @returns the constant
export extern void* LLVMConstArray2(void* element, void** values, ulong count);

# Basic blocks

## Appends a basic block to a function.
##
## @param context the context
## @param function the function
## @param name the block's name
## @returns the block
export extern void* LLVMAppendBasicBlockInContext(void* context, void* function, char* name);

## Returns the function a block belongs to.
##
## @param block the block
## @returns the function
export extern void* LLVMGetBasicBlockParent(void* block);

## Returns a block's terminator instruction, or null.
##
## @param block the block
## @returns the terminator, or null
export extern void* LLVMGetBasicBlockTerminator(void* block);

## Returns a block's name; the block owns the string.
##
## @param block the block
## @returns the name
export extern char* LLVMGetBasicBlockName(void* block);

## Adds incoming edges to a phi node.
##
## @param phi the phi node
## @param values the incoming values
## @param blocks the blocks they come from
## @param count the number of edges
export extern void LLVMAddIncoming(void* phi, void** values, void** blocks, uint count);

## Adds a case to a switch.
##
## @param switch_instruction the switch
## @param on the case's value
## @param destination the block to branch to
export extern void LLVMAddCase(void* switch_instruction, void* on, void* destination);

# The instruction builder

## Creates an instruction builder.
##
## @param context the context
## @returns the builder
export extern void* LLVMCreateBuilderInContext(void* context);

## Destroys a builder.
##
## @param builder the builder
export extern void LLVMDisposeBuilder(void* builder);

## Moves the builder to the end of a block.
##
## @param builder the builder
## @param block the block
export extern void LLVMPositionBuilderAtEnd(void* builder, void* block);

## Returns the block the builder inserts into, or null.
##
## @param builder the builder
## @returns the block, or null
export extern void* LLVMGetInsertBlock(void* builder);

## Builds `ret void`.
##
## @param builder the builder
## @returns the instruction
export extern void* LLVMBuildRetVoid(void* builder);

## Builds `ret value`.
##
## @param builder the builder
## @param value the value to return
## @returns the instruction
export extern void* LLVMBuildRet(void* builder, void* value);

## Builds an unconditional branch.
##
## @param builder the builder
## @param destination the block to branch to
## @returns the instruction
export extern void* LLVMBuildBr(void* builder, void* destination);

## Builds a conditional branch.
##
## @param builder the builder
## @param condition the `i1` condition
## @param then_block the block when true
## @param else_block the block when false
## @returns the instruction
export extern void* LLVMBuildCondBr(void* builder, void* condition, void* then_block, void* else_block);

## Builds a switch; add cases with `LLVMAddCase`.
##
## @param builder the builder
## @param value the value switched on
## @param otherwise the default block
## @param count the expected number of cases
## @returns the instruction
export extern void* LLVMBuildSwitch(void* builder, void* value, void* otherwise, uint count);

## Builds `unreachable`.
##
## @param builder the builder
## @returns the instruction
export extern void* LLVMBuildUnreachable(void* builder);

## Builds a binary operation (`LLVMOpcode`).
##
## @param builder the builder
## @param opcode the operation
## @param left the left operand
## @param right the right operand
## @param name the result's name
## @returns the instruction
export extern void* LLVMBuildBinOp(void* builder, int opcode, void* left, void* right, char* name);

## Builds `add nsw`.
##
## @param builder the builder
## @param left the left operand
## @param right the right operand
## @param name the result's name
## @returns the instruction
export extern void* LLVMBuildNSWAdd(void* builder, void* left, void* right, char* name);

## Builds `sub nsw`.
##
## @param builder the builder
## @param left the left operand
## @param right the right operand
## @param name the result's name
## @returns the instruction
export extern void* LLVMBuildNSWSub(void* builder, void* left, void* right, char* name);

## Builds `mul nsw`.
##
## @param builder the builder
## @param left the left operand
## @param right the right operand
## @param name the result's name
## @returns the instruction
export extern void* LLVMBuildNSWMul(void* builder, void* left, void* right, char* name);

## Builds an integer negation.
##
## @param builder the builder
## @param value the operand
## @param name the result's name
## @returns the instruction
export extern void* LLVMBuildNeg(void* builder, void* value, char* name);

## Builds a floating-point negation.
##
## @param builder the builder
## @param value the operand
## @param name the result's name
## @returns the instruction
export extern void* LLVMBuildFNeg(void* builder, void* value, char* name);

## Builds a bitwise not.
##
## @param builder the builder
## @param value the operand
## @param name the result's name
## @returns the instruction
export extern void* LLVMBuildNot(void* builder, void* value, char* name);

## Builds an integer comparison (`LLVMIntPredicate`).
##
## @param builder the builder
## @param predicate the comparison
## @param left the left operand
## @param right the right operand
## @param name the result's name
## @returns the instruction
export extern void* LLVMBuildICmp(void* builder, int predicate, void* left, void* right, char* name);

## Builds a floating-point comparison (`LLVMRealPredicate`).
##
## @param builder the builder
## @param predicate the comparison
## @param left the left operand
## @param right the right operand
## @param name the result's name
## @returns the instruction
export extern void* LLVMBuildFCmp(void* builder, int predicate, void* left, void* right, char* name);

## Builds a cast (`LLVMOpcode`).
##
## @param builder the builder
## @param opcode the cast
## @param value the operand
## @param llvm_type the type cast to
## @param name the result's name
## @returns the instruction
export extern void* LLVMBuildCast(void* builder, int opcode, void* value, void* llvm_type, char* name);

## Builds `alloca`.
##
## @param builder the builder
## @param llvm_type the allocated type
## @param name the result's name
## @returns the instruction
export extern void* LLVMBuildAlloca(void* builder, void* llvm_type, char* name);

## Builds `load`.
##
## @param builder the builder
## @param llvm_type the loaded type
## @param pointer the address
## @param name the result's name
## @returns the instruction
export extern void* LLVMBuildLoad2(void* builder, void* llvm_type, void* pointer, char* name);

## Builds `store`.
##
## @param builder the builder
## @param value the value to store
## @param pointer the address
## @returns the instruction
export extern void* LLVMBuildStore(void* builder, void* value, void* pointer);

## Builds `getelementptr`.
##
## @param builder the builder
## @param llvm_type the source element type
## @param pointer the base address
## @param indices the indices
## @param count the number of indices
## @param name the result's name
## @returns the instruction
export extern void* LLVMBuildGEP2(
    void* builder, void* llvm_type, void* pointer, void** indices, uint count, char* name
);

## Builds `getelementptr inbounds`.
##
## @param builder the builder
## @param llvm_type the source element type
## @param pointer the base address
## @param indices the indices
## @param count the number of indices
## @param name the result's name
## @returns the instruction
export extern void* LLVMBuildInBoundsGEP2(
    void* builder, void* llvm_type, void* pointer, void** indices, uint count, char* name
);

## Builds the address of a struct field.
##
## @param builder the builder
## @param llvm_type the struct type
## @param pointer the struct's address
## @param index the field's position
## @param name the result's name
## @returns the instruction
export extern void* LLVMBuildStructGEP2(void* builder, void* llvm_type, void* pointer, uint index, char* name);

## Builds `call`.
##
## @param builder the builder
## @param llvm_type the callee's function type
## @param function the callee
## @param arguments the arguments
## @param count the number of arguments
## @param name the result's name; empty for a `void` call
## @returns the instruction
export extern void* LLVMBuildCall2(
    void* builder, void* llvm_type, void* function, void** arguments, uint count, char* name
);

## Builds an empty `phi`; add edges with `LLVMAddIncoming`.
##
## @param builder the builder
## @param llvm_type the value's type
## @param name the result's name
## @returns the instruction
export extern void* LLVMBuildPhi(void* builder, void* llvm_type, char* name);

## Builds `select`.
##
## @param builder the builder
## @param condition the `i1` condition
## @param then_value the value when true
## @param else_value the value when false
## @param name the result's name
## @returns the instruction
export extern void* LLVMBuildSelect(void* builder, void* condition, void* then_value, void* else_value, char* name);

## Builds `extractvalue`.
##
## @param builder the builder
## @param aggregate the struct or array value
## @param index the element's position
## @param name the result's name
## @returns the instruction
export extern void* LLVMBuildExtractValue(void* builder, void* aggregate, uint index, char* name);

## Builds `insertvalue`.
##
## @param builder the builder
## @param aggregate the struct or array value
## @param element the new element
## @param index the element's position
## @param name the result's name
## @returns the instruction
export extern void* LLVMBuildInsertValue(void* builder, void* aggregate, void* element, uint index, char* name);

## Builds a private global holding a NUL-terminated string and returns its
## address.
##
## @param builder the builder
## @param text the string
## @param name the global's name
## @returns the global
export extern void* LLVMBuildGlobalString(void* builder, char* text, char* name);
