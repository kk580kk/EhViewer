/*
 * Copyright 2024 EhViewer Contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.hippo.ehviewer.htmlparser.impl;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import com.hippo.ehviewer.htmlparser.HElement;
import com.hippo.ehviewer.htmlparser.HElements;
import java.util.Iterator;
import java.util.NoSuchElementException;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

/**
 * Wraps a jsoup {@link Elements} into the read-only {@link HElements} interface.
 */
public final class JsoupElements implements HElements {

    private final Elements elements;

    public JsoupElements(@NonNull Elements elements) {
        this.elements = elements;
    }

    @Override
    @NonNull
    public HElement get(int index) {
        return new JsoupElement(elements.get(index));
    }

    @Override
    public int size() {
        return elements.size();
    }

    @Override
    @Nullable
    public HElement first() {
        Element f = elements.first();
        return f != null ? new JsoupElement(f) : null;
    }

    @Override
    public boolean isEmpty() {
        return elements.isEmpty();
    }

    @Override
    @Nullable
    public HElement last() {
        Element l = elements.last();
        return l != null ? new JsoupElement(l) : null;
    }

    @Override
    @NonNull
    public String text() {
        return elements.text();
    }

    @Override
    @NonNull
    public String attr(@NonNull String key) {
        return elements.attr(key);
    }

    @Override
    @NonNull
    public Iterator<HElement> iterator() {
        return new Iterator<HElement>() {
            private final Iterator<Element> inner = elements.iterator();

            @Override
            public boolean hasNext() {
                return inner.hasNext();
            }

            @Override
            public HElement next() {
                if (!inner.hasNext()) {
                    throw new NoSuchElementException();
                }
                return new JsoupElement(inner.next());
            }
        };
    }
}
