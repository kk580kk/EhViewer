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
 * HtmlUtils — lightweight HTML-to-text conversion for ArkTS.
 *
 * Equivalent to Android's Html.fromHtml / URLImageGetter / LinkMovementMethod.
 * Provides utilities for:
 *  - Stripping HTML tags to plain text
 *  - Extracting links from HTML
 *  - Decoding HTML entities
 *  - Extracting image URLs from <img> tags
 *
 * Used by gallery detail, comment display, and rich-text rendering.
 */

/** Represents a hyperlink extracted from HTML. */
export class HtmlLink {
  text: string;
  url: string;

  constructor(text: string, url: string) {
    this.text = text;
    this.url = url;
  }
}

/** Represents an image reference extracted from HTML. */
export class HtmlImage {
  src: string;
  alt: string;

  constructor(src: string, alt: string = '') {
    this.src = src;
    this.alt = alt;
  }
}

/** Common HTML entity map. */
const ENTITY_MAP: Record<string, string> = {
  '&amp;': '&',
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&#39;': "'",
  '&apos;': "'",
  '&nbsp;': ' ',
  '&hellip;': '\u2026',
  '&mdash;': '\u2014',
  '&ndash;': '\u2013',
  '&laquo;': '\u00AB',
  '&raquo;': '\u00BB',
  '&copy;': '\u00A9',
  '&reg;': '\u00AE',
  '&trade;': '\u2122',
};

export class HtmlUtils {
  /**
   * Strip all HTML tags and return plain text.
   * Converts <br> / <br/> to newlines. Decodes common entities.
   */
  static stripHtml(html: string): string {
    if (html.length === 0) return '';

    let text = html;
    // Convert <br> tags to newlines
    text = text.replace(/<br\s*\/?>/gi, '\n');
    // Convert <p> and </p> to paragraph breaks
    text = text.replace(/<\/p>/gi, '\n\n');
    text = text.replace(/<p[^>]*>/gi, '');
    // Remove all remaining HTML tags
    text = text.replace(/<[^>]+>/g, '');
    // Decode entities
    text = HtmlUtils.decodeEntities(text);
    // Collapse multiple blank lines
    text = text.replace(/\n{3,}/g, '\n\n');
    return text.trim();
  }

  /**
   * Decode HTML entities in a string.
   * Handles named entities and numeric character references (&#NNN; and &#xHHH;).
   */
  static decodeEntities(text: string): string {
    let result = text;
    // Named entities
    for (const entity of Object.keys(ENTITY_MAP)) {
      result = result.split(entity).join(ENTITY_MAP[entity]);
    }
    // Decimal numeric references: &#NNN;
    result = result.replace(/&#(\d+);/g, (_match: string, num: string) => {
      return String.fromCharCode(parseInt(num, 10));
    });
    // Hex numeric references: &#xHHH;
    result = result.replace(/&#x([0-9a-fA-F]+);/g, (_match: string, hex: string) => {
      return String.fromCharCode(parseInt(hex, 16));
    });
    return result;
  }

  /**
   * Extract all hyperlinks (<a href="...">) from HTML.
   * Returns an array of HtmlLink objects.
   */
  static extractLinks(html: string): HtmlLink[] {
    const links: HtmlLink[] = [];
    const regex = /<a[^>]+href=["']([^"']*)["'][^>]*>([\s\S]*?)<\/a>/gi;
    let match: RegExpExecArray | null;
    while ((match = regex.exec(html)) !== null) {
      const url = match[1];
      const text = HtmlUtils.stripHtml(match[2]);
      links.push(new HtmlLink(text, url));
    }
    return links;
  }

  /**
   * Extract all image URLs (<img src="...">) from HTML.
   * Returns an array of HtmlImage objects.
   */
  static extractImages(html: string): HtmlImage[] {
    const images: HtmlImage[] = [];
    const regex = /<img[^>]+src=["']([^"']*)["'][^>]*>/gi;
    let match: RegExpExecArray | null;
    while ((match = regex.exec(html)) !== null) {
      const src = match[1];
      // Try to extract alt text
      const altMatch = match[0].match(/alt=["']([^"']*)["']/i);
      const alt = altMatch ? altMatch[1] : '';
      images.push(new HtmlImage(src, alt));
    }
    return images;
  }

  /**
   * Escape special HTML characters in plain text.
   * Useful when inserting user-provided text into HTML context.
   */
  static escapeHtml(text: string): string {
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  /**
   * Truncate HTML-stripped text to a maximum length,
   * appending '...' if truncated.
   */
  static truncate(text: string, maxLength: number): string {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength).trimEnd() + '\u2026';
  }
}
