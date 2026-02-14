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
import com.hippo.ehviewer.htmlparser.impl.JsoupElement;
import com.hippo.ehviewer.htmlparser.impl.JsoupNode;
import org.jsoup.nodes.Node;
import org.jsoup.select.NodeTraversor;
import org.jsoup.select.NodeVisitor;

/**
 * Utility for depth-first traversal of the HTML node tree,
 * modeled after jsoup's {@code NodeTraversor}.
 */
public final class HNodeTraversor {

    private HNodeTraversor() {}

    /**
     * Perform a depth-first traversal on the given node, invoking the visitor callbacks.
     */
    public static void traverse(@NonNull HNodeVisitor visitor, @NonNull HNode root) {
        Node jsoupNode;
        if (root instanceof JsoupElement) {
            jsoupNode = ((JsoupElement) root).unwrap();
        } else if (root instanceof JsoupNode) {
            jsoupNode = ((JsoupNode) root).unwrap();
        } else {
            throw new IllegalArgumentException("HNodeTraversor only supports jsoup-backed nodes");
        }
        NodeTraversor.traverse(new NodeVisitor() {
            @Override
            public void head(Node node, int depth) {
                visitor.head(JsoupElement.wrapNode(node), depth);
            }

            @Override
            public void tail(Node node, int depth) {
                visitor.tail(JsoupElement.wrapNode(node), depth);
            }
        }, jsoupNode);
    }
}
