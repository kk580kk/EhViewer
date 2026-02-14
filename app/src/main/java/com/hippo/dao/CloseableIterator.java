package com.hippo.dao;

import java.io.Closeable;
import java.util.Iterator;

/**
 * An iterator that holds a Cursor resource and must be closed after use.
 */
public interface CloseableIterator<T> extends Iterator<T>, Closeable {
}
