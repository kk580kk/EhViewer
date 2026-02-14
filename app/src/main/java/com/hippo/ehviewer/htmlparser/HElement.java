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

package com.hippo.ehviewer.htmlparser;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

/**
 * Read-only abstraction for an HTML element, modeled after jsoup's {@code Element}.
 * <p>
 * Provides the subset of jsoup's Element API that is actually used by the parsers,
 * making it easy to swap the underlying HTML parser implementation.
 */
public interface HElement extends HNode {

    // ---- Query methods ----

    /** Find an element by its id attribute. */
    @Nullable
    HElement getElementById(@NonNull String id);

    /** Find elements that have the given class name. */
    @NonNull
    HElements getElementsByClass(@NonNull String className);

    /** Find elements by tag name (case-insensitive). */
    @NonNull
    HElements getElementsByTag(@NonNull String tagName);

    /** Find elements matching a CSS query selector. */
    @NonNull
    HElements select(@NonNull String cssQuery);

    // ---- Child / sibling traversal ----

    /** Get all direct child elements. */
    @NonNull
    HElements children();

    /** Get the nth direct child element (0-based). */
    @NonNull
    HElement child(int index);

    /** Get this element's parent element. */
    @Nullable
    HElement parent();

    /** Get the previous sibling element. */
    @Nullable
    HElement previousElementSibling();

    /** Get the next sibling element. */
    @Nullable
    HElement nextElementSibling();

    // ---- Properties ----

    /** Get the tag name of this element (e.g. "div", "a"). */
    @NonNull
    String tagName();

    /** Get the combined text of this element and all its children. */
    @NonNull
    String text();

    /** Get only the text directly owned by this element (not children). */
    @NonNull
    String ownText();

    /** Get the inner HTML of this element. */
    @NonNull
    String html();

    /** Get the value of an attribute by its key. Returns empty string if not present. */
    @NonNull
    String attr(@NonNull String key);

    /** Test whether this element has the specified class. */
    boolean hasClass(@NonNull String className);

    /** Test whether this element has an attribute with the given key. */
    boolean hasAttr(@NonNull String key);
}
