# Tests the llvm module: builds IR, verifies it, optimizes it and compiles
# it to object files for the host and other targets.

import llvm;

# int max(int a, int b) { return a > b ? a : b; } with branches and a phi.
build_max(context: llvm.Context, module: llvm.Module): llvm.Value {
    var i32 = context.int32_type();
    var function = module.add_function("max", llvm.Type.function(i32, [i32, i32]));
    var entry = context.append_block(function, "entry");
    var left = context.append_block(function, "left");
    var right = context.append_block(function, "right");
    var join = context.append_block(function, "join");
    var builder = llvm.Builder(context);
    builder.position_at_end(entry);
    var greater = builder.compare(llvm.IntPredicate.SignedGreater, function.param(0), function.param(1), "greater");
    builder.conditional_branch(greater, left, right);
    builder.position_at_end(left);
    builder.branch(join);
    builder.position_at_end(right);
    builder.branch(join);
    builder.position_at_end(join);
    var result = builder.phi(i32, "result");
    result.add_incoming([function.param(0), function.param(1)], [left, right]);
    builder.return_value(result);
    return function;
}

# A module whose `make` returns a module that outlives the context
# variable it was made from: the module keeps its context alive.
make_module(): llvm.Module {
    var context = llvm.Context();
    var module = llvm.Module(context, "kept");
    var i64 = context.int64_type();
    var function = module.add_function("seven", llvm.Type.function(i64, Array<llvm.Type>()));
    var builder = llvm.Builder(context);
    builder.position_at_end(context.append_block(function, "entry"));
    builder.return_value(i64.const_int(7));
    return module;
}

# Compiles `int seven() { return 7; }` for `triple` and returns the object
# file's first four bytes, or an empty array when LLVM has no `backend`.
cross_compile(backend: String, triple: String): u8[] {
    if (llvm.initialize_target(backend).is_err()) {
        return Array<u8>();
    }
    var context = llvm.Context();
    var module = llvm.Module(context, "cross");
    var i32 = context.int32_type();
    var function = module.add_function("seven", llvm.Type.function(i32, Array<llvm.Type>()));
    var builder = llvm.Builder(context);
    builder.position_at_end(context.append_block(function, "entry"));
    builder.return_value(i32.const_int(7));
    var machine = llvm.TargetMachine.create(triple).value();
    machine.configure(module);
    var object = machine.emit_to_memory(module).value();
    var head = Array<u8>();
    for (var index in 0..4) {
        head.append(object[index]);
    }
    return head;
}

# A module holding `max`, a named struct `Point`, a global `origin` of it,
# and a `main` that stores into the global, calls C's `puts` and calls
# `max`.
build_program(context: llvm.Context): llvm.Module {
    var module = llvm.Module(context, "test");
    var i32 = context.int32_type();
    var max = build_max(context, module);
    var point = context.named_struct_type("Point");
    point.set_body([i32, i32]);
    var origin = module.add_global(point, "origin");
    origin.set_initializer(point.const_struct([i32.const_int(0), i32.const_int(0)]));
    origin.set_linkage(llvm.Linkage.Internal);
    var puts_type = llvm.Type.function(i32, [context.pointer_type()]);
    var puts = module.add_function("puts", puts_type);
    var main_function = module.add_function("main", llvm.Type.function(i32, Array<llvm.Type>()));
    main_function.add_function_attribute(context.attribute("nounwind"));
    var builder = llvm.Builder(context);
    builder.position_at_end(context.append_block(main_function, "entry"));
    var y = builder.field_pointer(point, origin, 1, "y");
    builder.store(i32.const_int(3), y);
    builder.call(puts_type, puts, [builder.global_string("hello", "greeting")]);
    var loaded = builder.load(i32, y, "loaded");
    builder.return_value(
        builder.call(llvm.Type.function(i32, [i32, i32]), max, [loaded, i32.const_int(-1)], "biggest")
    );
    return module;
}

[Test]
types_print_as_ir() {
    var context = llvm.Context();
    var i32 = context.int32_type();
    expect_equal(i32.to_string(), "i32");
    expect_true(i32.kind() == llvm.TypeKind.Integer);
    expect_equal(i32.int_width(), 32 as uint);
    expect_equal(context.struct_type([i32, context.pointer_type()]).to_string(), "{ i32, ptr }");
    expect_equal(llvm.Type.function(context.void_type(), [i32], true).to_string(), "void (i32, ...)");
}

