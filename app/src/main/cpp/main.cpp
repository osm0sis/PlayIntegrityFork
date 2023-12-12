//SUGGESTION!
#include <android/log.h>
#include <sys/system_properties.h>
#include <unistd.h>

#include "zygisk.hpp"
#include "shadowhook.h"
#include "json.hpp"

#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, "PIF/Native", __VA_ARGS__)

#define DEX_FILE_PATH "/data/adb/modules/playintegrityfix/classes.dex"

#define JSON_FILE_PATH "/data/adb/modules/playintegrityfix/pif.json"
#define CUSTOM_JSON_FILE_PATH "/data/adb/modules/playintegrityfix/custom.pif.json"

static std::string FIRST_API_LEVEL, SECURITY_PATCH, BUILD_ID, VNDK_VERSION;

typedef void (*T_Callback)(void *, const char *, const char *, uint32_t);

static std::map<void *, T_Callback> callbacks;

static void modify_callback(void *cookie, const char *name, const char *value, uint32_t serial) {

    if (cookie == nullptr || name == nullptr || value == nullptr ||
        !callbacks.contains(cookie))
        return;

    std::string_view prop(name);

    if (prop.ends_with("api_level")) {
        if (FIRST_API_LEVEL.empty()) {
            LOGD("FIRST_API_LEVEL is empty, ignoring it...");
            return;
        } else {
            value = FIRST_API_LEVEL.c_str();
        }
        LOGD("[%s] -> %s", name, value);
    } else if (prop.ends_with("security_patch")) {
        if (SECURITY_PATCH.empty()) {
            LOGD("SECURITY_PATCH is empty, ignoring it...");
            return;
        } else {
            value = SECURITY_PATCH.c_str();
        }
        LOGD("[%s] -> %s", name, value);
    } else if (prop == "ro.build.id") {
        if (BUILD_ID.empty()) {
            LOGD("BUILD_ID is empty, ignoring it...");
            return;
        } else {
            value = BUILD_ID.c_str();
        }
        LOGD("[%s] -> %s", name, value);
    } else if (prop.ends_with("vndk.version")) {
        if (VNDK_VERSION.empty()) {
            LOGD("VNDK_VERSION is empty, ignoring it...");
            return;
        } else {
            value = VNDK_VERSION.c_str();
        }
        LOGD("[%s] -> %s", name, value);
    }

    return callbacks[cookie](cookie, name, value, serial);
}

static void (*o_system_property_read_callback)(const prop_info *, T_Callback, void *);

static void my_system_property_read_callback(const prop_info *pi, T_Callback callback, void *cookie) {
    if (pi == nullptr || callback == nullptr || cookie == nullptr) {
        return o_system_property_read_callback(pi, callback, cookie);
    }
    callbacks[cookie] = callback;
    return o_system_property_read_callback(pi, modify_callback, cookie);
}

static void doHook() {
    shadowhook_init(SHADOWHOOK_MODE_UNIQUE, false);
    void *handle = shadowhook_hook_sym_name(
            "libc.so",
            "__system_property_read_callback",
            reinterpret_cast<void *>(my_system_property_read_callback),
            reinterpret_cast<void **>(&o_system_property_read_callback)
    );
    if (handle == nullptr) {
        LOGD("Couldn't find '__system_property_read_callback' handle. Report to @chiteroman");
        return;
    }
    LOGD("Found '__system_property_read_callback' handle at %p", handle);
}

class PlayIntegrityFix : public zygisk::ModuleBase {
public:
    void onLoad(zygisk::Api *api, JNIEnv *env) override {
        this->api = api;
        this->env = env;
    }

