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

/**
 * UrlBuilder — convenience wrapper for building URLs with query parameters.
 *
 * Equivalent to OkHttp HttpUrl.Builder's query parameter methods.
 * Uses the standard URL/URLSearchParams API underneath.
 *
 * Usage:
 *   const url = new UrlBuilder('https://e-hentai.org/')
 *     .addQuery('f_search', 'artbook')
 *     .addQuery('page', '2')
 *     .build();
 *   // => 'https://e-hentai.org/?f_search=artbook&page=2'
 */
export class UrlBuilder {
  private base: string;
  private params: [string, string][] = [];

  constructor(base: string) {
    this.base = base;
  }

  /** Add a query parameter. */
  addQuery(key: string, value: string): UrlBuilder {
    this.params.push([key, value]);
    return this;
  }

  /** Add a query parameter only if value is non-null and non-empty. */
  addQueryIfNotEmpty(key: string, value: string | null | undefined): UrlBuilder {
    if (value != null && value.length > 0) {
      this.params.push([key, value]);
    }
    return this;
  }

  /** Add a numeric query parameter. */
  addQueryNumber(key: string, value: number): UrlBuilder {
    this.params.push([key, String(value)]);
    return this;
  }

  /** Build the final URL string. */
  build(): string {
    if (this.params.length === 0) {
      return this.base;
    }
    const encoded = this.params
      .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
      .join('&');
    const separator = this.base.includes('?') ? '&' : '?';
    return `${this.base}${separator}${encoded}`;
  }
}
