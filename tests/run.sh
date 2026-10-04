#!/usr/bin/env bash
# Runs the package's tests: the [Test] functions under tests/ with
# `pepper test`, then the factorial example end to end (generate an object
# with LLVM, archive it, link it into a Pepper program, run it).
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
# The package is the module `llvm`: a folder of that name on the import path.
mkdir packages
ln -s "$root" packages/llvm
"$pepper" test -I packages "${library_dirs[@]}" "$root/tests"

"$pepper" build -I packages "${library_dirs[@]}" "$root/examples/factorial/generate.pep" -o generate
./generate factorial.o
ar rcs libfactorial.a factorial.o
"$pepper" build -L "$build" "$root/examples/factorial/main.pep" -o factorial
./factorial
echo "all tests passed"
