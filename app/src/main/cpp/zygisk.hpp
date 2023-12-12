/* Copyright 2022-2023 John "topjohnwu" Wu
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
 * REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
 * INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
 * LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
 * OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 */

// This is the public API for Zygisk modules.
// DO NOT MODIFY ANY CODE IN THIS HEADER.

#pragma once

#include <jni.h>

#define ZYGISK_API_VERSION 2

namespace zygisk {

struct Api;
struct AppSpecializeArgs;
struct ServerSpecializeArgs;

class ModuleBase {
public:

    virtual void onLoad(Api *api, JNIEnv *env) {}
    
    virtual void preAppSpecialize(AppSpecializeArgs *args) {}

    virtual void postAppSpecialize(const AppSpecializeArgs *args) {}

    virtual void preServerSpecialize(ServerSpecializeArgs *args) {}

    virtual void postServerSpecialize(const ServerSpecializeArgs *args) {}
};

struct AppSpecializeArgs {
    jint &uid;
    jint &gid;
    jintArray &gids;
    jint &runtime_flags;
    jint &mount_external;
    jstring &se_info;
    jstring &nice_name;
    jstring &instruction_set;
    jstring &app_data_dir;

    jboolean *const is_child_zygote;
    jboolean *const is_top_app;
    jobjectArray *const pkg_data_info_list;
    jobjectArray *const whitelisted_data_info_list;
    jboolean *const mount_data_dirs;
    jboolean *const mount_storage_dirs;

    AppSpecializeArgs() = delete;
};

struct ServerSpecializeArgs {
    jint &uid;
    jint &gid;
    jintArray &gids;
    jint &runtime_flags;
    jlong &permitted_capabilities;
    jlong &effective_capabilities;

    ServerSpecializeArgs() = delete;
};

enum Option : int {

    FORCE_DENYLIST_UNMOUNT = 0,

    DLCLOSE_MODULE_LIBRARY = 1,
};

enum StateFlag : uint32_t {
    PROCESS_GRANTED_ROOT = (1u << 0),

    PROCESS_ON_DENYLIST = (1u << 1),
};

struct Api {

    int connectCompanion();
    int getModuleDir();
    void setOption(Option opt);
    uint32_t getFlags();
    void hookJniNativeMethods(JNIEnv *env, const char *className, JNINativeMethod *methods, int numMethods);
    
    void pltHookRegister(const char *regex, const char *symbol, void *newFunc, void **oldFunc);

    void pltHookExclude(const char *regex, const char *symbol);

    bool pltHookCommit();

private:
    void *impl;
    friend class ModuleBase;
};

#define ZYGISK_MODULE_ENTRY(clazz) \
void zygisk_module_entry(void *impl, JNIEnv *env) { \
    static Api api; \
    api.impl = impl; \
    static clazz module; \
    ModuleBase *m = &module; \
    m->onLoad(&api, env); \
}

#define ZYGISK_COMPANION_ENTRY(func) \
void zygisk_companion_entry(int client) { func(client); }

inline int Api::connectCompanion() {
    return impl ? reinterpret_cast<int (*)(void *)>(impl)(impl) : -1;
}
inline int Api::getModuleDir() {
    return impl ? reinterpret_cast<int (*)(void *)>(impl + sizeof(void *))(impl) : -1;
}
inline void Api::setOption(Option opt) {
    if (impl) reinterpret_cast<void (*)(void *, Option)>(impl + sizeof(void *) * 2)(impl, opt);
}
inline uint32_t Api::getFlags() {
    return impl ? reinterpret_cast<uint32_t (*)(void *)>(impl + sizeof(void *) * 3)(impl) : 0;
}
inline void Api::hookJniNativeMethods(JNIEnv *env, const char *className, JNINativeMethod *methods, int numMethods) {
    if (impl) reinterpret_cast<void (*)(JNIEnv *, const char *, JNINativeMethod *, int)>(impl + sizeof(void *) * 4)(env, className, methods, numMethods);
}
inline void Api::pltHookRegister(const char *regex, const char *symbol, void *newFunc, void **oldFunc) {
    if (impl) reinterpret_cast<void (*)(const char *, const char *, void *, void **)>(impl + sizeof(void *) * 5)(regex, symbol, newFunc, oldFunc);
}
inline void Api::pltHookExclude(const char *regex, const char *symbol) {
    if (impl) reinterpret_cast<void (*)(const char *, const char *)>(impl + sizeof(void *) * 6)(regex, symbol);
}
inline bool Api::pltHookCommit() {
    return impl && reinterpret_cast<bool (*)(void)>(impl + sizeof(void *) * 7)();
}

} // namespace zygisk

extern "C" {

[[gnu::unused, maybe_unused]]
void zygisk_module_entry(void *, JNIEnv *);

[[gnu::unused, maybe_unused]]
void zygisk_companion_entry(int);

} // extern "C"
