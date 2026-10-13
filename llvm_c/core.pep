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

## Returns the context that owns a module's types.
##
## @param module the module
## @returns the context
export extern void* LLVMGetModuleContext(void* module);

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

## Reads a whole file into a memory buffer.
##
## @param path the file
## @param buffer receives the buffer; free it with `LLVMDisposeMemoryBuffer`
## @param message receives the reason on failure; free it with `LLVMDisposeMessage`
## @returns nonzero on failure
export extern int LLVMCreateMemoryBufferWithContentsOfFile(char* path, void** buffer, char** message);

## Parses bitcode into a module of `context`. The buffer stays the caller's.
##
## @param context the context
## @param buffer the bitcode
## @param module receives the module
## @returns nonzero on failure
export extern int LLVMParseBitcodeInContext2(void* context, void* buffer, void** module);

## Copies a module, in its context.
##
## @param module the module
## @returns the copy
export extern void* LLVMCloneModule(void* module);

## Links `source` into `destination` and disposes of `source`.
##
## @param destination the module linked into
## @param source the module linked in, disposed of
## @returns nonzero when the two do not link
export extern int LLVMLinkModules2(void* destination, void* source);

## Reports whether a function or global variable is only declared.
##
## @param global the function or global variable
## @returns nonzero for a declaration
export extern int LLVMIsDeclaration(void* global);

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
export extern void* LLVMGetInitializer(void* global);
export extern void LLVMDeleteGlobal(void* global);
export extern void LLVMSetSection(void* global, char* section);

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

# Inspecting and editing IR

## Creates a string attribute (`"key"="value"`).
##
## @param context the context that owns the attribute
## @param key the attribute's key
## @param key_length the key's length in bytes
## @param value the attribute's value
## @param value_length the value's length in bytes
## @returns the attribute
export extern void* LLVMCreateStringAttribute(
    void* context, char* key, uint key_length, char* value, uint value_length
);

## Returns the type of a global's value (a function's function type).
##
## @param global the function or global variable
## @returns its value type
export extern void* LLVMGlobalGetValueType(void* global);

## Returns a function type's result type.
##
## @param function_type the function type
## @returns the result type
export extern void* LLVMGetReturnType(void* function_type);

## Returns the number of a function type's parameters.
##
## @param function_type the function type
## @returns the count
export extern uint LLVMCountParamTypes(void* function_type);

## Writes a function type's parameter types to `types`.
##
## @param function_type the function type
## @param types room for `LLVMCountParamTypes` handles
export extern void LLVMGetParamTypes(void* function_type, void** types);

## Returns a struct type's name, or null for a literal struct.
##
## @param struct_type the struct type
## @returns the name, which the type owns
export extern char* LLVMGetStructName(void* struct_type);

## Returns the number of a struct type's fields.
##
## @param struct_type the struct type
## @returns the count
export extern uint LLVMCountStructElementTypes(void* struct_type);

## Returns a struct type's field type.
##
## @param struct_type the struct type
## @param index the field's position
## @returns the field's type
export extern void* LLVMStructGetTypeAtIndex(void* struct_type, uint index);

## Returns whether a struct type has no body yet.
##
## @param struct_type the struct type
## @returns nonzero when it is opaque
export extern int LLVMIsOpaqueStruct(void* struct_type);

## Returns an array's or vector's element type.
##
## @param llvm_type the array, vector or pointer type
## @returns the element type
export extern void* LLVMGetElementType(void* llvm_type);

## Returns an array type's length.
##
## @param array_type the array type
## @returns the length
export extern ulong LLVMGetArrayLength2(void* array_type);

## Returns a vector type's length.
##
## @param vector_type the vector type
## @returns the length
export extern uint LLVMGetVectorSize(void* vector_type);

## Returns whether a value is a constant.
##
## @param value the value
## @returns nonzero when it is constant
export extern int LLVMIsConstant(void* value);

## Returns the value when it is a `ConstantInt`, else null.
##
## @param value the value
## @returns the value or null
export extern void* LLVMIsAConstantInt(void* value);

