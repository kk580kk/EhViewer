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
import com.hippo.ehviewer.htmlparser.HNode;
import org.jsoup.nodes.Node;

/**
 * Wraps a jsoup {@link Node} that is <em>not</em> an {@code Element} into
 * the read-only {@link HNode} interface (e.g. text nodes, comment nodes).
 */
public final class JsoupNode implements HNode {

    private final Node node;

    public JsoupNode(@NonNull Node node) {
        this.node = node;
    }

    /** Unwrap the underlying jsoup Node. */
    @NonNull
    public Node unwrap() {
        return node;
    }

    @Override
    @NonNull
    public String nodeName() {
        return node.nodeName();
    }

    @Override
    public boolean isElement() {
        return false;
    }

    @Override
    @Nullable
    public HElement asElement() {
        return null;
    }
}
