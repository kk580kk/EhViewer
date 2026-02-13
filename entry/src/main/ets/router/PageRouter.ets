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

  /** Sign-in page (username/password). */
  SIGN_IN: 'pages/SignInPage',

  /** Cookie-based sign-in page.  params: none */
  COOKIE_SIGN_IN: 'pages/CookieSignInPage',

  /** WebView-based sign-in page.  params: none */
  WEBVIEW_SIGN_IN: 'pages/WebViewSignInPage',
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

export interface LocalGalleryReaderParams {
  source: 'dir' | 'archive';
  path: string;
  page?: number;
  title?: string;
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
 * Optional navigator interface for actual routing.
 * Production code injects a real router; tests use the default no-op.
 */
export interface Navigator {
  pushUrl(url: string, params?: Record<string, Object>): void;
  replaceUrl(url: string, params?: Record<string, Object>): void;
  back(): void;
}

/** Default no-op navigator (safe for tests). */
const noopNavigator: Navigator = {
  pushUrl(_url: string, _params?: Record<string, Object>): void {},
  replaceUrl(_url: string, _params?: Record<string, Object>): void {},
  back(): void {},
};

/**
 * PageRouter — thin abstraction over @ohos.router.
 *
 * Call PageRouter.setNavigator() once at app startup to enable real routing.
 * Tests can call the static helpers directly — they always return a NavResult.
 */
export class PageRouter {
  private static nav: Navigator = noopNavigator;

  /** Inject the real navigator (call once from EntryAbility / Index). */
  static setNavigator(navigator: Navigator): void {
    PageRouter.nav = navigator;
  }

  /**
   * Navigate to the gallery detail page.
   */
  static toGalleryDetail(gid: number, token: string): NavResult {
    const result = buildNavResult(Routes.GALLERY_DETAIL, {
      gid: gid as Object,
      token: token as Object,
    });
    PageRouter.nav.pushUrl(result.url, result.params);
    return result;
  }

  /**
   * Navigate to the gallery reader page.
   */
  static toGalleryReader(gid: number, token: string, page: number = 0): NavResult {
    const result = buildNavResult(Routes.GALLERY_READER, {
      gid: gid as Object,
      token: token as Object,
      page: page as Object,
    });
    PageRouter.nav.pushUrl(result.url, result.params);
    return result;
  }

  /** Navigate to the main page (replace mode). */
  static toMain(): NavResult {
    const result = buildNavResult(Routes.MAIN);
    PageRouter.nav.replaceUrl(result.url, result.params);
    return result;
  }

  /** Navigate to the sign-in page (username/password). */
  static toSignIn(): NavResult {
    const result = buildNavResult(Routes.SIGN_IN);
    PageRouter.nav.pushUrl(result.url, result.params);
    return result;
  }

  /** Navigate to the cookie sign-in page. */
  static toCookieSignIn(): NavResult {
    const result = buildNavResult(Routes.COOKIE_SIGN_IN);
    PageRouter.nav.pushUrl(result.url, result.params);
    return result;
  }

  /** Navigate to the WebView sign-in page. */
  static toWebViewSignIn(): NavResult {
    const result = buildNavResult(Routes.WEBVIEW_SIGN_IN);
    PageRouter.nav.pushUrl(result.url, result.params);
    return result;
  }

  /**
   * Navigate to the local gallery reader page (directory or archive).
   */
  static toLocalGalleryReader(
    source: 'dir' | 'archive',
    path: string,
    page: number = 0,
    title: string = '',
  ): NavResult {
    const result = buildNavResult(Routes.GALLERY_READER, {
      source: source as Object,
      path: path as Object,
      page: page as Object,
      title: title as Object,
    });
    PageRouter.nav.pushUrl(result.url, result.params);
    return result;
  }

  /** Go back to previous page. */
  static goBack(): void {
    PageRouter.nav.back();
  }
}
