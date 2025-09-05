package com.hippo.desktop;

public class AppException extends Exception {
    public AppException(String message) { super(message); }
}

class EmptyFolderException extends AppException {
    public EmptyFolderException(String path) { super("No supported images found in: " + path); }
}

class UnsupportedFormatException extends AppException {
    public UnsupportedFormatException(String name) { super("Unsupported or corrupted image: " + name); }
}