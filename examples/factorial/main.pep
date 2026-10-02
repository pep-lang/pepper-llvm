# Calls the `factorial` that generate.pep compiled with LLVM, linked from
# the library `factorial` (libfactorial.a, or factorial.lib on Windows).

[Link("factorial")]
extern long factorial(long n);

main(): int {
    if (factorial(0) != 1 || factorial(1) != 1 || factorial(5) != 120 || factorial(20) != 2432902008176640000) {
        return 1;
    }
    print($"20! = {factorial(20)}");
    return 0;
}
