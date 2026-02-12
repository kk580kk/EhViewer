/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * TextUrl — URL detection and text segmentation for ArkTS.
 *
 * Port of Android com.hippo.util.TextUrl.
 * Since ArkTS has no Spannable/URLSpan, this utility parses text into
 * segments (plain text vs. clickable URL) that UI components can render.
 */

/** A segment of text — either plain text or a URL. */
export interface TextSegment {
  /** The text content of this segment. */
  text: string;
  /** If this segment is a URL, the URL string; otherwise undefined. */
  url?: string;
}

/** A single URL match within text. */
export interface UrlMatch {
  /** The matched URL string. */
  url: string;
  /** Start index in the source text (inclusive). */
  start: number;
  /** End index in the source text (exclusive). */
  end: number;
}

/**
 * URL pattern matching http/https URLs.
 * Equivalent to the Java URL_PATTERN in com.hippo.util.TextUrl.
 */
const URL_PATTERN =
  /(https?):\/\/[a-z0-9A-Z%-]+(\.[a-z0-9A-Z%-]+)+(:\d{1,5})?(\/[a-zA-Z0-9\-_~:#@!&',;=%\/\*\.\?\+\$\[\]\(\)]+)?\/?/g;

export class TextUrl {
  /**
   * Find all URL matches in the given text.
   */
  static findUrls(text: string): UrlMatch[] {
    const matches: UrlMatch[] = [];
    const regex = new RegExp(URL_PATTERN.source, 'g');
    let m: RegExpExecArray | null;
    while ((m = regex.exec(text)) !== null) {
      matches.push({
        url: m[0],
        start: m.index,
        end: m.index + m[0].length,
      });
    }
    return matches;
  }

  /**
   * Parse text into an array of TextSegments.
   *
   * Plain-text portions become segments without a url field;
   * detected URLs become segments with url set.
   *
   * If `existingUrls` is provided, any URL range that overlaps with
   * an existing URL range will be skipped (mirrors the Java behaviour
   * of skipping regions already covered by URLSpan).
   */
  static handleTextUrl(text: string, existingUrls?: UrlMatch[]): TextSegment[] {
    if (text.length === 0) {
      return [];
    }

    const detected = TextUrl.findUrls(text);
    if (detected.length === 0) {
      return [{ text }];
    }

    // Filter out URLs that overlap with already-linked regions
    const urls = existingUrls
      ? detected.filter(d => !existingUrls.some(e => d.start < e.end && d.end > e.start))
      : detected;

    if (urls.length === 0) {
      return [{ text }];
    }

    const segments: TextSegment[] = [];
    let cursor = 0;

    for (const match of urls) {
      // Plain text before this URL
      if (match.start > cursor) {
        segments.push({ text: text.substring(cursor, match.start) });
      }
      // The URL segment
      segments.push({ text: match.url, url: match.url });
      cursor = match.end;
    }

    // Trailing plain text
    if (cursor < text.length) {
      segments.push({ text: text.substring(cursor) });
    }

    return segments;
  }

  /**
   * Convenience: check whether text contains at least one URL.
   */
  static containsUrl(text: string): boolean {
    const regex = new RegExp(URL_PATTERN.source, 'g');
    return regex.test(text);
  }
}
