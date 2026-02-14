package com.hippo.dao;

import java.io.Closeable;
import java.util.ListIterator;

/**
 * A ListIterator that holds a Cursor resource and must be closed after use.
 * Mirrors greenDAO's CloseableListIterator.
 */
public interface CloseableListIterator<T> extends ListIterator<T>, Closeable {
}
