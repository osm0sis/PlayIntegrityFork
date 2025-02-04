package es.chiteroman.playintegrityfix;

import android.annotation.SuppressLint;
import android.os.Build;
import java.lang.reflect.Field;
import android.util.Log;

public final class EntryPointVending {

    private static void LOG(String msg) {
        Log.d("PIF/Java:vending", msg);
    }

    @SuppressLint("DefaultLocale")
    public static void init(int verboseLogs, int spoofVendingSdk) {
        if (spoofVendingSdk < 1) return;
        int requestSdk = spoofVendingSdk == 1 ? 32 : spoofVendingSdk;
        int targetSdk = Math.min(Build.VERSION.SDK_INT, requestSdk);
        int oldValue;
        try {
            Field field = Build.VERSION.class.getDeclaredField("SDK_INT");
            field.setAccessible(true);
            oldValue = field.getInt(null);
            if (oldValue == targetSdk) {
                if (verboseLogs > 2) LOG(String.format("[SDK_INT]: %d (unchanged)", oldValue));
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
    }
}
