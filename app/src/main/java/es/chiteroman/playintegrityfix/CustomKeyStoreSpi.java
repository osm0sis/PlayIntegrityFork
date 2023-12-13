package es.chiteroman.playintegrityfix;

import android.util.Log;

import java.lang.reflect.Field;
import java.security.Key;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.KeyStoreSpi;
import java.security.Provider;
import java.security.Security;
import java.security.cert.Certificate;
import java.util.Collections;
import java.util.Date;
import java.util.Enumeration;
import java.util.HashSet;
import java.util.Set;

public class CustomKeyStoreSpi extends KeyStoreSpi {
    public static KeyStoreSpi keyStoreSpi; // final keyword removed
    private final Set<String> aliases = new HashSet<>();

    public CustomKeyStoreSpi(KeyStoreSpi keyStoreSpi) {
        this.keyStoreSpi = keyStoreSpi; // final keyword removed
    }

    public static void init() {
        try {
            KeyStore keyStore = KeyStore.getInstance("AndroidKeyStore");
            keyStore.load(null);

            Field f = keyStore.getClass().getDeclaredField("mSpi");
            f.setAccessible(true);
            CustomKeyStoreSpi.keyStoreSpi = (KeyStoreSpi) f.get(keyStore);

            Provider provider = Security.getProvider("AndroidKeyStore");
            provider.put("KeyStore.AndroidKeyStore", CustomKeyStoreSpi.class.getName());
        } catch (Exception e) {
            EntryPoint.LOG("Couldn't initialize CustomKeyStoreSpi: " + e);
        }
    }

    @Override
    public Key engineGetKey(String alias, char[] password) throws KeyStoreException {
        if (alias == null) return null; // null check added
        return keyStoreSpi.engineGetKey(alias, password);
    }

    @Override
    public Certificate[] engineGetCertificateChain(String alias) { // throws KeyStoreException removed
        if (alias == null) return null; // null check added
        return keyStoreSpi.engineGetCertificateChain(alias);
    }

    @Override
    public Certificate engineGetCertificate(String alias) {
        if (alias == null) return null; // null check added
        return keyStoreSpi.engineGetCertificate(alias);
    }

    @Override
    public Date engineGetCreationDate(String alias) {
        return keyStoreSpi.engineGetCreationDate(alias);
    }

    @Override
    public void engineSetKeyEntry(String alias, Key key, char[] password, Certificate[] chain) throws KeyStoreException {
        if (key == null) throw new KeyStoreException("key is null"); // null check added
        keyStoreSpi.engineSetKeyEntry(alias, key, password, chain);
    }

    @Override
    public void engineSetKeyEntry(String alias, byte[] key, Certificate[] chain) throws KeyStoreException {
        keyStoreSpi.engineSetKeyEntry(alias, key, chain);
    }

    @Override
    public void engineSetCertificateEntry(String alias, Certificate certificate) throws KeyStoreException {
        if (certificate == null) throw new KeyStoreException("certificate is null"); // null check added
        keyStoreSpi.engineSetCertificateEntry(alias, certificate);
    }

    @Override
    public void engineDeleteEntry(String alias) throws KeyStoreException {
        if (alias == null) throw new KeyStoreException("alias is null"); // null check added
        keyStoreSpi.engineDeleteEntry(alias);
    }

    @Override
    public Enumeration<String> engineAliases() {
        return Collections.enumeration(aliases);
    }

    @Override
    public boolean engineContainsAlias(String alias) {
        if (alias == null) return false; // null check added
        return aliases.contains(alias);
    }

    @Override
    public int engineSize() {
        return aliases.size();
    }

    @Override
    public boolean engineIsKeyEntry(String alias) {
        return keyStoreSpi.engineIsKeyEntry(alias);
    }

    @Override
    public boolean engineIsCertificateEntry(String alias) {
        return keyStoreSpi.engineIsCertificateEntry(alias);
    }

    @Override
    public String engineGetCertificateAlias(Certificate certificate) {
        return keyStoreSpi.engineGetCertificateAlias(certificate);
    }

    @Override
    public void engineStore(KeyStore.LoadStoreParameter param) throws KeyStoreException {
        keyStoreSpi.engineStore(param);
    }

    @Override
    public void engineLoad(KeyStore.LoadStoreParameter param) throws KeyStoreException {
        keyStoreSpi.engineLoad(param);
    }

    @Override
    public void engineStore(java.io.OutputStream stream, char[] password) throws KeyStoreException {
        keyStoreSpi.engineStore(stream, password);
    }

    @Override
    public void engineLoad(java.io.InputStream stream, char[] password) throws KeyStoreException {
        keyStoreSpi.engineLoad(stream, password);
    }
}
