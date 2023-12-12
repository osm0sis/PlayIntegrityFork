package es.chiteroman.playintegrityfix;

import java.security.Provider;

public final class SpoofingProvider extends Provider {

    SpoofingProvider(Provider provider) {
        super(provider.getName(), provider.getVersion(), provider.getInfo());
        putAll(provider);
        this.putService(new Service(this, "KeyStore", "AndroidKeyStore", CustomKeyStoreSpi.class.getName(), null, null));
    }

    @Override
    public synchronized Service getService(String type, String algorithm) {
        EntryPoint.spoofDevice();
        return super.getService(type, algorithm);
    }
}
