#!/usr/bin/env bash
# Runs the package's tests: the [Test] functions under tests/ with
# `pepper test`, then the factorial example end to end (generate an object
# with LLVM, archive it, link it into a Pepper program, run it).
#
# Usage: tests/run.sh [path/to/pepper]   (default: pepper on PATH)
# LLVM_LIB names the folder holding LLVM 20's library to link. On Windows
# it is LLVM's lib folder (for LLVM-C.lib; its bin folder goes on PATH to
# run); on macOS it defaults to Homebrew's llvm@20 lib folder. Linux needs
# none.
# AR is the archiver for the example's library (default: ar, or llvm-ar
# on Windows).
set -euxo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
pepper="${1:-pepper}"
build="$(mktemp -d)"
trap 'rm -rf "$build"' EXIT

library_dirs=()
if [[ -n "${LLVM_LIB:-}" ]]; then
    library_dirs=(-L "$LLVM_LIB")
elif [[ "$(uname)" == Darwin ]]; then
    library_dirs=(-L "$(brew --prefix llvm@20)/lib")
fi

# The example's library, by the platform's naming.
library=libfactorial.a
ar="${AR:-ar}"
case "$(uname -s)" in
MINGW* | MSYS* | CYGWIN*)
    library=factorial.lib
    ar="${AR:-llvm-ar}"
    ;;
esac

cd "$build"
# The package is the module `llvm`: a folder of that name on the import path.
mkdir packages
ln -s "$root" packages/llvm
"$pepper" test -I packages "${library_dirs[@]}" "$root/tests"

"$pepper" build -I packages "${library_dirs[@]}" "$root/examples/factorial/generate.pep" -o generate
./generate factorial.o
"$ar" rcs "$library" factorial.o
"$pepper" build -L "$build" "$root/examples/factorial/main.pep" -o factorial
./factorial
echo "all tests passed"
