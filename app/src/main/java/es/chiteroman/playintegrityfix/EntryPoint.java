package es.chiteroman.playintegrityfix;

import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.Signature;
import android.os.Build;
import android.os.Parcel;
import android.os.Parcelable;
import android.util.Base64;
import android.util.JsonReader;
import android.util.Log;

import org.lsposed.hiddenapibypass.HiddenApiBypass;

import java.io.IOException;
import java.io.StringReader;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.KeyStoreSpi;
import java.security.Provider;
import java.security.Security;
import java.util.HashMap;
import java.util.Map;

public final class EntryPoint {
    private static Integer verboseLogs = 0;
    private static Integer spoofBuildEnabled = 1;

    private static final String signatureData = "MIIFyTCCA7GgAwIBAgIVALyxxl+zDS9SL68SzOr48309eAZyMA0GCSqGSIb3DQEBCwUAMHQxCzAJ\n" +
            "BgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMRYwFAYDVQQHEw1Nb3VudGFpbiBWaWV3MRQw\n" +
            "EgYDVQQKEwtHb29nbGUgSW5jLjEQMA4GA1UECxMHQW5kcm9pZDEQMA4GA1UEAxMHQW5kcm9pZDAg\n" +
            "Fw0yMjExMDExODExMzVaGA8yMDUyMTEwMTE4MTEzNVowdDELMAkGA1UEBhMCVVMxEzARBgNVBAgT\n" +
            "CkNhbGlmb3JuaWExFjAUBgNVBAcTDU1vdW50YWluIFZpZXcxFDASBgNVBAoTC0dvb2dsZSBJbmMu\n" +
            "MRAwDgYDVQQLEwdBbmRyb2lkMRAwDgYDVQQDEwdBbmRyb2lkMIICIjANBgkqhkiG9w0BAQEFAAOC\n" +
            "Ag8AMIICCgKCAgEAsqtalIy/nctKlrhd1UVoDffFGnDf9GLi0QQhsVoJkfF16vDDydZJOycG7/kQ\n" +
            "ziRZhFdcoMrIYZzzw0ppBjsSe1AiWMuKXwTBaEtxN99S1xsJiW4/QMI6N6kMunydWRMsbJ6aAxi1\n" +
            "lVq0bxSwr8Sg/8u9HGVivfdG8OpUM+qjuV5gey5xttNLK3BZDrAlco8RkJZryAD40flmJZrWXJmc\n" +
            "r2HhJJUnqG4Z3MSziEgW1u1JnnY3f/BFdgYsA54SgdUGdQP3aqzSjIpGK01/vjrXvifHazSANjvl\n" +
            "0AUE5i6AarMw2biEKB2ySUDp8idC5w12GpqDrhZ/QkW8yBSa87KbkMYXuRA2Gq1fYbQx3YJraw0U\n" +
            "gZ4M3fFKpt6raxxM5j0sWHlULD7dAZMERvNESVrKG3tQ7B39WAD8QLGYc45DFEGOhKv5Fv8510h5\n" +
            "sXK502IvGpI4FDwz2rbtAgJ0j+16db5wCSW5ThvNPhCheyciajc8dU1B5tJzZN/ksBpzne4Xf9gO\n" +
            "LZ9ZU0+3Z5gHVvTS/YpxBFwiFpmL7dvGxew0cXGSsG5UTBlgr7i0SX0WhY4Djjo8IfPwrvvA0QaC\n" +
            "FamdYXKqBsSHgEyXS9zgGIFPt2jWdhaS+sAa//5SXcWro0OdiKPuwEzLgj759ke1sHRnvO735dYn\n" +
            "5whVbzlGyLBh3L0CAwEAAaNQME4wDAYDVR0TBAUwAwEB/zAdBgNVHQ4EFgQUU1eXQ7NoYKjvOQlh\n" +
            "5V8jHQMoxA8wHwYDVR0jBBgwFoAUU1eXQ7NoYKjvOQlh5V8jHQMoxA8wDQYJKoZIhvcNAQELBQAD\n" +
            "ggIBAHFIazRLs3itnZKllPnboSd6sHbzeJURKehx8GJPvIC+xWlwWyFO5+GHmgc3yh/SVd3Xja/k\n" +
            "8Ud59WEYTjyJJWTw0Jygx37rHW7VGn2HDuy/x0D+els+S8HeLD1toPFMepjIXJn7nHLhtmzTPlDW\n" +
            "DrhiaYsls/k5Izf89xYnI4euuOY2+1gsweJqFGfbznqyqy8xLyzoZ6bvBJtgeY+G3i/9Be14HseS\n" +
            "Na4FvI1Oze/l2gUu1IXzN6DGWR/lxEyt+TncJfBGKbjafYrfSh3zsE4N3TU7BeOL5INirOMjre/j\n" +
            "VgB1YQG5qLVaPoz6mdn75AbBBm5a5ahApLiKqzy/hP+1rWgw8Ikb7vbUqov/bnY3IlIU6XcPJTCD\n" +
            "b9aRZQkStvYpQd82XTyxD/T0GgRLnUj5Uv6iZlikFx1KNj0YNS2T3gyvL++J9B0Y6gAkiG0EtNpl\n" +
            "z7Pomsv5pVdmHVdKMjqWw5/6zYzVmu5cXFtR384Ti1qwML1xkD6TC3VIv88rKIEjrkY2c+v1frh9\n" +
            "fRJ2OmzXmML9NgHTjEiJR2Ib2iNrMKxkuTIs9oxKZgrJtJKvdU9qJJKM5PnZuNuHhGs6A/9gt9Oc\n" +
            "cetYeQvVSqeEmQluWfcunQn9C9Vwi2BJIiVJh4IdWZf5/e2PlSSQ9CJjz2bKI17pzdxOmjQfE0JS\n" +
            "F7Xt\n";