    void preAppSpecialize(zygisk::AppSpecializeArgs *args) override {
        bool isGms = false, isGmsUnstable = false;

        auto rawProcess = env->GetStringUTFChars(args->nice_name, nullptr);

        if (rawProcess) {
            std::string_view process(rawProcess);

            isGms = process.starts_with("com.google.android.gms");
            isGmsUnstable = process.compare("com.google.android.gms.unstable") == 0;
        }

        env->ReleaseStringUTFChars(args->nice_name, rawProcess);

        if (!isGms) {
            api->setOption(zygisk::DLCLOSE_MODULE_LIBRARY);
            return;
        }

        api->setOption(zygisk::FORCE_DENYLIST_UNMOUNT);

        if (!isGmsUnstable) {
            api->setOption(zygisk::DLCLOSE_MODULE_LIBRARY);
            return;
        }

        long dexSize = 0, jsonSize = 0;
        int fd = api->connectCompanion();

        read(fd, &dexSize, sizeof(long));
        read(fd, &jsonSize, sizeof(long));

        if (dexSize < 1) {
            close(fd);
            LOGD("Couldn't read classes.dex");
            api->setOption(zygisk::DLCLOSE_MODULE_LIBRARY);
            return;
        }

        if (jsonSize < 1) {
            close(fd);
            LOGD("Couldn't read pif.json");
            api->setOption(zygisk::DLCLOSE_MODULE_LIBRARY);
            return;
        }

        dexVector.resize(dexSize);
        read(fd, dexVector.data(), dexSize);

        std::vector<char> jsonVector(jsonSize);
        read(fd, jsonVector.data(), jsonSize);

        close(fd);

        LOGD("Read from file descriptor file 'classes.dex' -> %ld bytes", dexSize);
        LOGD("Read from file descriptor file 'pif.json' -> %ld bytes", jsonSize);

        std::string data(jsonVector.cbegin(), jsonVector.cend());
        json = nlohmann::json::parse(data, nullptr, false, true);

        jsonVector.clear();
        data.clear();
    }

    void postAppSpecialize(const zygisk::AppSpecializeArgs *args) override {
        if (dexVector.empty() || json.empty()) return;

        readJson();

        doHook();

        inject();

        dexVector.clear();
        json.clear();
    }

    void preServerSpecialize(zygisk::ServerSpecializeArgs *args) override {
        api->setOption(zygisk::DLCLOSE_MODULE_LIBRARY);
    }

private:
    zygisk::Api *api = nullptr;
    JNIEnv *env = nullptr;
    std::vector<char> dexVector;
    nlohmann::json json;

    void readJson() {
        LOGD("JSON contains %d keys!", static_cast<int>(json.size()));

        // Direct property spoofing workarounds
        if (json.contains("ID")) {
            if (json["ID"].is_null()) {
                LOGD("Key ID is null!");
            } else if (json["ID"].is_string()) {
                BUILD_ID = json["ID"].get<std::string>();
            } else {
                LOGD("Error parsing ID!");
            }
        } else {
            LOGD("Key ID doesn't exist in JSON file!");
        }
        if (json.contains("SECURITY_PATCH")) {
            if (json["SECURITY_PATCH"].is_null()) {
                LOGD("Key SECURITY_PATCH is null!");
            } else if (json["SECURITY_PATCH"].is_string()) {
                SECURITY_PATCH = json["SECURITY_PATCH"].get<std::string>();
            } else {
                LOGD("Error parsing SECURITY_PATCH!");
            }
        } else {
            LOGD("Key SECURITY_PATCH doesn't exist in JSON file!");
        }
        if (json.contains("DEVICE_INITIAL_SDK_INT")) {
            if (json["DEVICE_INITIAL_SDK_INT"].is_null()) {
                LOGD("Key DEVICE_INITIAL_SDK_INT is null!");
            } else if (json["DEVICE_INITIAL_SDK_INT"].is_string()) {
                FIRST_API_LEVEL = json["DEVICE_INITIAL_SDK_INT"].get<std::string>();
            } else {
                LOGD("Error parsing DEVICE_INITIAL_SDK_INT!");
            }
        } else {
            LOGD("Key DEVICE_INITIAL_SDK_INT doesn't exist in JSON file!");
        }

        // Backwards compatibility for chiteroman's alternate API naming
        if (json.contains("BUILD_ID")) {
            if (json["BUILD_ID"].is_null()) {
                LOGD("Key BUILD_ID is null!");
            } else if (json["BUILD_ID"].is_string()) {
                BUILD_ID = json["BUILD_ID"].get<std::string>();
            } else {
                LOGD("Error parsing BUILD_ID!");
            }
        } else {
            LOGD("Key BUILD_ID doesn't exist in JSON file!");
        }
        if (json.contains("FIRST_API_LEVEL")) {
            if (json["FIRST_API_LEVEL"].is_null()) {
                LOGD("Key FIRST_API_LEVEL is null!");
            } else if (json["FIRST_API_LEVEL"].is_string()) {
                FIRST_API_LEVEL = json["FIRST_API_LEVEL"].get<std::string>();
            } else {
                LOGD("Error parsing FIRST_API_LEVEL!");
            }
        } else {
            LOGD("Key FIRST_API_LEVEL doesn't exist in JSON file!");
        }
        if (json.contains("VNDK_VERSION")) {
            if (json["VNDK_VERSION"].is_null()) {
                LOGD("Key VNDK_VERSION is null!");
            } else if (json["VNDK_VERSION"].is_string()) {
                VNDK_VERSION = json["VNDK_VERSION"].get<std::string>();
            } else {
                LOGD("Error parsing VNDK_VERSION!");
            }
            json.erase("VNDK_VERSION"); // Doesn't exist in Build or Build.VERSION
        } else {
            LOGD("Key VNDK_VERSION doesn't exist in JSON file!");
        }
    }

