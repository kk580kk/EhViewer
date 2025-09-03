package com.hippo.desktop;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class ReaderController {

    private ImageSource imageSource;
    private List<String> imageNames;
    private int currentIndex;

    public ReaderController() {
        this.imageNames = new ArrayList<>();
        this.currentIndex = -1;
    }

    public void openDirectory(File directory) throws IOException {
        close();
        this.imageSource = new DirectoryImageSource(directory);
        this.imageNames = new ArrayList<>(imageSource.getImageNames());
        Collections.sort(this.imageNames, new NaturalOrderComparator());
        this.currentIndex = this.imageNames.isEmpty() ? -1 : 0;
    }

    public void openZip(File zipFile) throws IOException {
        close();
        this.imageSource = new ZipImageSource(zipFile);
        this.imageNames = new ArrayList<>(imageSource.getImageNames());
        Collections.sort(this.imageNames, new NaturalOrderComparator());
        this.currentIndex = this.imageNames.isEmpty() ? -1 : 0;
    }

    public void openArchive(File archiveFile) throws IOException {
        close();
        String fileName = archiveFile.getName().toLowerCase();
        if (fileName.endsWith(".zip") || fileName.endsWith(".cbz")) {
            this.imageSource = new ZipImageSource(archiveFile);
        } else if (fileName.endsWith(".rar") || fileName.endsWith(".cbr")) {
            this.imageSource = new RarImageSource(archiveFile);
        } else {
            throw new IOException("Unsupported archive format: " + fileName);
        }
        this.imageNames = new ArrayList<>(imageSource.getImageNames());
        Collections.sort(this.imageNames, new NaturalOrderComparator());
        this.currentIndex = this.imageNames.isEmpty() ? -1 : 0;
    }

    public boolean hasImages() {
        return currentIndex >= 0 && currentIndex < imageNames.size();
    }

    public int getCurrentIndex() {
        return currentIndex;
    }

    public int getTotalCount() {
        return imageNames.size();
    }

    public boolean next() {
        if (currentIndex + 1 < imageNames.size()) {
            currentIndex++;
            return true;
        }
        return false;
    }

    public boolean previous() {
        if (currentIndex - 1 >= 0) {
            currentIndex--;
            return true;
        }
        return false;
    }

    public BufferedImage loadCurrentImage() throws IOException {
        if (!hasImages()) return null;
        String name = imageNames.get(currentIndex);
        try (InputStream inputStream = imageSource.open(name)) {
            return ImageIO.read(inputStream);
        }
    }

    public String getCurrentName() {
        if (!hasImages()) return null;
        return imageNames.get(currentIndex);
    }

    public boolean goToFirst() {
        if (!imageNames.isEmpty()) {
            currentIndex = 0;
            return true;
        }
        return false;
    }

    public boolean goToLast() {
        if (!imageNames.isEmpty()) {
            currentIndex = imageNames.size() - 1;
            return true;
        }
        return false;
    }

    public void close() {
        if (imageSource != null) {
            try {
                imageSource.close();
            } catch (IOException ignored) {}
        }
        imageSource = null;
        imageNames.clear();
        currentIndex = -1;
    }
}