    private static final Map<String, String> map = new HashMap<>();

    public static Integer getVerboseLogs() {
        return verboseLogs;
    }

    public static Integer getSpoofBuildEnabled() {
        return spoofBuildEnabled;
    }

    public static void init(int logLevel, int spoofBuildVal, int spoofProviderVal, int spoofSignatureVal) {
        verboseLogs = logLevel;
        spoofBuildEnabled = spoofBuildVal;
        if (verboseLogs > 99) logFields();
        if (spoofProviderVal > 0) spoofProvider();
        if (spoofBuildVal > 0) spoofDevice();
        if (spoofSignatureVal > 0) spoofPackageManager();
    }

    public static void receiveJson(String data) {
        try (JsonReader reader = new JsonReader(new StringReader(data))) {
            reader.beginObject();
            while (reader.hasNext()) {
                map.put(reader.nextName(), reader.nextString());
            }
            reader.endObject();
        } catch (IOException|IllegalStateException e) {
            LOG("Couldn't read JSON from Zygisk: " + e);
            map.clear();
            return;
        }
    }

    private static void spoofProvider() {
        final String KEYSTORE = "AndroidKeyStore";

        try {
            Provider provider = Security.getProvider(KEYSTORE);
            KeyStore keyStore = KeyStore.getInstance(KEYSTORE);

            Field f = keyStore.getClass().getDeclaredField("keyStoreSpi");
            f.setAccessible(true);
            CustomKeyStoreSpi.keyStoreSpi = (KeyStoreSpi) f.get(keyStore);
            f.setAccessible(false);

            CustomProvider customProvider = new CustomProvider(provider);
            Security.removeProvider(KEYSTORE);
            Security.insertProviderAt(customProvider, 1);

            LOG("Spoof KeyStoreSpi and Provider done!");

        } catch (KeyStoreException e) {
            LOG("Couldn't find KeyStore: " + e);
        } catch (NoSuchFieldException e) {
            LOG("Couldn't find field: " + e);
        } catch (IllegalAccessException e) {
            LOG("Couldn't change access of field: " + e);
        }
    }

    static void spoofDevice() {
        for (String key : map.keySet()) {
            setField(key, map.get(key));
        }
    }

