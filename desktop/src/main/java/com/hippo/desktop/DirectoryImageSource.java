package com.hippo.desktop;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class DirectoryImageSource implements ImageSource {

    private final File rootDirectory;
    private final List<String> imagePaths;

    public DirectoryImageSource(File rootDirectory) throws IOException {
        if (rootDirectory == null || !rootDirectory.isDirectory()) {
            throw new IOException("Not a directory: " + rootDirectory);
        }
        this.rootDirectory = rootDirectory.getCanonicalFile();
        this.imagePaths = scanImages(this.rootDirectory);
    }

    private static List<String> scanImages(File root) throws IOException {
        try (Stream<Path> stream = Files.walk(root.toPath())) {
            List<String> list = stream
                .filter(Files::isRegularFile)
                .map(Path::toFile)
                .filter(DirectoryImageSource::isSupportedImage)
                .map(file -> root.toPath().relativize(file.toPath()).toString())
                .collect(Collectors.toCollection(ArrayList::new));
            return list;
        }
    }

    private static boolean isSupportedImage(File file) {
        String name = file.getName().toLowerCase(Locale.ROOT);
        return name.endsWith(".jpg") || name.endsWith(".jpeg") || name.endsWith(".png") || 
               name.endsWith(".gif") || name.endsWith(".bmp") || name.endsWith(".webp") ||
               name.endsWith(".tiff") || name.endsWith(".tif");
    }

    @Override
    public List<String> getImageNames() {
        return new ArrayList<>(imagePaths);
    }

    @Override
    public InputStream open(String name) throws IOException {
        File file = new File(rootDirectory, name);
        return new FileInputStream(file);
    }

    @Override
    public void close() {
        // nothing to close for directory
    }
}