## Returns the value when it is a `Function`, else null.
##
## @param value the value
## @returns the value or null
export extern void* LLVMIsAFunction(void* value);

## Returns a constant integer zero-extended to 64 bits.
##
## @param value the `ConstantInt`
## @returns its value
export extern ulong LLVMConstIntGetZExtValue(void* value);

## Returns a constant integer sign-extended to 64 bits.
##
## @param value the `ConstantInt`
## @returns its value
export extern long LLVMConstIntGetSExtValue(void* value);

## Returns an integer constant of type `llvm_type` with every bit set.
##
## @param llvm_type the integer type
## @returns the constant
export extern void* LLVMConstAllOnes(void* llvm_type);

## Returns the null pointer of a pointer type.
##
## @param llvm_type the pointer type
## @returns the constant
export extern void* LLVMConstPointerNull(void* llvm_type);

## Returns a function's first basic block, or null.
##
## @param function the function
## @returns the block or null
export extern void* LLVMGetFirstBasicBlock(void* function);

## Returns a function's last basic block, or null.
##
## @param function the function
## @returns the block or null
export extern void* LLVMGetLastBasicBlock(void* function);

## Returns the block after `block` in its function, or null.
##
## @param block the block
## @returns the next block or null
export extern void* LLVMGetNextBasicBlock(void* block);

## Returns the number of a function's basic blocks.
##
## @param function the function
## @returns the count
export extern uint LLVMCountBasicBlocks(void* function);

## Creates a block and inserts it before `before`.
##
## @param context the context
## @param before the block to insert before
## @param name the block's name
## @returns the new block
export extern void* LLVMInsertBasicBlockInContext(void* context, void* before, char* name);

## Moves `block` to just after `after`.
##
## @param block the block to move
## @param after the block to follow
export extern void LLVMMoveBasicBlockAfter(void* block, void* after);

## Returns a block's first instruction, or null.
##
## @param block the block
## @returns the instruction or null
export extern void* LLVMGetFirstInstruction(void* block);

## Returns a block's last instruction, or null.
##
## @param block the block
## @returns the instruction or null
export extern void* LLVMGetLastInstruction(void* block);

## Returns the instruction after `instruction`, or null.
##
## @param instruction the instruction
## @returns the next instruction or null
export extern void* LLVMGetNextInstruction(void* instruction);

## Returns the instruction before `instruction`, or null.
##
## @param instruction the instruction
## @returns the previous instruction or null
export extern void* LLVMGetPreviousInstruction(void* instruction);

## Returns an instruction's opcode (`LLVMOpcode`).
##
## @param instruction the instruction
## @returns the opcode
export extern int LLVMGetInstructionOpcode(void* instruction);

## Returns the block an instruction is in.
##
## @param instruction the instruction
## @returns the block
export extern void* LLVMGetInstructionParent(void* instruction);

## Removes an instruction from its block and deletes it.
##
## @param instruction the instruction
export extern void LLVMInstructionEraseFromParent(void* instruction);

## Returns a module's first function, or null.
##
## @param module the module
## @returns the function or null
export extern void* LLVMGetFirstFunction(void* module);

## Returns the function after `function` in its module, or null.
##
## @param function the function
## @returns the next function or null
export extern void* LLVMGetNextFunction(void* function);

## Returns a module's first global variable, or null.
##
## @param module the module
## @returns the global or null
export extern void* LLVMGetFirstGlobal(void* module);

## Returns the global variable after `global`, or null.
##
## @param global the global
## @returns the next global or null
export extern void* LLVMGetNextGlobal(void* global);

## Deletes a function from its module.
##
## @param function the function
export extern void LLVMDeleteFunction(void* function);

## Removes a basic block from its function and deletes it.
##
## @param block the block
export extern void LLVMDeleteBasicBlock(void* block);

## Sets (or, given null, clears) a function's personality function.
##
## @param function the function
## @param personality the personality function
export extern void LLVMSetPersonalityFn(void* function, void* personality);

## Reports whether a function has a personality function.
##
## @param function the function
## @returns nonzero when it has one
export extern int LLVMHasPersonalityFn(void* function);

