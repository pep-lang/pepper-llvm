# Compiles a `factorial` function to an object file with LLVM:
#
#     long factorial(long n) {
#         long result = 1;
#         for (long i = 2; i <= n; i++) result *= i;
#         return result;
#     }
#
# Usage: generate <output.o>. `main.pep` links the object and calls it.

import llvm;

main(args: String[]): int {
    if (args.count != 2) {
        print("usage: generate <output.o>");
        return 2;
    }
    var context = llvm.Context();
    var module = llvm.Module(context, "factorial");
    var i64 = context.int64_type();
    var factorial = module.add_function("factorial", llvm.Type.function(i64, [i64]));

    var entry = context.append_block(factorial, "entry");
    var loop = context.append_block(factorial, "loop");
    var done = context.append_block(factorial, "done");
    var builder = llvm.Builder(context);

    # entry: skip the loop when n < 2.
    builder.position_at_end(entry);
    var n = factorial.param(0);
    n.set_name("n");
    var small = builder.compare(llvm.IntPredicate.SignedLess, n, i64.const_int(2), "small");
    builder.conditional_branch(small, done, loop);

    # loop: result *= i; i++; repeat while i <= n.
    builder.position_at_end(loop);
    var i = builder.phi(i64, "i");
    var result = builder.phi(i64, "result");
    var product = builder.mul(result, i, "product");
    var next = builder.add(i, i64.const_int(1), "next");
    var more = builder.compare(llvm.IntPredicate.SignedLessOrEqual, next, n, "more");
    builder.conditional_branch(more, loop, done);
    i.add_incoming([i64.const_int(2), next], [entry, loop]);
    result.add_incoming([i64.const_int(1), product], [entry, loop]);

    # done: 1 when the loop never ran, else the product.
    builder.position_at_end(done);
    var answer = builder.phi(i64, "answer");
    answer.add_incoming([i64.const_int(1), product], [entry, loop]);
    builder.return_value(answer);

    var verified = module.verify();
    if (verified.is_err()) {
        print(verified.error().message);
        return 1;
    }
    var machine = llvm.TargetMachine.host().value();
    machine.configure(module);
    module.run_passes("default<O2>", machine).value();
    var written = machine.emit_to_file(module, args[1]);
    if (written.is_err()) {
        print(written.error().message);
        return 1;
    }
    return 0;
}
