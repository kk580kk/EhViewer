package com.hippo.desktop;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class RarImageSource implements ImageSource {

    private final java.io.File rarFile;
    private final List<String> imageNames;

    public RarImageSource(java.io.File file) throws IOException {
        this.rarFile = file;
        this.imageNames = new ArrayList<>();
        // Note: RAR support requires external library (like junrar)
        // For now, we'll just create a placeholder that shows an error
        throw new IOException("RAR format not yet supported. Please use ZIP files instead.");
    }

    @Override
    public List<String> getImageNames() {
        return new ArrayList<>(imageNames);
    }

    @Override
    public InputStream open(String name) throws IOException {
        throw new IOException("RAR format not yet supported");
    }

    @Override
    public void close() throws IOException {
        // Nothing to close for now
    }
}