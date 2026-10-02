# Exercises the llvm module: builds IR, verifies it, optimizes it and
# compiles it to an object file in memory and on disk. Each check returns
# its own exit code, so a failure says which one broke.

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

main(): int {
    var context = llvm.Context();
    var module = llvm.Module(context, "test");
    var i32 = context.int32_type();

    # Types print as IR and report their kind.
    if (i32.to_string() != "i32" || i32.kind() != llvm.TypeKind.Integer || i32.int_width() != 32) {
        return 1;
    }
    var pair = context.struct_type([i32, context.pointer_type()]);
    if (pair.to_string() != "{ i32, ptr }") {
        return 2;
    }
    var signature = llvm.Type.function(context.void_type(), [i32], true);
    if (signature.to_string() != "void (i32, ...)") {
        return 3;
    }

    # A function with a branch and a phi verifies and prints.
    var max = build_max(context, module);
    if (!max.verify_function() || max.param_count() != 2 || max.name() != "max") {
        return 4;
    }
    if (!module.verify().is_ok()) {
        return 5;
    }
    var text = module.to_string();
    if (!text.contains("define i32 @max(i32 %0, i32 %1)") || !text.contains("%result = phi i32")) {
        return 6;
    }
    if (!module.function("max").is_some() || module.function("missing").is_some()) {
        return 7;
    }

    # A named struct, a global and a call to a declared C function.
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
    var checked = module.verify();
    if (!checked.is_ok()) {
        print(checked.error().message);
        print(module.to_string());
        return 8;
    }
    text = module.to_string();
    if (!text.contains("%Point = type { i32, i32 }")
        || !text.contains("@greeting = private")
        || !text.contains("nounwind")) {
        return 9;
    }
    if (origin.linkage() != llvm.Linkage.Internal || module.global("origin").is_none()) {
        return 10;
    }

    # A block with no terminator fails verification with LLVM's message.
    var broken = llvm.Module(context, "broken");
    var bad = broken.add_function("bad", llvm.Type.function(context.void_type(), Array<llvm.Type>()));
    context.append_block(bad, "entry");
    var verified = broken.verify();
    if (verified.is_ok() || !verified.error().message.contains("terminator")) {
        return 11;
    }

    # Target machine: configure, optimize, size the types, emit.
    var machine = llvm.TargetMachine.host(llvm.OptLevel.O2).value();
    machine.configure(module);
    if (module.target_triple() != machine.triple() || module.data_layout() != machine.data_layout()) {
        return 12;
    }
    if (machine.size_of(point) != 8 || machine.alignment_of(i32) != 4 || machine.offset_of(point, 1) != 4) {
        return 13;
    }
    if (!module.run_passes("default<O2>", machine).is_ok()) {
        return 14;
    }
    if (module.run_passes("no-such-pass").is_ok()) {
        return 15;
    }
    var object = machine.emit_to_memory(module).value();
    if (object.count < 4) {
        return 16;
    }
    # ELF on Linux, Mach-O on macOS, COFF (an x64 or arm64 machine number) on Windows.
    var elf = object[0] == 0x7F && object[1] == 'E' as u8;
    var mach_o = object[0] == 0xCF && object[1] == 0xFA;
    var coff = (object[0] == 0x64 && object[1] == 0x86) || (object[0] == 0x64 && object[1] == 0xAA);
    if (!elf && !mach_o && !coff) {
        return 17;
    }
    var assembly = machine.emit_to_memory(module, llvm.FileKind.Assembly).value();
    if (assembly.count == 0) {
        return 18;
    }

    # An unknown triple is an error, not a crash.
    if (llvm.TargetMachine.create("no-such-arch-unknown-none").is_ok()) {
        return 19;
    }

    # A module keeps its context alive after the context variable is gone.
    var kept = make_module();
    if (!kept.verify().is_ok() || !kept.to_string().contains("ret i64 7")) {
        return 20;
    }

    # Any backend the library has, not only the host's.
    if (llvm.initialize_target("NoSuchBackend").is_ok()) {
        return 22;
    }
    var registered = llvm.initialize_all_targets();
    if (!registered.contains("X86") && !registered.contains("AArch64")) {
        return 23;
    }
    if (!llvm.registered_targets().contains("x86-64") && !llvm.registered_targets().contains("aarch64")) {
        return 24;
    }
    var riscv = cross_compile("RISCV", "riscv64-unknown-linux-gnu");
    if (riscv.count > 0 && (riscv[0] != 0x7F || riscv[1] != 'E' as u8)) {
        return 25;
    }
    var mac = cross_compile("AArch64", "arm64-apple-macosx14.0.0");
    if (mac.count > 0 && (mac[0] != 0xCF || mac[1] != 0xFA)) {
        return 26;
    }
    var windows = cross_compile("X86", "x86_64-pc-windows-msvc");
    if (windows.count > 0 && (windows[0] != 0x64 || windows[1] != 0x86)) {
        return 27;
    }
    var wasm = cross_compile("WebAssembly", "wasm32-unknown-unknown");
    if (wasm.count > 0 && (wasm[0] != 0 || wasm[1] != 'a' as u8 || wasm[2] != 's' as u8 || wasm[3] != 'm' as u8)) {
        return 28;
    }

    if (llvm.version().split(".").count != 3 || llvm.default_triple().size == 0) {
        return 21;
    }
    return 0;
}
