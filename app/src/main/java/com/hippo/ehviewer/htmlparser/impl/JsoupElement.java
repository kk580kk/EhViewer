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
import com.hippo.ehviewer.htmlparser.HNode;
import org.jsoup.nodes.Element;
import org.jsoup.nodes.Node;

/**
 * Wraps a jsoup {@link Element} into the read-only {@link HElement} interface.
 */
public class JsoupElement implements HElement {

    private final Element element;

    public JsoupElement(@NonNull Element element) {
        this.element = element;
    }

    /** Unwrap the underlying jsoup Element (also works as Node). */
    @NonNull
    public Element unwrap() {
        return element;
    }

    /**
     * Wrap a jsoup {@link Node} into the appropriate adapter type.
     * Returns {@link JsoupElement} for Element nodes, {@link JsoupNode} for others.
     */
    @NonNull
    public static HNode wrapNode(@NonNull Node node) {
        if (node instanceof Element) {
            return new JsoupElement((Element) node);
        }
        return new JsoupNode(node);
    }

    @Nullable
    static JsoupElement wrapNullable(@Nullable Element element) {
        return element != null ? new JsoupElement(element) : null;
    }

    // ---- HNode methods ----

    @Override
    @NonNull
    public String nodeName() {
        return element.nodeName();
    }

    @Override
    public boolean isElement() {
        return true;
    }

    @Override
    @NonNull
    public HElement asElement() {
        return this;
    }

    // ---- Query methods ----

    @Override
    @Nullable
    public HElement getElementById(@NonNull String id) {
        Element found = element.getElementById(id);
        return wrapNullable(found);
    }

    @Override
    @NonNull
    public HElements getElementsByClass(@NonNull String className) {
        return new JsoupElements(element.getElementsByClass(className));
    }

    @Override
    @NonNull
    public HElements getElementsByTag(@NonNull String tagName) {
        return new JsoupElements(element.getElementsByTag(tagName));
    }

    @Override
    @NonNull
    public HElements select(@NonNull String cssQuery) {
        return new JsoupElements(element.select(cssQuery));
    }

    // ---- Child / sibling traversal ----

    @Override
    @NonNull
    public HElements children() {
        return new JsoupElements(element.children());
    }

    @Override
    @NonNull
    public HElement child(int index) {
        return new JsoupElement(element.child(index));
    }

    @Override
    @Nullable
    public HElement parent() {
        Element p = element.parent();
        return wrapNullable(p);
    }

    @Override
    @Nullable
    public HElement previousElementSibling() {
        Element prev = element.previousElementSibling();
        return wrapNullable(prev);
    }

    @Override
    @Nullable
    public HElement nextElementSibling() {
        Element next = element.nextElementSibling();
        return wrapNullable(next);
    }

    // ---- Properties ----

    @Override
    @NonNull
    public String tagName() {
        return element.tagName();
    }

    @Override
    @NonNull
    public String text() {
        return element.text();
    }

    @Override
    @NonNull
    public String ownText() {
        return element.ownText();
    }

    @Override
    @NonNull
    public String html() {
        return element.html();
    }

    @Override
    @NonNull
    public String attr(@NonNull String key) {
        return element.attr(key);
    }

    @Override
    public boolean hasClass(@NonNull String className) {
        return element.hasClass(className);
    }

    @Override
    public boolean hasAttr(@NonNull String key) {
        return element.hasAttr(key);
    }
}