    void inject() {
        LOGD("get system classloader");
        auto clClass = env->FindClass("java/lang/ClassLoader");
        auto getSystemClassLoader = env->GetStaticMethodID(clClass, "getSystemClassLoader",
                                                           "()Ljava/lang/ClassLoader;");
        auto systemClassLoader = env->CallStaticObjectMethod(clClass, getSystemClassLoader);

        LOGD("create class loader");
        auto dexClClass = env->FindClass("dalvik/system/InMemoryDexClassLoader");
        auto dexClInit = env->GetMethodID(dexClClass, "<init>",
                                          "(Ljava/nio/ByteBuffer;Ljava/lang/ClassLoader;)V");
        auto buffer = env->NewDirectByteBuffer(dexVector.data(),
                                               static_cast<jlong>(dexVector.size()));
        auto dexCl = env->NewObject(dexClClass, dexClInit, buffer, systemClassLoader);

        LOGD("load class");
        auto loadClass = env->GetMethodID(clClass, "loadClass",
                                          "(Ljava/lang/String;)Ljava/lang/Class;");
        auto entryClassName = env->NewStringUTF("es.chiteroman.playintegrityfix.EntryPoint");
        auto entryClassObj = env->CallObjectMethod(dexCl, loadClass, entryClassName);

        auto entryClass = (jclass) entryClassObj;

        LOGD("read json");
        auto readProps = env->GetStaticMethodID(entryClass, "readJson",
                                                "(Ljava/lang/String;)V");
        auto javaStr = env->NewStringUTF(json.dump().c_str());
        env->CallStaticVoidMethod(entryClass, readProps, javaStr);

        LOGD("call init");
        auto entryInit = env->GetStaticMethodID(entryClass, "init", "()V");
        env->CallStaticVoidMethod(entryClass, entryInit);
    }
};

static void companion(int fd) {
    long dexSize = 0, jsonSize = 0;
    std::vector<char> dexVector, jsonVector;

    FILE *dex = fopen(DEX_FILE_PATH, "rb");

    if (dex) {
        fseek(dex, 0, SEEK_END);
        dexSize = ftell(dex);
        fseek(dex, 0, SEEK_SET);

        dexVector.resize(dexSize);
        fread(dexVector.data(), 1, dexSize, dex);

        fclose(dex);
    }

    FILE *json = fopen(CUSTOM_JSON_FILE_PATH, "r");
    if (!json)
        json = fopen(JSON_FILE_PATH, "r");

    if (json) {
        fseek(json, 0, SEEK_END);
        jsonSize = ftell(json);
        fseek(json, 0, SEEK_SET);

        jsonVector.resize(jsonSize);
        fread(jsonVector.data(), 1, jsonSize, json);

        fclose(json);
    }

    write(fd, &dexSize, sizeof(long));
    write(fd, &jsonSize, sizeof(long));

    write(fd, dexVector.data(), dexSize);
    write(fd, jsonVector.data(), jsonSize);

    dexVector.clear();
    jsonVector.clear();
}

REGISTER_ZYGISK_MODULE(PlayIntegrityFix)

REGISTER_ZYGISK_COMPANION(companion)
