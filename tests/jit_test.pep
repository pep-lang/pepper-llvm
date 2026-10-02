# Compiles functions in memory with the JIT and calls them.

import llvm;

main(): int {
    var jit = llvm.Jit.create().value();
    if (jit.triple().size == 0 || jit.data_layout().size == 0) {
        return 1;
    }

    var context = llvm.Context(thread_safe = true);
    if (!context.is_thread_safe()) {
        return 2;
    }
    var module = llvm.Module(context, "jitted");
    var i32 = context.int32_type();
    var i64 = context.int64_type();
    var builder = llvm.Builder(context);

    # int add(int a, int b) { return a + b; }
    var add = module.add_function("add", llvm.Type.function(i32, [i32, i32]));
    builder.position_at_end(context.append_block(add, "entry"));
    builder.return_value(builder.add(add.param(0), add.param(1), "sum"));

    # long length(char* s) { return strlen(s); }: calls the program's C library.
    var pointer = context.pointer_type();
    var strlen_type = llvm.Type.function(i64, [pointer]);
    var strlen = module.add_function("strlen", strlen_type);
    var length = module.add_function("length", strlen_type);
    builder.position_at_end(context.append_block(length, "entry"));
    builder.return_value(builder.call(strlen_type, strlen, [length.param(0)], "n"));

    if (!module.verify().is_ok()) {
        return 3;
    }
    if (!jit.add_module(module).is_ok() || module.is_owned()) {
        return 4;
    }

    var add_function = jit.lookup("add").value() as extern (int, int) => int;
    if (add_function(2, 3) != 5) {
        return 5;
    }
    var length_function = jit.lookup("length").value() as extern (__ptr<char>) => long;
    var text = "hello";
    var got = length_function(text.c_str());
    if (got != 5) {
        print($"length: {got}");
        return 6;
    }
    if (jit.lookup("missing").is_ok()) {
        return 7;
    }

    # A module from a plain context is refused, not a crash.
    var plain = llvm.Context();
    var refused = jit.add_module(llvm.Module(plain, "plain"));
    if (refused.is_ok() || !refused.error().message.contains("thread_safe")) {
        return 8;
    }

    # A second module can call the first one's function.
    var second = llvm.Module(context, "second");
    var add_declaration = second.add_function("add", llvm.Type.function(i32, [i32, i32]));
    var triple = second.add_function("triple", llvm.Type.function(i32, [i32]));
    var second_builder = llvm.Builder(context);
    second_builder.position_at_end(context.append_block(triple, "entry"));
    var doubled = second_builder.call(
        llvm.Type.function(i32, [i32, i32]), add_declaration, [triple.param(0), triple.param(0)], "doubled"
    );
    second_builder.return_value(
        second_builder.call(llvm.Type.function(i32, [i32, i32]), add_declaration, [doubled, triple.param(0)], "tripled")
    );
    jit.add_module(second).value();
    var triple_function = jit.lookup("triple").value() as extern (int) => int;
    if (triple_function(14) != 42) {
        return 9;
    }
    return 0;
}
