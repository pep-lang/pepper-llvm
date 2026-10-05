## The LLVM-C enumerations the wrappers take and return, with LLVM's values.

## What kind of type a `Type` is (`LLVMTypeKind`).
export enum TypeKind {
    ## `void`.
    Void = 0,
    ## 16-bit floating point.
    Half = 1,
    ## 32-bit floating point.
    Float = 2,
    ## 64-bit floating point.
    Double = 3,
    ## 80-bit x87 floating point.
    X86Fp80 = 4,
    ## 128-bit floating point.
    Fp128 = 5,
    ## PowerPC's pair-of-doubles floating point.
    PpcFp128 = 6,
    ## A basic block label.
    Label = 7,
    ## An integer of any width.
    Integer = 8,
    ## A function type.
    Function = 9,
    ## A struct.
    Struct = 10,
    ## An array.
    Array = 11,
    ## A pointer.
    Pointer = 12,
    ## A fixed-width SIMD vector.
    Vector = 13,
    ## Metadata.
    Metadata = 14,
    ## A token.
    Token = 16,
    ## A scalable SIMD vector.
    ScalableVector = 17,
    ## 16-bit brain floating point.
    BFloat = 18,
    ## An x86 AMX tile.
    X86Amx = 19,
    ## A target extension type.
    TargetExtension = 20,
}

## An integer comparison (`LLVMIntPredicate`).
export enum IntPredicate {
    ## Equal.
    Equal = 32,
    ## Not equal.
    NotEqual = 33,
    ## Unsigned greater than.
    UnsignedGreater = 34,
    ## Unsigned greater than or equal.
    UnsignedGreaterOrEqual = 35,
    ## Unsigned less than.
    UnsignedLess = 36,
    ## Unsigned less than or equal.
    UnsignedLessOrEqual = 37,
    ## Signed greater than.
    SignedGreater = 38,
    ## Signed greater than or equal.
    SignedGreaterOrEqual = 39,
    ## Signed less than.
    SignedLess = 40,
    ## Signed less than or equal.
    SignedLessOrEqual = 41,
}

## A floating-point comparison (`LLVMRealPredicate`). Ordered comparisons
## are false when either operand is NaN; unordered ones are true.
export enum RealPredicate {
    ## Always false.
    False = 0,
    ## Ordered and equal.
    OrderedEqual = 1,
    ## Ordered and greater than.
    OrderedGreater = 2,
    ## Ordered and greater than or equal.
    OrderedGreaterOrEqual = 3,
    ## Ordered and less than.
    OrderedLess = 4,
    ## Ordered and less than or equal.
    OrderedLessOrEqual = 5,
    ## Ordered and not equal.
    OrderedNotEqual = 6,
    ## Neither operand is NaN.
    Ordered = 7,
    ## Either operand is NaN.
    Unordered = 8,
    ## Unordered or equal.
    UnorderedEqual = 9,
    ## Unordered or greater than.
    UnorderedGreater = 10,
    ## Unordered or greater than or equal.
    UnorderedGreaterOrEqual = 11,
    ## Unordered or less than.
    UnorderedLess = 12,
    ## Unordered or less than or equal.
    UnorderedLessOrEqual = 13,
    ## Unordered or not equal.
    UnorderedNotEqual = 14,
    ## Always true.
    True = 15,
}

## Who a linked symbol is visible to (`LLVMVisibility`).
export enum Visibility {
    ## Every object and shared library.
    Default = 0,
    ## Only the objects linked into the same executable or library.
    Hidden = 1,
    ## Every object, but always bound to this definition.
    Protected = 2,
}

