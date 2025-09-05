package com.hippo.desktop;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.io.FileNotFoundException;

public class ReaderController {

    private ImageSource imageSource;
    private List<String> imageNames;
    private int currentIndex;

    public ReaderController() {
        this.imageNames = new ArrayList<>();
        this.currentIndex = -1;
    }

    public void openDirectory(File directory) throws IOException, AppException {
        close();
        this.imageSource = new DirectoryImageSource(directory);
        this.imageNames = new ArrayList<>(imageSource.getImageNames());
        Collections.sort(this.imageNames, new NaturalOrderComparator());
        if (this.imageNames.isEmpty()) {
            throw new EmptyFolderException(directory.getAbsolutePath());
        }
        this.currentIndex = 0;
    }

    public void openZip(File zipFile) throws IOException, AppException {
        close();
        this.imageSource = new ZipImageSource(zipFile);
        this.imageNames = new ArrayList<>(imageSource.getImageNames());
        Collections.sort(this.imageNames, new NaturalOrderComparator());
        if (this.imageNames.isEmpty()) {
            throw new EmptyFolderException(zipFile.getAbsolutePath());
        }
        this.currentIndex = 0;
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

    public BufferedImage loadCurrentImage() throws IOException, AppException {
        if (!hasImages()) return null;
        String name = imageNames.get(currentIndex);
        try (InputStream inputStream = imageSource.open(name)) {
            BufferedImage img = ImageIO.read(inputStream);
            if (img == null) {
                throw new UnsupportedFormatException(name);
            }
            return img;
        }
    }

    public String getCurrentName() {
        if (!hasImages()) return null;
        return imageNames.get(currentIndex);
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

