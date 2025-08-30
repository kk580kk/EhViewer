package com.hippo.desktop;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;

public interface ImageSource extends AutoCloseable {
    List<String> getImageNames() throws IOException;
    InputStream open(String name) throws IOException;
    @Override
    void close() throws IOException;
}

