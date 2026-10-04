# Helpers the wrappers share: C strings, LLVM's messages, and C arrays of
# handles. Exported to the module's files only (module.pep does not
# re-export them).

import "llvm_c" as llvm_c;

extern void* malloc(ulong size);
extern void free(void* p);

# `text` as a C string for LLVM. An empty String has no buffer (its
# `c_str()` is null), and LLVM reads a name's first byte, so it gets "".
export _c_string(text: String): __ptr<char> {
    if (text.size == 0) {
        return "";
    }
    return text.c_str();
}

# Copies a string LLVM allocated, then frees it with LLVMDisposeMessage.
export _take_message(message: __ptr<char>): String {
    if (message == __null) {
        return String();
    }
    var text = String(message);
    llvm_c.LLVMDisposeMessage(message);
    return text;
}

# The message of an LLVMErrorRef, which this consumes; "" for null (success).
export _take_error(error: __ptr<void>): String {
    if (error == __null) {
        return String();
    }
    var message = llvm_c.LLVMGetErrorMessage(error);
    var text = String(message);
    llvm_c.LLVMDisposeErrorMessage(message);
    return text;
}

# Copies a string LLVM owns (a `const char*`), or "" for null.
export _copy_string(text: __ptr<char>): String {
    if (text == __null) {
        return String();
    }
    return String(text);
}

# A C array of LLVM handles (`LLVMTypeRef*`, `LLVMValueRef*`, ...) that
# frees itself.
export struct _RefArray {
    var _memory: Handle<__ptr<void>>;
    var count: uint { get; }

    construct(count: ulong) {
        # malloc(0) may return null, which LLVM accepts with a count of 0.
        var size = count == 0 ? 1 : count;
        _memory = Handle<__ptr<void>>(malloc(size * sizeof<__ptr<void>>()), (p) => free(p));
        this.count = count as uint;
    }

    data(): __ptr<__ptr<void>> {
        return _memory.value as __ptr<__ptr<void>>;
    }

    set(index: ulong, ref: __ptr<void>) {
        data()[index] = ref;
    }
}

# A slot C writes one pointer into (an out parameter), freed with it.
export struct _OutPointer {
    var _memory: Handle<__ptr<void>>;

    construct() {
        _memory = Handle<__ptr<void>>(malloc(sizeof<__ptr<void>>()), (p) => free(p));
        data()[0] = __null;
    }

    data(): __ptr<__ptr<void>> {
        return _memory.value as __ptr<__ptr<void>>;
    }

    get(): __ptr<void> {
        return data()[0];
    }
}
