package com.hippo.desktop;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import java.util.Locale;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

public class ZipImageSource implements ImageSource {

    private final ZipFile zipFile;
    private final List<String> imageNames;

    public ZipImageSource(java.io.File file) throws IOException {
        this.zipFile = new ZipFile(file);
        this.imageNames = scanImages(zipFile);
    }

    private static List<String> scanImages(ZipFile zipFile) {
        List<String> names = new ArrayList<>();
        Enumeration<? extends ZipEntry> entries = zipFile.entries();
        while (entries.hasMoreElements()) {
            ZipEntry entry = entries.nextElement();
            if (entry.isDirectory()) continue;
            String name = entry.getName();
            String lname = name.toLowerCase(Locale.ROOT);
            if (lname.endsWith(".jpg") || lname.endsWith(".jpeg") || lname.endsWith(".png") || 
                lname.endsWith(".gif") || lname.endsWith(".bmp") || lname.endsWith(".webp")) {
                names.add(name);
            }
        }
        return names;
    }

    @Override
    public List<String> getImageNames() {
        return new ArrayList<>(imageNames);
    }

    @Override
    public InputStream open(String name) throws IOException {
        ZipEntry entry = zipFile.getEntry(name);
        if (entry == null) throw new IOException("Entry not found: " + name);
        return zipFile.getInputStream(entry);
    }

    @Override
    public void close() throws IOException {
        zipFile.close();
    }
}

