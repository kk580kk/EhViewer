package com.hippo.dao;

import android.database.Cursor;

import java.io.Closeable;
import java.io.IOException;
import java.util.AbstractList;
import java.util.NoSuchElementException;

/**
 * A list backed by a database Cursor that loads entities on demand.
 * Must be closed after use to release the cursor.
 * Mirrors greenDAO's LazyList.
 */
public class LazyList<T> extends AbstractList<T> implements Closeable {

    private final AbstractDao<T, ?> dao;
    private final Cursor cursor;
    private final Object[] entities;
    private final int size;
    private volatile boolean closed;

    LazyList(AbstractDao<T, ?> dao, Cursor cursor) {
        this.dao = dao;
        this.cursor = cursor;
        this.size = cursor.getCount();
        this.entities = new Object[size];
    }

    @Override
    public T get(int index) {
        if (index < 0 || index >= size) {
            throw new IndexOutOfBoundsException("Index: " + index + ", Size: " + size);
        }
        @SuppressWarnings("unchecked")
        T cached = (T) entities[index];
        if (cached != null) {
            return cached;
        }
        synchronized (this) {
            @SuppressWarnings("unchecked")
            T doubleCheck = (T) entities[index];
            if (doubleCheck != null) {
                return doubleCheck;
            }
            if (closed) {
                throw new IllegalStateException("LazyList is closed");
            }
            cursor.moveToPosition(index);
            T entity = dao.readEntity(cursor, 0);
            entities[index] = entity;
            return entity;
        }
    }

    @Override
    public int size() {
        return size;
    }

    public boolean isClosed() {
        return closed;
    }

    @Override
    public void close() {
        synchronized (this) {
            if (!closed) {
                closed = true;
                cursor.close();
            }
        }
    }

    /**
     * Returns a closeable list iterator over this lazy list.
     */
    public CloseableListIterator<T> listIterator() {
        return new LazyListIterator();
    }

    private class LazyListIterator implements CloseableListIterator<T> {
        private int index = 0;

        @Override
        public boolean hasNext() {
            return index < size;
        }

        @Override
        public T next() {
            if (!hasNext()) throw new NoSuchElementException();
            return get(index++);
        }

        @Override
        public boolean hasPrevious() {
            return index > 0;
        }

        @Override
        public T previous() {
            if (!hasPrevious()) throw new NoSuchElementException();
            return get(--index);
        }

        @Override
        public int nextIndex() {
            return index;
        }

        @Override
        public int previousIndex() {
            return index - 1;
        }

        @Override
        public void remove() {
            throw new UnsupportedOperationException();
        }

        @Override
        public void set(T t) {
            throw new UnsupportedOperationException();
        }

        @Override
        public void add(T t) {
            throw new UnsupportedOperationException();
        }

        @Override
        public void close() throws IOException {
            LazyList.this.close();
        }
    }
}
