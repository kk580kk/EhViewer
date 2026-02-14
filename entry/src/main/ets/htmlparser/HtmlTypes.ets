/*
 * Copyright 2024 EhViewer Contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * Read-only interfaces modeled after jsoup's Document / Element / Elements API,
 * so that parsers can be migrated from jsoup without changing call-site code style.
 */

/** Base node type (text nodes, element nodes). */
export interface HNode {
  nodeName(): string;
  isElement(): boolean;
  asElement(): HElement | null;
}

/** Read-only element, mirrors jsoup Element. */
export interface HElement extends HNode {
  // ---- Query ----
  getElementById(id: string): HElement | null;
  getElementsByClass(className: string): HElements;
  getElementsByTag(tagName: string): HElements;
  select(cssQuery: string): HElements;

  // ---- Traversal ----
  children(): HElements;
  child(index: number): HElement;
  parent(): HElement | null;
  previousElementSibling(): HElement | null;
  nextElementSibling(): HElement | null;

  // ---- Properties ----
  tagName(): string;
  text(): string;
  ownText(): string;
  html(): string;
  attr(key: string): string;
  hasClass(className: string): boolean;
  hasAttr(key: string): boolean;
}

/** Read-only element list, mirrors jsoup Elements. */
export interface HElements extends Iterable<HElement> {
  get(index: number): HElement;
  size(): number;
  first(): HElement | null;
  last(): HElement | null;
  isEmpty(): boolean;
  text(): string;
  attr(key: string): string;
}

/** Parsed HTML document. Extends HElement since jsoup Document is an Element. */
export interface HDocument extends HElement {}

/** Visitor for depth-first node tree traversal. */
export interface HNodeVisitor {
  head(node: HNode, depth: number): void;
  tail(node: HNode, depth: number): void;
}
