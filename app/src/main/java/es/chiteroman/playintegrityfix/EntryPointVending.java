package es.chiteroman.playintegrityfix;

import android.annotation.SuppressLint;
import android.os.Build;
import java.lang.reflect.Field;
import android.util.Log;

public final class EntryPointVending {

    private static void LOG(String msg) {
        Log.d("PIF/Java:PS", msg);
    }

    @SuppressLint("DefaultLocale")
    public static void init(int verboseLogs, int spoofVendingFingerprint, int spoofVendingSdk, String spoofFingerprintValue) {
        if (spoofVendingSdk > 0){
            int requestSdk = spoofVendingSdk == 1 ? 32 : spoofVendingSdk;
            int targetSdk = Math.min(Build.VERSION.SDK_INT, requestSdk);
            int oldValue;
            try {
                Field field = Build.VERSION.class.getDeclaredField("SDK_INT");
                field.setAccessible(true);
                oldValue = field.getInt(null);
                if (oldValue == targetSdk) {
                    if (verboseLogs > 2) LOG(String.format("[SDK_INT]: %d (unchanged)", oldValue));
                    field.setAccessible(false);
                    return;
                }
                field.set(null, targetSdk);
                field.setAccessible(false);
                LOG(String.format("[SDK_INT]: %d -> %d", oldValue, targetSdk));
            } catch (NoSuchFieldException e) {
                LOG("SDK_INT field not found: " + e);
            } catch (SecurityException | IllegalAccessException | IllegalArgumentException |
                     NullPointerException | ExceptionInInitializerError e) {
                LOG("SDK_INT field not accessible: " + e);
            }
            return
        }
        if (spoofVendingFingerprint < 1) return;
        String oldValue;
        try {
            Field field = Build.VERSION.class.getDeclaredField("FINGERPRINT");
            field.setAccessible(true);
            oldValue = String.valueOf(field.get(null));
            if (oldValue.equals(spoofFingerprintValue) {
                if (verboseLogs > 2) LOG(String.format("[FINGERPRINT]: %s (unchanged)", oldValue));
                field.setAccessible(false);
                return;
            }
            field.set(null, spoofFingerprintValue);
            field.setAccessible(false);
            LOG(String.format("[FINGERPRINT]: %s -> %s", oldValue, spoofFingerprintValue));
        } catch (NoSuchFieldException e) {
            LOG("FINGERPRINT field not found: " + e);
        } catch (SecurityException | IllegalAccessException | IllegalArgumentException |
                 NullPointerException | ExceptionInInitializerError e) {
            LOG("FINGERPRINT field not accessible: " + e);
        }
    }
}