## Returns the module a function or global variable belongs to.
##
## @param global the function or global variable
## @returns the module
export extern void* LLVMGetGlobalParent(void* global);

## Returns the module's comdat of this name, adding it when it has none.
##
## @param module the module
## @param name the comdat's name
## @returns the comdat
export extern void* LLVMGetOrInsertComdat(void* module, char* name);

## Returns the comdat a function or global variable is in, or null.
##
## @param global the function or global variable
## @returns the comdat or null
export extern void* LLVMGetComdat(void* global);

## Puts a function or global variable in a comdat.
##
## @param global the function or global variable
## @param comdat the comdat
export extern void LLVMSetComdat(void* global, void* comdat);

## Sets a global value's visibility (`LLVMVisibility`).
##
## @param global the function or global variable
## @param visibility 0 default, 1 hidden, 2 protected
export extern void LLVMSetVisibility(void* global, int visibility);

## Returns a value's first use, or null when nothing uses it.
##
## @param value the value
## @returns the use or null
export extern void* LLVMGetFirstUse(void* value);

## Makes every use of `old` a use of `replacement`, of the same type.
##
## @param old the value whose uses change
## @param replacement the value they use instead
export extern void LLVMReplaceAllUsesWith(void* old, void* replacement);

## Sets whether a global's address is significant (`LLVMUnnamedAddr`).
##
## @param global the global
## @param unnamed 0 for none, 1 for `local_unnamed_addr`, 2 for `unnamed_addr`
export extern void LLVMSetUnnamedAddress(void* global, int unnamed);

## Returns whether a global's address is significant (`LLVMUnnamedAddr`).
##
## @param global the function or global variable
## @returns 0 for none, 1 for `local_unnamed_addr`, 2 for `unnamed_addr`
export extern int LLVMGetUnnamedAddress(void* global);

## Sets a global variable's `thread_local` mode (`LLVMThreadLocalMode`).
##
## @param global the global
## @param mode the mode; 0 for not thread-local
export extern void LLVMSetThreadLocalMode(void* global, int mode);

## Sets a global's, alloca's, load's or store's alignment.
##
## @param value the value
## @param bytes the alignment
export extern void LLVMSetAlignment(void* value, uint bytes);

## Sets an instruction's metadata of kind `kind`.
##
## @param instruction the instruction
## @param kind the kind, from `LLVMGetMDKindIDInContext`
## @param node the metadata, as a value
export extern void LLVMSetMetadata(void* instruction, uint kind, void* node);

## Returns the kind of metadata named `name` (`tbaa`).
##
## @param context the context
## @param name the name
## @param length the name's length in bytes
## @returns the kind
export extern uint LLVMGetMDKindIDInContext(void* context, char* name, uint length);

## Returns a metadata string.
##
## @param context the context
## @param text the string
## @param length its length in bytes
## @returns the metadata
export extern void* LLVMMDStringInContext2(void* context, char* text, ulong length);

## Returns a metadata tuple of `count` operands.
##
## @param context the context
## @param operands the operands
## @param count how many
## @returns the metadata
export extern void* LLVMMDNodeInContext2(void* context, void** operands, ulong count);

## Wraps metadata as a value.
##
## @param context the context
## @param metadata the metadata
## @returns the value
export extern void* LLVMMetadataAsValue(void* context, void* metadata);

## Wraps a constant as metadata.
##
## @param value the constant
## @returns the metadata
export extern void* LLVMValueAsMetadata(void* value);

## Returns the ID of the intrinsic named `name` (`llvm.trap`), or 0.
##
## @param name the name
## @param length its length in bytes
## @returns the ID
export extern uint LLVMLookupIntrinsicID(char* name, ulong length);

## Declares (or finds) an intrinsic in a module, overloaded on `types`.
##
## @param module the module
## @param id the intrinsic's ID
## @param types the overload's types
## @param count how many
## @returns the function
export extern void* LLVMGetIntrinsicDeclaration(void* module, uint id, void** types, ulong count);

