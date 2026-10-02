## Bindings to LLVM for building IR and compiling it to object files, in
## Pepper types that free what they own.
##
## A `Context` owns types and constants; a `Module` holds functions and
## globals; a `Builder` appends instructions to a function's blocks; a
## `TargetMachine` optimizes a module and compiles it to an object file.
## Those four free their LLVM object when the last reference goes away
## (each holds a `Handle`). `Type`, `Value`, `BasicBlock` and `Attribute`
## are plain handles, valid while their context and module are alive.
##
## For what the wrappers do not cover, the `llvm_c` module declares the C
## functions themselves; every wrapper exposes its LLVM-C handle as `ref`.
##
## @example
##     import llvm;
##
##     main(): int {
##         var context = llvm.Context();
##         var module = llvm.Module(context, "demo");
##         var i32 = context.int32_type();
##         var add = module.add_function("add", llvm.Type.function(i32, [i32, i32]));
##         var builder = llvm.Builder(context);
##         builder.position_at_end(context.append_block(add, "entry"));
##         builder.return_value(builder.add(add.param(0), add.param(1), "sum"));
##         module.verify().value();
##
##         var machine = llvm.TargetMachine.host().value();
##         machine.configure(module);
##         machine.emit_to_file(module, "demo.o").value();
##         return 0;
##     }

export * from "enums";
export * from "values";
export * from "context";
export * from "ir_module";
export * from "builder";
export * from "target";
