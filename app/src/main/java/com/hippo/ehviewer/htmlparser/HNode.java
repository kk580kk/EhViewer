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
 * Read-only abstraction for an HTML node, modeled after jsoup's {@code Node}.
 * Serves as the base type for {@link HElement}.
 */
public interface HNode {

    /**
     * Get the node name (e.g. "#text" for text nodes, tag name for elements).
     */
    @NonNull
    String nodeName();

    /**
     * Return {@code true} if this node is an element node.
     */
    boolean isElement();

    /**
     * Cast this node to {@link HElement}, or {@code null} if it is not an element.
     */
    @Nullable
    HElement asElement();
}
