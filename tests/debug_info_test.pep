# Builds a function with debug info: a compile unit, a subprogram, a
# parameter and a local variable with their types, and line locations.

import llvm;

[Test]
functions_carry_debug_info() {
    var context = llvm.Context();
    var module = llvm.Module(context, "debug");
    var machine = llvm.TargetMachine.host(llvm.OptLevel.O0).value();
    machine.configure(module);

    var debug = llvm.DebugBuilder(module);
    debug.set_dwarf_version(5);
    var file = debug.file("twice.pep", "/src");
    var unit = debug.compile_unit(file, "pepper-llvm test", llvm.DwarfLanguage.C);
    var int_type = debug.basic_type("int", 32, llvm.DwarfEncoding.Signed);
    var int_pointer = debug.pointer_type(int_type, 64);
    var point_x = debug.member_type(file, "x", file, 1, 32, 32, 0, int_type);
    var point_y = debug.member_type(file, "y", file, 1, 32, 32, 32, int_type);
    var point = debug.struct_type(unit, "Point", file, 1, 64, 32, [point_x, point_y]);
    expect_false(int_pointer.is_null());
    expect_false(point.is_null());

    # int twice(int value) {   // line 3
    #     int result = value * 2;   // line 4
    #     return result;            // line 5
    # }
    var i32 = context.int32_type();
    var twice = module.add_function("twice", llvm.Type.function(i32, [i32]));
    var signature = debug.subroutine_type(file, int_type, [int_type]);
    var info = debug.function(unit, "twice", file, 3, signature);
    twice.set_subprogram(info);

    var entry = context.append_block(twice, "entry");
    var builder = llvm.Builder(context);
    builder.position_at_end(entry);
    builder.set_location(debug.location(3, 1, info));
    var value_slot = builder.alloca(i32, "value.address");
    builder.store(twice.param(0), value_slot);
    var parameter = debug.parameter_variable(info, "value", 1, file, 3, int_type);
    debug.declare(value_slot, parameter, debug.location(3, 11, info), entry);

    builder.set_location(debug.location(4, 5, info));
    var result_slot = builder.alloca(i32, "result.address");
    var block = debug.lexical_block(info, file, 3, 25);
    var result = debug.local_variable(block, "result", file, 4, int_type);
    debug.declare(result_slot, result, debug.location(4, 9, block), entry);
    var loaded = builder.load(i32, value_slot, "value");
    builder.store(builder.mul(loaded, i32.const_int(2), "doubled"), result_slot);

    builder.set_location(debug.location(5, 5, info));
    builder.return_value(builder.load(i32, result_slot, "result"));
    builder.clear_location();
    debug.finalize();

    var verified = module.verify();
    if (verified.is_err()) {
        print(verified.error().message);
    }
    expect_true(verified.is_ok());
    var text = module.to_string();
    var expected = [
        "!DICompileUnit(language: DW_LANG_C",
        "!DIFile(filename: \"twice.pep\", directory: \"/src\")",
        "!DISubprogram(name: \"twice\"",
        "!DILocalVariable(name: \"value\", arg: 1",
        "!DILocalVariable(name: \"result\"",
        "#dbg_declare(",
        "!\"Debug Info Version\"",
        "!\"Dwarf Version\", i32 5",
        "!DILocation(line: 5, column: 5",
    ];
    for (var line in expected) {
        if (!text.contains(line)) {
            print($"missing: {line}");
            print(text);
        }
        expect_true(text.contains(line));
    }

    # The object carries the debug sections.
    var assembly = String._from_bytes(machine.emit_to_memory(module, llvm.FileKind.Assembly).value());
    expect_true(assembly.contains(".debug_info") || assembly.contains("__debug_info") || assembly.contains(".debug$S"));
}