[Test]
a_function_with_a_phi_verifies_and_prints() {
    var context = llvm.Context();
    var module = llvm.Module(context, "test");
    var max = build_max(context, module);
    expect_true(max.verify_function());
    expect_equal(max.param_count(), 2 as uint);
    expect_equal(max.name(), "max");
    expect_true(module.verify().is_ok());
    var text = module.to_string();
    expect_true(text.contains("define i32 @max(i32 %0, i32 %1)"));
    expect_true(text.contains("%result = phi i32"));
    expect_true(module.function("max").is_value());
    expect_true(module.function("missing").is_empty());
}

[Test]
structs_globals_and_calls_verify() {
    var context = llvm.Context();
    var module = build_program(context);
    var checked = module.verify();
    if (checked.is_err()) {
        print(checked.error().message);
        print(module.to_string());
    }
    expect_true(checked.is_ok());
    var text = module.to_string();
    expect_true(text.contains("%Point = type { i32, i32 }"));
    expect_true(text.contains("@greeting = private"));
    expect_true(text.contains("nounwind"));
    expect_true(module.global("origin").value().linkage() == llvm.Linkage.Internal);
}

[Test]
a_block_without_a_terminator_fails_verification() {
    var context = llvm.Context();
    var broken = llvm.Module(context, "broken");
    var bad = broken.add_function("bad", llvm.Type.function(context.void_type(), Array<llvm.Type>()));
    context.append_block(bad, "entry");
    var verified = broken.verify();
    expect_true(verified.is_err());
    expect_true(verified.error().message.contains("terminator"));
}

[Test]
the_host_machine_optimizes_and_emits() {
    var context = llvm.Context();
    var module = build_program(context);
    var i32 = context.int32_type();
    var point = context.struct_type([i32, i32]);
    var machine = llvm.TargetMachine.host(llvm.OptLevel.O2).value();
    machine.configure(module);
    expect_equal(module.target_triple(), machine.triple());
    expect_equal(module.data_layout(), machine.data_layout());
    expect_equal(machine.size_of(point), 8 as ulong);
    expect_equal(machine.alignment_of(i32), 4 as uint);
    expect_equal(machine.offset_of(point, 1), 4 as ulong);
    expect_true(module.run_passes("default<O2>", machine).is_ok());
    expect_true(module.run_passes("no-such-pass").is_err());
    var object = machine.emit_to_memory(module).value();
    expect_true(object.count >= 4);
    # ELF on Linux, Mach-O on macOS, COFF (an x64 or arm64 machine number) on Windows.
    var elf = object[0] == 0x7F && object[1] == 'E' as u8;
    var mach_o = object[0] == 0xCF && object[1] == 0xFA;
    var coff = (object[0] == 0x64 && object[1] == 0x86) || (object[0] == 0x64 && object[1] == 0xAA);
    expect_true(elf || mach_o || coff);
    expect_true(machine.emit_to_memory(module, llvm.FileKind.Assembly).value().count > 0);
}

[Test]
an_unknown_triple_is_an_error() {
    expect_true(llvm.TargetMachine.create("no-such-arch-unknown-none").is_err());
}

[Test]
a_module_keeps_its_context_alive() {
    var kept = make_module();
    expect_true(kept.verify().is_ok());
    expect_true(kept.to_string().contains("ret i64 7"));
}

[Test]
other_backends_compile_for_their_targets() {
    expect_true(llvm.initialize_target("NoSuchBackend").is_err());
    var registered = llvm.initialize_all_targets();
    expect_true(registered.contains("X86") || registered.contains("AArch64"));
    var targets = llvm.registered_targets();
    expect_true(targets.contains("x86-64") || targets.contains("aarch64"));
    # Each is empty when the library lacks the backend.
    var riscv = cross_compile("RISCV", "riscv64-unknown-linux-gnu");
    expect_true(riscv.count == 0 || (riscv[0] == 0x7F && riscv[1] == 'E' as u8));
    var mac = cross_compile("AArch64", "arm64-apple-macosx14.0.0");
    expect_true(mac.count == 0 || (mac[0] == 0xCF && mac[1] == 0xFA));
    var windows = cross_compile("X86", "x86_64-pc-windows-msvc");
    expect_true(windows.count == 0 || (windows[0] == 0x64 && windows[1] == 0x86));
    var wasm = cross_compile("WebAssembly", "wasm32-unknown-unknown");
    expect_true(
        wasm.count == 0 || (wasm[0] == 0 && wasm[1] == 'a' as u8 && wasm[2] == 's' as u8 && wasm[3] == 'm' as u8)
    );
}

[Test]
the_library_reports_its_version_and_triple() {
    expect_equal(llvm.version().split(".").count, 3 as ulong);
    expect_true(llvm.default_triple().size > 0);
}
