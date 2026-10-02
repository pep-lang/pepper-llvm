#!/usr/bin/env bash
# Runs the package's tests: tests/llvm_test.pep, then the factorial example
# end to end (generate an object with LLVM, archive it, link it into a
# Pepper program, run it).
#
# Usage: tests/run.sh [path/to/pepper]   (default: pepper on PATH)
# On macOS, set LLVM_LIB to Homebrew's llvm@20 lib folder if it is not
# $(brew --prefix llvm@20)/lib.
set -euxo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
pepper="${1:-pepper}"
build="$(mktemp -d)"
trap 'rm -rf "$build"' EXIT

library_dirs=()
if [[ "$(uname)" == Darwin ]]; then
    library_dirs=(-L "${LLVM_LIB:-$(brew --prefix llvm@20)/lib}")
fi

cd "$build"
"$pepper" -I "$root" "${library_dirs[@]}" "$root/tests/llvm_test.pep" -o llvm_test
./llvm_test

"$pepper" -I "$root" "${library_dirs[@]}" "$root/examples/factorial/generate.pep" -o generate
./generate factorial.o
ar rcs libfactorial.a factorial.o
"$pepper" -L "$build" "$root/examples/factorial/main.pep" -o factorial
./factorial
echo "all tests passed"
