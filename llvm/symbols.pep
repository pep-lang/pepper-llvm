# Finds a function of the linked LLVM library by name at run time, for
# backends' `LLVMInitialize<Name>*` functions: which ones exist depends on
# how LLVM was built, so declaring them as externs would fail to link
# against a build without one.

[Target(OS(Linux))]
[Link("dl")]
extern void* dlsym(void* handle, char* name);

[Target(OS(Linux))]
export _llvm_symbol(name: String): __ptr<void> {
    # RTLD_DEFAULT is null on Linux: search every loaded library.
    return dlsym(__null, name.c_str());
}

[Target(OS(Mac))]
extern void* dlsym(long handle, char* name);

[Target(OS(Mac))]
export _llvm_symbol(name: String): __ptr<void> {
    # RTLD_DEFAULT is (void*)-2 on macOS.
    return dlsym(-2, name.c_str());
}

[Target(OS(Windows))]
extern void* GetModuleHandleA(char* name);
[Target(OS(Windows))]
extern void* GetProcAddress(void* module, char* name);

[Target(OS(Windows))]
export _llvm_symbol(name: String): __ptr<void> {
    var module = GetModuleHandleA("LLVM-C.dll");
    if (module == __null) {
        return __null;
    }
    return GetProcAddress(module, name.c_str());
}
