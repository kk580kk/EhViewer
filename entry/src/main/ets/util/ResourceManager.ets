/*
 * Copyright 2016 Hippo Seven
 * Ported to HarmonyOS ArkTS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Platform differences:
 *   Android DrawableManager: Loads vector drawables via VectorDrawableCompat
 *     on pre-Lollipop, and Resources.getDrawable() on API 21+. Returns an
 *     Android Drawable instance.
 *   HarmonyOS ResourceManager: Resources are loaded via
 *     resourceManager.getMediaContentSync / $r('app.media.xxx'). No SDK
 *     version compat layer is needed since HarmonyOS has a single resource
 *     API. This utility provides a consistent abstraction with tinting
 *     support and resource ID validation.
 */

import { Logger } from './Logger.ets';

const log = Logger.tag('ResourceManager');

// ---- Resource descriptor ----

/**
 * A loaded resource descriptor. In HarmonyOS, resources are referenced
 * by name and type rather than integer IDs. This interface provides
 * a uniform representation.
 */
export interface ResourceDescriptor {
  /** Resource name (e.g. 'ic_launcher'). */
  name: string;
  /** Resource type ('media', 'rawfile', 'string', etc.). */
  type: string;
  /** Raw byte data if the resource was loaded as binary. */
  data?: Uint8Array;
  /** String content if the resource was loaded as text. */
  text?: string;
}

/**
 * Tint specification for applying color to a resource.
 */
export interface TintSpec {
  /** Color as a 32-bit ARGB integer (e.g. 0xFF00FF00 for green). */
  color: number;
}

// ---- Abstraction over resource access ----

/**
 * Abstraction over HarmonyOS resourceManager for loading resources.
 *
 * Production: wraps getContext().resourceManager.
 * Tests: supply a mock implementation.
 */
export interface ResourceProvider {
  /**
   * Load a media resource by name.
   * Returns the raw bytes, or null if not found.
   */
  getMediaContent(name: string): Uint8Array | null;

  /**
   * Load a string resource by name.
   * Returns the string, or null if not found.
   */
  getString(name: string): string | null;

  /**
   * Check if a resource exists.
   */
  hasResource(name: string, type: string): boolean;
}

// ---- ResourceManager ----

/**
 * ResourceManager — utility for loading and managing resources in HarmonyOS.
 *
 * Equivalent to Android's DrawableManager, providing:
 *  - Resource loading by name
 *  - Tint color application tracking
 *  - Resource existence checking
 *  - Simple LRU-style caching for loaded resources
 */
export class ResourceManager {
  private provider: ResourceProvider;
  private cache: Map<string, ResourceDescriptor> = new Map();
  private tints: Map<string, TintSpec> = new Map();
  private readonly maxCacheSize: number;

  constructor(provider: ResourceProvider, maxCacheSize: number = 64) {
    this.provider = provider;
    this.maxCacheSize = maxCacheSize;
  }

  /**
   * Load a media resource (image/icon) by name.
   * Results are cached for subsequent calls.
   *
   * @param name - resource name (e.g. 'ic_search')
   * @returns ResourceDescriptor or null if not found
   */
  getMedia(name: string): ResourceDescriptor | null {
    const key = `media:${name}`;
    const cached = this.cache.get(key);
    if (cached !== undefined) {
      return cached;
    }

    try {
      const data = this.provider.getMediaContent(name);
      if (data === null) {
        log.w(`Media resource not found: ${name}`);
        return null;
      }

      const desc: ResourceDescriptor = { name, type: 'media', data };
      this.putCache(key, desc);
      return desc;
    } catch (e) {
      log.e(`Failed to load media: ${name}`, e instanceof Error ? e : new Error(String(e)));
      return null;
    }
  }

  /**
   * Load a media resource with a tint color specification.
   * The tint information is stored alongside the resource so the
   * rendering layer can apply it.
   *
   * @param name - resource name
   * @param tint - tint color specification
   * @returns ResourceDescriptor or null if not found
   */
  getMediaWithTint(name: string, tint: TintSpec): ResourceDescriptor | null {
    const desc = this.getMedia(name);
    if (desc !== null) {
      this.tints.set(name, tint);
    }
    return desc;
  }

  /**
   * Get the tint specification for a previously loaded resource.
   * Returns null if no tint was applied.
   */
  getTint(name: string): TintSpec | null {
    return this.tints.get(name) ?? null;
  }

  /**
   * Load a string resource by name.
   *
   * @param name - resource name (e.g. 'app_name')
   * @returns the string, or null if not found
   */
  getString(name: string): string | null {
    try {
      return this.provider.getString(name);
    } catch (e) {
      log.e(`Failed to load string: ${name}`, e instanceof Error ? e : new Error(String(e)));
      return null;
    }
  }

  /**
   * Check whether a resource exists.
   *
   * @param name - resource name
   * @param type - resource type ('media', 'string', etc.)
   */
  hasResource(name: string, type: string = 'media'): boolean {
    try {
      return this.provider.hasResource(name, type);
    } catch (_e) {
      return false;
    }
  }

  /** Clear the resource cache. */
  clearCache(): void {
    this.cache.clear();
    this.tints.clear();
  }

  /** Number of cached resources. */
  getCacheSize(): number {
    return this.cache.size;
  }

  // ---- Internal ----

  private putCache(key: string, desc: ResourceDescriptor): void {
    // Simple eviction: remove oldest entries when over limit
    if (this.cache.size >= this.maxCacheSize) {
      const firstKey = this.cache.keys().next().value;
      if (firstKey !== undefined) {
        this.cache.delete(firstKey);
      }
    }
    this.cache.set(key, desc);
  }
}
