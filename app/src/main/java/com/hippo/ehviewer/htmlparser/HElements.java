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
 * Read-only abstraction for a list of HTML elements, modeled after jsoup's {@code Elements}.
 * <p>
 * Supports the subset of jsoup's Elements API used by the parsers:
 * {@code get}, {@code size}, {@code first}, {@code isEmpty}, and {@code Iterable}.
 */
public interface HElements extends Iterable<HElement> {

    /** Get the element at the specified index (0-based). */
    @NonNull
    HElement get(int index);

    /** Get the number of elements in this list. */
    int size();

    /** Get the first element, or {@code null} if the list is empty. */
    @Nullable
    HElement first();

    /** Return {@code true} if the list contains no elements. */
    boolean isEmpty();

    /** Get the last element, or {@code null} if the list is empty. */
    @Nullable
    HElement last();

    /** Get the combined text of all matched elements. */
    @NonNull
    String text();

    /** Get the attribute value of the first matched element, or empty string if none. */
    @NonNull
    String attr(@NonNull String key);
}
