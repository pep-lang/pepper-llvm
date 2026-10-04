## `Module`: a unit of LLVM IR (functions and globals) that is verified,
## optimized and compiled to an object file.

import "context";
import "llvm_c" as llvm_c;
import "support";
import "target";
import "values";

## An LLVM module (`LLVMModuleRef`): the functions and global variables of
## one compilation unit. It is disposed when the last reference to it goes
## away, before the `Context` it holds.
##
## @example
##     var context = llvm.Context();
##     var module = llvm.Module(context, "main");
##     var i32 = context.int32_type();
##     var answer = module.add_function("answer", llvm.Type.function(i32, Array<llvm.Type>()));
export struct Module {
    var _handle: Handle<__ptr<void>>;
    ## The context the module's types and constants belong to.
    var context: Context { get; }

    ## Creates an empty module.
    ##
    ## @param context the context its types and constants belong to
    ## @param name the module's identifier
    construct(context: Context, name: String) {
        this.context = context;
        _handle = Handle<__ptr<void>>(
            llvm_c.LLVMModuleCreateWithNameInContext(_c_string(name), context.ref),
            (module) => llvm_c.LLVMDisposeModule(module)
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

    ## Reports whether this wrapper still owns the module: false after it
    ## was given to a `Jit`, which then owns it.
    ##
    ## @returns true while the module can be used
    is_owned(): bool {
        return _handle.is_owned();
    }

    ## Returns the module's target triple, or "" when none is set.
    ##
    ## @returns the triple
    target_triple(): String {
        return _copy_string(llvm_c.LLVMGetTarget(ref));
    }

    ## Sets the module's target triple, such as `x86_64-pc-linux-gnu`.
    ## `TargetMachine.configure` sets it and the data layout together.
    ##
    ## @param triple the triple
    set_target_triple(triple: String) {
        llvm_c.LLVMSetTarget(ref, _c_string(triple));
    }

    ## Returns the module's data layout string, or "" when none is set.
    ##
    ## @returns the data layout
    data_layout(): String {
        return _copy_string(llvm_c.LLVMGetDataLayoutStr(ref));
    }

    ## Sets the module's data layout string.
    ##
    ## @param layout the data layout
    set_data_layout(layout: String) {
        llvm_c.LLVMSetDataLayout(ref, _c_string(layout));
    }

    ## Sets the source file name the module records.
    ##
    ## @param name the file name
    set_source_file_name(name: String) {
        llvm_c.LLVMSetSourceFileName(ref, _c_string(name), name.size);
    }

    ## Returns the module as LLVM IR text.
    ##
    ## @returns the IR text
    to_string(): String {
        return _take_message(llvm_c.LLVMPrintModuleToString(ref));
    }

    ## Adds a function, with no body until blocks are appended to it.
    ##
    ## @param name the function's name; LLVM adds a number when it is taken
    ## @param function_type the function's type, from `Type.function`
    ## @returns the function
    add_function(name: String, function_type: Type): Value {
        return Value(llvm_c.LLVMAddFunction(ref, _c_string(name), function_type.ref));
    }

    ## Returns the function named `name`, if there is one.
    ##
    ## @param name the function's name
    ## @returns the function, or None
    function(name: String): Value? {
        var found = llvm_c.LLVMGetNamedFunction(ref, _c_string(name));
        if (found == __null) {
            return Optional<Value>.Empty;
        }
        return Optional<Value>.Value(Value(found));
    }

    ## Adds a global variable, with no initializer until one is set.
    ##
    ## @param value_type the variable's type
    ## @param name the variable's name
    ## @returns the global, whose value is its address
    add_global(value_type: Type, name: String): Value {
        return Value(llvm_c.LLVMAddGlobal(ref, value_type.ref, _c_string(name)));
    }

    ## Returns the global variable named `name`, if there is one.
    ##
    ## @param name the variable's name
    ## @returns the global, or None
    global(name: String): Value? {
        var found = llvm_c.LLVMGetNamedGlobal(ref, _c_string(name));
        if (found == __null) {
            return Optional<Value>.Empty;
        }
        return Optional<Value>.Value(Value(found));
    }

    ## Checks the module for errors, such as a block with no terminator or
    ## an operand of the wrong type.
    ##
    ## @returns Ok when the module is well formed, else an Err with LLVM's description of every problem
    verify(): Result<void> {
        var message = _OutPointer();
        var broken = llvm_c.LLVMVerifyModule(ref, 2, unsafe_cast<__ptr<__ptr<char>>>(message.data()));
        var text = _take_message(message.get() as __ptr<char>);
        if (broken != 0) {
            return Result<void>.err(Error(text.trim()));
        }
        return Result<void>.ok();
    }

    ## Writes the module as LLVM bitcode.
    ##
    ## @param path the file to write
    ## @returns Ok, or an Err when the file could not be written
    write_bitcode(path: String): Result<void> {
        if (llvm_c.LLVMWriteBitcodeToFile(ref, _c_string(path)) != 0) {
            return Result<void>.err(Error($"cannot write bitcode to '{path}'"));
        }
        return Result<void>.ok();
    }

    ## Runs an optimization pipeline over the module, in `opt -passes=`
    ## syntax: `default<O2>` for the standard `-O2` pipeline, or a list of
    ## passes such as `mem2reg,instcombine`. Configure the module for its
    ## target first (`TargetMachine.configure`).
    ##
    ## @param passes the pipeline
    ## @param machine the target machine, whose cost model the passes use
    ## @returns Ok, or an Err when the pipeline does not parse
    run_passes(passes: String, machine: TargetMachine): Result<void> {
        return _run_passes(passes, machine.ref);
    }

    ## Runs an optimization pipeline over the module with no target
    ## machine, as `opt` does without a triple.
    ##
    ## @param passes the pipeline, in `opt -passes=` syntax
    ## @returns Ok, or an Err when the pipeline does not parse
    run_passes(passes: String): Result<void> {
        return _run_passes(passes, __null);
    }

    _run_passes(passes: String, machine: __ptr<void>): Result<void> {
        var options = Handle<__ptr<void>>(
            llvm_c.LLVMCreatePassBuilderOptions(), (options) => llvm_c.LLVMDisposePassBuilderOptions(options)
        );
        var error = llvm_c.LLVMRunPasses(ref, _c_string(passes), machine, options.value);
        if (error != __null) {
            return Result<void>.err(Error(_take_error(error)));
        }
        return Result<void>.ok();
    }
}
