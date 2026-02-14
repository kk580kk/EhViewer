/*
 * Copyright 2016 Hippo Seven
 * Ported to HarmonyOS ArkTS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import type { HDocument, HElement, HElements } from '../htmlparser/HtmlTypes.ets';

/**
 * JsoupUtils — convenience wrappers for querying HTML elements.
 *
 * Port of Android com.hippo.util.JsoupUtils.
 * Works with the HElement / HDocument interfaces from HtmlTypes.ets
 * (which mirror the jsoup API).
 *
 * Platform difference:
 *   Android uses jsoup's Document/Element directly. HarmonyOS uses the
 *   HDocument/HElement interfaces defined in HtmlTypes.ets, which provide
 *   the same query methods. Behaviour is identical.
 */
export class JsoupUtils {
  private constructor() {}

  /**
   * Get the first element matching the given class name from a document.
   * Returns null if no match is found.
   */
  static getElementByClassFromDoc(doc: HDocument, className: string): HElement | null {
    const elements: HElements = doc.getElementsByClass(className);
    if (elements.size() > 0) {
      return elements.get(0);
    }
    return null;
  }

  /**
   * Get the first element matching the given class name from an element.
   * Returns null if no match is found.
   */
  static getElementByClass(element: HElement, className: string): HElement | null {
    const elements: HElements = element.getElementsByClass(className);
    if (elements.size() > 0) {
      return elements.get(0);
    }
    return null;
  }

  /**
   * Get the first element matching the given tag name from an element.
   * Returns null if no match is found.
   */
  static getElementByTag(element: HElement, tagName: string): HElement | null {
    const elements: HElements = element.getElementsByTag(tagName);
    if (elements.size() > 0) {
      return elements.get(0);
    }
    return null;
  }
}