## Returns an intrinsic's function type for the overload on `types`.
##
## @param context the context
## @param id the intrinsic's ID
## @param types the overload's types
## @param count how many
## @returns the function type
export extern void* LLVMIntrinsicGetType(void* context, uint id, void** types, ulong count);

## Moves the builder to just before `instruction`.
##
## @param builder the builder
## @param instruction the instruction
export extern void LLVMPositionBuilderBefore(void* builder, void* instruction);

## Adds an attribute to a call instruction (index as for `LLVMAddAttributeAtIndex`).
##
## @param call the call
## @param index the attribute index
## @param attribute the attribute
export extern void LLVMAddCallSiteAttribute(void* call, uint index, void* attribute);

## Marks a load or store volatile, or not.
##
## @param instruction the load or store
## @param volatile nonzero for volatile
export extern void LLVMSetVolatile(void* instruction, int volatile);

## Builds `atomicrmw`.
##
## @param builder the builder
## @param op the operation (`LLVMAtomicRMWBinOp`)
## @param pointer the address
## @param value the operand
## @param ordering the ordering (`LLVMAtomicOrdering`)
## @param single_thread nonzero for single-thread scope
## @returns the old value
export extern void* LLVMBuildAtomicRMW(
    void* builder, int op, void* pointer, void* value, int ordering, int single_thread
);

## Builds `cmpxchg`.
##
## @param builder the builder
## @param pointer the address
## @param expected the value expected there
## @param replacement the value to store
## @param success the ordering on success
## @param failure the ordering on failure
## @param single_thread nonzero for single-thread scope
## @returns the `{ old, succeeded }` pair
export extern void* LLVMBuildAtomicCmpXchg(
    void* builder, void* pointer, void* expected, void* replacement, int success, int failure, int single_thread
);

## Sets an atomic load's or store's ordering.
##
## @param instruction the load or store
## @param ordering the ordering (`LLVMAtomicOrdering`)
export extern void LLVMSetOrdering(void* instruction, int ordering);

## Builds `llvm.memcpy`.
##
## @param builder the builder
## @param destination the destination
## @param destination_align its alignment
## @param source the source
## @param source_align its alignment
## @param size the byte count
## @returns the call
export extern void* LLVMBuildMemCpy(
    void* builder, void* destination, uint destination_align, void* source, uint source_align, void* size
);

## Builds `llvm.memmove`.
##
## @param builder the builder
## @param destination the destination
## @param destination_align its alignment
## @param source the source
## @param source_align its alignment
## @param size the byte count
## @returns the call
export extern void* LLVMBuildMemMove(
    void* builder, void* destination, uint destination_align, void* source, uint source_align, void* size
);

## Builds `llvm.memset`.
##
## @param builder the builder
## @param pointer the destination
## @param value the byte
## @param length the byte count
## @param align the destination's alignment
## @returns the call
export extern void* LLVMBuildMemSet(void* builder, void* pointer, void* value, void* length, uint align);

## Builds `extractelement`.
##
## @param builder the builder
## @param vector the vector
## @param index the lane
## @param name the result's name
## @returns the lane's value
export extern void* LLVMBuildExtractElement(void* builder, void* vector, void* index, char* name);

## Builds `insertelement`.
##
## @param builder the builder
## @param vector the vector
## @param element the new lane value
## @param index the lane
## @param name the result's name
## @returns the new vector
export extern void* LLVMBuildInsertElement(void* builder, void* vector, void* element, void* index, char* name);

## Builds `shufflevector`.
##
## @param builder the builder
## @param left the first vector
## @param right the second vector
## @param mask the constant lane mask
## @param name the result's name
## @returns the new vector
export extern void* LLVMBuildShuffleVector(void* builder, void* left, void* right, void* mask, char* name);

## Builds `fence`.
##
## @param builder the builder
## @param ordering the ordering
## @param single_thread nonzero for single-thread scope
## @param name the result's name
## @returns the instruction
export extern void* LLVMBuildFence(void* builder, int ordering, int single_thread, char* name);

