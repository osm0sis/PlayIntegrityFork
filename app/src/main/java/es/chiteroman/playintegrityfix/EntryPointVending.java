package es.chiteroman.playintegrityfix;

import android.annotation.SuppressLint;
import android.os.Build;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import android.util.Log;
import org.lsposed.hiddenapibypass.HiddenApiBypass;

public final class EntryPointVending {

    private static void LOG(String msg) {
        Log.d("PIF/Java:PS", msg);
    }

    @SuppressLint("DefaultLocale")
    public static void init(int verboseLogs, int spoofVendingFinger, int spoofVendingSdk, String vendingFingerprintValue) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            HiddenApiBypass.addHiddenApiExemptions("");
        }
        // Only spoof FINGERPRINT to Play Store if not forcing Android <13 Play Integrity verdict
        if (spoofVendingSdk < 1) {
            if (spoofVendingFinger < 1) return;
            String oldValue;
            try {
                Field field = Build.class.getDeclaredField("FINGERPRINT");
                field.setAccessible(true);
                try {
                    Field accessFlagsField = Field.class.getDeclaredField("accessFlags");
                    accessFlagsField.setAccessible(true);
                    accessFlagsField.setInt(field, field.getModifiers() & ~java.lang.reflect.Modifier.FINAL);
                } catch (NoSuchFieldException | IllegalAccessException e) {
                    LOG("Couldn't modify accessFlags for FINGERPRINT: " + e);
                }
                oldValue = String.valueOf(field.get(null));
                if (oldValue.equals(vendingFingerprintValue)) {
                    if (verboseLogs > 2) LOG(String.format("[FINGERPRINT]: %s (unchanged)", oldValue));
                    field.setAccessible(false);
                    return;
                }
                try {
                    Class<?> unsafeClass = Class.forName("sun.misc.Unsafe");
                    Field unsafeField = unsafeClass.getDeclaredField("theUnsafe");
                    unsafeField.setAccessible(true);
                    Object unsafe = unsafeField.get(null);

                    Method objectFieldOffset = unsafeClass.getMethod("objectFieldOffset", Field.class);
                    Method putObject = unsafeClass.getMethod("putObject", Object.class, long.class, Object.class);

                    Object base = field.getDeclaringClass();
                    long offset = (long) objectFieldOffset.invoke(unsafe, field);
                    putObject.invoke(unsafe, base, offset, vendingFingerprintValue);
                } catch (Exception e) {
                    LOG("Unsafe failed for FINGERPRINT: " + e);
                    field.set(null, vendingFingerprintValue);
                }
                field.setAccessible(false);
                LOG(String.format("[FINGERPRINT]: %s -> %s", oldValue, vendingFingerprintValue));
            } catch (NoSuchFieldException e) {
                LOG("FINGERPRINT field not found: " + e);
            } catch (SecurityException | IllegalAccessException | IllegalArgumentException |
                     NullPointerException | ExceptionInInitializerError e) {
                LOG("FINGERPRINT field not accessible: " + e);
            }
        } else {
            int requestSdk = spoofVendingSdk == 1 ? 32 : spoofVendingSdk;
            int targetSdk = Math.min(Build.VERSION.SDK_INT, requestSdk);
            int oldValue;
            try {
                Field field = Build.VERSION.class.getDeclaredField("SDK_INT");
                field.setAccessible(true);
                try {
                    Field accessFlagsField = Field.class.getDeclaredField("accessFlags");
                    accessFlagsField.setAccessible(true);
                    accessFlagsField.setInt(field, field.getModifiers() & ~java.lang.reflect.Modifier.FINAL);
                } catch (NoSuchFieldException | IllegalAccessException e) {
                    LOG("Couldn't modify accessFlags for SDK_INT: " + e);
                }
                oldValue = field.getInt(null);
                if (oldValue == targetSdk) {
                    if (verboseLogs > 2) LOG(String.format("[SDK_INT]: %d (unchanged)", oldValue));
                    field.setAccessible(false);
                    return;
                }
                try {
                    Class<?> unsafeClass = Class.forName("sun.misc.Unsafe");
                    Field unsafeField = unsafeClass.getDeclaredField("theUnsafe");
                    unsafeField.setAccessible(true);
                    Object unsafe = unsafeField.get(null);

                    Method objectFieldOffset = unsafeClass.getMethod("objectFieldOffset", Field.class);
                    Method putInt = unsafeClass.getMethod("putInt", Object.class, long.class, int.class);

                    Object base = field.getDeclaringClass();
                    long offset = (long) objectFieldOffset.invoke(unsafe, field);
                    putInt.invoke(unsafe, base, offset, targetSdk);
                } catch (Exception e) {
                    LOG("Unsafe failed for SDK_INT: " + e);
                    field.set(null, targetSdk);
                }
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
}
