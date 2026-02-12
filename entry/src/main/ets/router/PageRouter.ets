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
 * Centralised page routing utility for EhViewer HarmonyOS.
 *
 * Wraps @ohos.router to provide:
 *  - typed route constants
 *  - helper methods for common navigation patterns (push / replace / back)
 *  - parameter passing via a plain Record
 */

/** All page route paths used in the application. */
export const Routes = {
  /** Main entry page with bottom tab navigation. */
  MAIN: 'pages/Index',

  /** Gallery detail page.  params: { gid: number, token: string } */
  GALLERY_DETAIL: 'pages/GalleryDetailPage',

  /** Gallery reader / viewer page.  params: { gid: number, token: string, page?: number } */
  GALLERY_READER: 'pages/GalleryReaderPage',
} as const;

export type RoutePath = (typeof Routes)[keyof typeof Routes];

/** Typed parameter maps for each route (optional — for documentation). */
export interface GalleryDetailParams {
  gid: number;
  token: string;
}

export interface GalleryReaderParams {
  gid: number;
  token: string;
  page?: number;
}

/** Lightweight navigation result for tests / call-site inspection. */
export interface NavResult {
  url: string;
  params: Record<string, Object> | undefined;
}

/**
 * Build a NavResult (used by tests and by the actual navigate* helpers).
 * Pure function — no side effects.
 */
export function buildNavResult(url: string, params?: Record<string, Object>): NavResult {
  return { url, params };
}

/**
 * PageRouter — thin abstraction over @ohos.router.
 *
 * UI code should call the static helpers; tests can call buildNavResult
 * directly to validate parameter building without pulling in the router.
 */
export class PageRouter {
  /**
   * Navigate to the gallery detail page.
   * Returns a NavResult describing the intended navigation.
   */
  static toGalleryDetail(gid: number, token: string): NavResult {
    return buildNavResult(Routes.GALLERY_DETAIL, {
      gid: gid as Object,
      token: token as Object,
    });
  }

  /**
   * Navigate to the gallery reader page.
   * Returns a NavResult describing the intended navigation.
   */
  static toGalleryReader(gid: number, token: string, page: number = 0): NavResult {
    return buildNavResult(Routes.GALLERY_READER, {
      gid: gid as Object,
      token: token as Object,
      page: page as Object,
    });
  }

  /**
   * Build a NavResult to go back to the main page (replace mode).
   */
  static toMain(): NavResult {
    return buildNavResult(Routes.MAIN);
  }
}