## Returns the size of a type as a constant `i64`.
##
## @param llvm_type the type
## @returns the size
export extern void* LLVMSizeOf(void* llvm_type);

## Returns a constant vector.
##
## @param values the lanes
## @param count how many
## @returns the vector
export extern void* LLVMConstVector(void** values, uint count);

## Returns whether an intrinsic takes types to name a declaration.
##
## @param id the intrinsic's ID
## @returns nonzero when overloaded
export extern int LLVMIntrinsicIsOverloaded(uint id);

## Returns the name of an overloaded intrinsic for `types`; free it with
## `LLVMDisposeMessage`.
##
## @param module the module
## @param id the intrinsic's ID
## @param types the overload's types
## @param count how many
## @param length receives the name's length
## @returns the name
export extern char* LLVMIntrinsicCopyOverloadedName2(void* module, uint id, void** types, ulong count, ulong* length);

## Returns a function's intrinsic ID, or 0.
##
## @param function the function
## @returns the ID
export extern uint LLVMGetIntrinsicID(void* function);

## Returns an inline assembly value.
##
## @param llvm_type the function type
## @param assembly the assembly text
## @param assembly_length its length
## @param constraints the constraints
## @param constraints_length their length
## @param side_effects nonzero when it has side effects
## @param align_stack nonzero to align the stack
## @param dialect 0 for AT&T, 1 for Intel
## @param can_throw nonzero when it may unwind
## @returns the value
export extern void* LLVMGetInlineAsm(
    void* llvm_type,
    char* assembly,
    ulong assembly_length,
    char* constraints,
    ulong constraints_length,
    int side_effects,
    int align_stack,
    int dialect,
    int can_throw
);

## Builds a test that a pointer is null.
##
## @param builder the builder
## @param value the pointer
## @param name the result's name
## @returns an `i1`
export extern void* LLVMBuildIsNull(void* builder, void* value, char* name);

## Builds a test that a pointer is not null.
##
## @param builder the builder
## @param value the pointer
## @param name the result's name
## @returns an `i1`
export extern void* LLVMBuildIsNotNull(void* builder, void* value, char* name);

## Builds a signed integer cast: a truncation, sign extension or nothing.
##
## @param builder the builder
## @param value the integer
## @param llvm_type the integer type to convert to
## @param name the result's name
## @returns the result
export extern void* LLVMBuildIntCast(void* builder, void* value, void* llvm_type, char* name);

## Returns whether a function type takes variadic arguments.
##
## @param function_type the type
## @returns nonzero when variadic
export extern int LLVMIsFunctionVarArg(void* function_type);

## Returns a constant integer converted to a pointer.
##
## @param value the constant
## @param llvm_type the pointer type
## @returns the constant
export extern void* LLVMConstIntToPtr(void* value, void* llvm_type);

## Returns a constant `getelementptr`.
##
## @param llvm_type the type the indices step through
## @param value the base constant
## @param indices the indices
## @param count how many
## @returns the constant
export extern void* LLVMConstGEP2(void* llvm_type, void* value, void** indices, uint count);

## Returns an operand of a user.
##
## @param value the user
## @param index the operand's position
## @returns the operand
export extern void* LLVMGetOperand(void* value, uint index);

## Returns how many operands a user has.
##
## @param value the user
## @returns the count
export extern int LLVMGetNumOperands(void* value);

## Returns `value` when it is an instruction, else null.
##
## @param value the value
## @returns the value or null
export extern void* LLVMIsAInstruction(void* value);

## Returns the source element type of a `getelementptr`.
##
## @param value the instruction
## @returns the type
export extern void* LLVMGetGEPSourceElementType(void* value);

## Returns an enum attribute at a position, or null.
##
## @param function the function
## @param index the position (0 the return value, then 1 per parameter, -1 the function)
## @param kind the attribute kind
## @returns the attribute or null
export extern void* LLVMGetEnumAttributeAtIndex(void* function, uint index, uint kind);

## Sets a global's DLL storage class (0 default, 1 import, 2 export).
##
## @param global the global
## @param class the class
export extern void LLVMSetDLLStorageClass(void* global, int class);
