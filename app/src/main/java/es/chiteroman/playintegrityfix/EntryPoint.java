package es.chiteroman.playintegrityfix;

import android.os.Build;
import android.util.JsonReader;
import android.util.Log;

import java.io.IOException;
import java.io.StringReader;
import java.lang.reflect.Field;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.KeyStoreSpi;
import java.security.Provider;
import java.security.Security;
import java.util.HashMap;
import java.util.Map;
import static es.chiteroman.playintegrityfix.SomeOtherClass.LOG;

public final class EntryPoint {
    public final Map<String, String> map;

    public EntryPoint(String data) {
        map = new HashMap<>();
        try (JsonReader reader = new JsonReader(new StringReader(data))) {
            reader.beginObject();
            while (reader.hasNext()) {
                map.put(reader.nextName(), reader.nextString());
            }
            reader.endObject();
        } catch (IOException e) {
            log("Couldn't read JSON from Zygisk: " + e);
            return;
        }
    }

    public static void init() {
        spoofProvider();
        spoofDevice();
    }

    private static void spoofProvider() {
        final String KEYSTORE = "AndroidKeyStore";

        try {
            Provider provider = Security.getProvider(KEYSTORE);
            KeyStore keyStore = KeyStore.getInstance(KEYSTORE);

            Field f = keyStore.getClass().getDeclaredField("keyStoreSpi");
            f.setAccessible(true);
            CustomKeyStoreSpi.keyStoreSpi = (KeyStoreSpi) f.get(keyStore);

            CustomProvider customProvider = new CustomProvider(provider);
            Security.removeProvider(KEYSTORE);
            Security.insertProviderAt(customProvider, 1);

            log("Spoof KeyStoreSpi and Provider done!");

        } catch (KeyStoreException e) {
            log("Couldn't find KeyStore: " + e);
        } catch (NoSuchFieldException e) {
            log("Couldn't find field: " + e);
        } catch (IllegalAccessException e) {
            log("Couldn't change access of field: " + e);
        }
    }

    static void spoofDevice() {
        for (String key : map.keySet()) {
            if (key.equals("BUILD_ID")) {
                setField("ID", map.get("BUILD_ID"));
            } else if (key.equals("FIRST_API_LEVEL")) {
                setField("DEVICE_INITIAL_SDK_INT", map.get("FIRST_API_LEVEL"));
            } else {
                setField(key, map.get(key));
            }
        }
    }

    private static boolean classContainsField(Class className, String fieldName) {
        for (Field field : className.getDeclaredFields()) {
            if (field.getName().equals(fieldName)) return true;
        }
        return false;
    }

    private static void setField(String name, String value) {
        if (value == null || value.isEmpty()) {
            log(String.format("%s is null, skipping...", name));
            return;
        }

        Field field = null;
        String oldValue = null;

        try {
            if (classContainsField(Build.class, name)) {
                field = Build.class.getDeclaredField(name);
            } else if (classContainsField(Build.VERSION.class, name)) {
                field = Build.VERSION.class.getDeclaredField(name);
            } else {
                log(String.format("Couldn't determine '%s' class name", name));
                return;
            }
        } catch (NoSuchFieldException e) {
            log(String.format("Couldn't find '%s' field name: " + e, name));
            return;
        }
        field.setAccessible(true);
        try {
            oldValue = String.valueOf(field.get(null));
        } catch (IllegalAccessException e) {
            log(String.format("Couldn't access '%s' field value: " + e, name));
            return;
        }
        if (value.equals(oldValue)) {
            log(String.format("[%s]: already '%s', skipping...", name, value));
            return;
        }
        Object newValue = null;
        Class<?> fieldType = field.getType();
        if (fieldType == String.class) {
            newValue = value;
        } else if (fieldType == int.class) {
            newValue = Integer.parseInt(value);
        } else if (fieldType == long.class) {
            newValue = Long.parseLong(value);
        } else if (fieldType == boolean.class) {
            newValue = Boolean.parseBoolean(value);
        } else {
            log(String.format("Couldn't convert '%s' to '%s' type", value, fieldType));
            return;
        }
        try {
            field.set(null, newValue);
        } catch (IllegalAccessException e) {
            log(String.format("Couldn't set '%s' field value: " + e, name));
            return;
        }
        log(String.format("[%s]: %s -> %s", name, oldValue, value));
    }

    // A helper method to log messages to the console
    private static void log(String msg) {
        Log.d("PIF/Java", msg);
    }
}