    private static void spoofPackageManager() {
        Signature spoofedSignature = new Signature(Base64.decode(signatureData, Base64.DEFAULT));
        Parcelable.Creator<PackageInfo> originalCreator = PackageInfo.CREATOR;
        Parcelable.Creator<PackageInfo> customCreator = new CustomPackageInfoCreator(originalCreator, spoofedSignature);

        try {
            Field creatorField = findField(PackageInfo.class, "CREATOR");
            creatorField.setAccessible(true);
            creatorField.set(null, customCreator);
        } catch (Exception e) {
            LOG("Couldn't replace PackageInfoCreator: " + e);
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            HiddenApiBypass.addHiddenApiExemptions("Landroid/os/Parcel;", "Landroid/content/pm", "Landroid/app");
        }

        try {
            Field cacheField = findField(PackageManager.class, "sPackageInfoCache");
            cacheField.setAccessible(true);
            Object cache = cacheField.get(null);
            Method clearMethod = cache.getClass().getMethod("clear");
            clearMethod.invoke(cache);
        } catch (Exception e) {
            LOG("Couldn't clear PackageInfoCache: " + e);
        }

        try {
            Field creatorsField = findField(Parcel.class, "mCreators");
            creatorsField.setAccessible(true);
            Map<?, ?> mCreators = (Map<?, ?>) creatorsField.get(null);
            mCreators.clear();
        } catch (Exception e) {
            LOG("Couldn't clear Parcel mCreators: " + e);
        }

        try {
            Field creatorsField = findField(Parcel.class, "sPairedCreators");
            creatorsField.setAccessible(true);
            Map<?, ?> sPairedCreators = (Map<?, ?>) creatorsField.get(null);
            sPairedCreators.clear();
        } catch (Exception e) {
            LOG("Couldn't clear Parcel sPairedCreators: " + e);
        }
    }

    private static Field findField(Class<?> currentClass, String fieldName) throws NoSuchFieldException {
        while (currentClass != null && !currentClass.equals(Object.class)) {
            try {
                return currentClass.getDeclaredField(fieldName);
            } catch (NoSuchFieldException e) {
                currentClass = currentClass.getSuperclass();
            }
        }
        throw new NoSuchFieldException("Field '" + fieldName + "' not found in class hierarchy of " + currentClass.getName());
    }

    private static boolean classContainsField(Class className, String fieldName) {
        for (Field field : className.getDeclaredFields()) {
            if (field.getName().equals(fieldName)) return true;
        }
        return false;
    }

    private static void setField(String name, String value) {
        if (value.isEmpty()) {
            LOG(String.format("%s is empty, skipping", name));
            return;
        }

        Field field = null;
        String oldValue = null;
        Object newValue = null;

        try {
            if (classContainsField(Build.class, name)) {
                field = Build.class.getDeclaredField(name);
            } else if (classContainsField(Build.VERSION.class, name)) {
                field = Build.VERSION.class.getDeclaredField(name);
            } else {
                if (verboseLogs > 1) LOG(String.format("Couldn't determine '%s' class name", name));
                return;
            }
        } catch (NoSuchFieldException e) {
            LOG(String.format("Couldn't find '%s' field name: " + e, name));
            return;
        }
        field.setAccessible(true);
        try {
            oldValue = String.valueOf(field.get(null));
        } catch (IllegalAccessException e) {
            LOG(String.format("Couldn't access '%s' field value: " + e, name));
            return;
        }
        if (value.equals(oldValue)) {
            if (verboseLogs > 2) LOG(String.format("[%s]: %s (unchanged)", name, value));
            return;
        }
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
            LOG(String.format("Couldn't convert '%s' to '%s' type", value, fieldType));
            return;
        }
        try {
            field.set(null, newValue);
        } catch (IllegalAccessException e) {
            LOG(String.format("Couldn't modify '%s' field value: " + e, name));
            return;
        }
        field.setAccessible(false);
        LOG(String.format("[%s]: %s -> %s", name, oldValue, value));
    }

    private static String logParseField(Field field) {
        Object value = null;
        String type = field.getType().getName();
        String name = field.getName();
        try {
            value = field.get(null);
        } catch (IllegalAccessException|NullPointerException e) {
            return String.format("Couldn't access '%s' field value: " + e, name);
        }
        return String.format("<%s> %s: %s", type, name, String.valueOf(value));
    }

    private static void logFields() {
        for (Field field : Build.class.getDeclaredFields()) {
            LOG("Build " + logParseField(field));
        }
        for (Field field : Build.VERSION.class.getDeclaredFields()) {
            LOG("Build.VERSION " + logParseField(field));
        }
    }

    static void LOG(String msg) {
        Log.d("PIF/Java:DG", msg);
    }
}