## How a global is linked (`LLVMLinkage`).
export enum Linkage {
    ## Visible to other objects.
    External = 0,
    ## Defined elsewhere; this copy may be inlined but is not emitted.
    AvailableExternally = 1,
    ## Merged with other copies of the same name when linking.
    LinkOnceAny = 2,
    ## Like `LinkOnceAny`, and every copy is equivalent.
    LinkOnceOdr = 3,
    ## Weak: kept unless a strong definition exists.
    WeakAny = 5,
    ## Like `WeakAny`, and every copy is equivalent.
    WeakOdr = 6,
    ## Appended to arrays of the same name when linking.
    Appending = 7,
    ## Local to the object, like C's `static`.
    Internal = 8,
    ## Like `Internal`, and left out of the symbol table.
    Private = 9,
    ## A weak reference to a definition elsewhere.
    ExternalWeak = 12,
    ## A tentative definition, like C's uninitialized globals.
    Common = 14,
}

## A function's calling convention (`LLVMCallConv`).
export enum CallConvention {
    ## The C calling convention.
    C = 0,
    ## A fast convention LLVM may choose freely.
    Fast = 8,
    ## For rarely called functions.
    Cold = 9,
}

## How hard code generation optimizes (`LLVMCodeGenOptLevel`).
export enum OptLevel {
    ## No optimization (`-O0`).
    O0 = 0,
    ## Light optimization (`-O1`).
    O1 = 1,
    ## The default (`-O2`).
    O2 = 2,
    ## Aggressive optimization (`-O3`).
    O3 = 3,
}

## How code addresses itself (`LLVMRelocMode`).
export enum RelocMode {
    ## The target's default.
    Default = 0,
    ## Fixed addresses.
    Static = 1,
    ## Position-independent code, for shared libraries and PIE executables.
    Pic = 2,
    ## Position-dependent code that may call position-independent code.
    DynamicNoPic = 3,
}

## Which addresses code may reach directly (`LLVMCodeModel`).
export enum CodeModel {
    ## The target's default.
    Default = 0,
    ## The default for JIT compilation.
    JitDefault = 1,
    ## Everything within a few megabytes.
    Tiny = 2,
    ## Code and data in the low 2 GB.
    Small = 3,
    ## For operating system kernels.
    Kernel = 4,
    ## Code in the low 2 GB, data anywhere.
    Medium = 5,
    ## Code and data anywhere.
    Large = 6,
}

## What `TargetMachine.emit` writes (`LLVMCodeGenFileType`).
export enum FileKind {
    ## Assembly text.
    Assembly = 0,
    ## An object file.
    Object = 1,
}

## The source language a compile unit records (`LLVMDWARFSourceLanguage`).
## The values are LLVM's enum positions, not DWARF's `DW_LANG_*` codes.
export enum DwarfLanguage {
    ## C89.
    C89 = 0,
    ## C.
    C = 1,
    ## C++.
    CPlusPlus = 3,
    ## C99.
    C99 = 11,
    ## C++11.
    CPlusPlus11 = 25,
    ## Rust.
    Rust = 27,
    ## C11.
    C11 = 28,
    ## Swift.
    Swift = 29,
    ## C++14.
    CPlusPlus14 = 32,
    ## Zig.
    Zig = 38,
    ## C++17.
    CPlusPlus17 = 40,
    ## C++20.
    CPlusPlus20 = 41,
    ## C17.
    C17 = 42,
}

## How much debug info a compile unit emits (`LLVMDWARFEmissionKind`).
export enum DebugEmission {
    ## None.
    None = 0,
    ## Types, variables and line tables, for a debugger.
    Full = 1,
    ## Line tables only, for stack traces and profilers.
    LineTablesOnly = 2,
}

## How a basic type's bits are read (`DW_ATE_*`).
export enum DwarfEncoding: uint {
    ## A boolean.
    Boolean = 2,
    ## A binary floating-point number.
    Float = 4,
    ## A signed integer.
    Signed = 5,
    ## A signed character.
    SignedChar = 6,
    ## An unsigned integer.
    Unsigned = 7,
    ## An unsigned character.
    UnsignedChar = 8,
    ## A Unicode character.
    Utf = 16,
}
