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

import type { PreferencesStore } from '../preferences/PreferencesStore.ets';
import { MemoryPreferencesStore } from '../preferences/MemoryPreferencesStore.ets';

/** Gallery site: 0 = E-Hentai, 1 = ExHentai */
const SITE_E = 0;

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

// ---- Preference keys ----
const KEY_GALLERY_SITE = 'gallery_site';
const KEY_SHOW_JPN_TITLE = 'show_jpn_title';
const KEY_THUMB_RESOLUTION = 'thumb_resolution';
const KEY_MULTI_THREAD_DOWNLOAD = 'download_thread';
const KEY_CONCURRENT_DOWNLOAD_LIMIT = 'concurrent_download_limit';
const KEY_PRELOAD_IMAGE = 'preload_image';
const KEY_DOWNLOAD_ORIGIN_IMAGE = 'download_origin_image';
const KEY_READ_CACHE_SIZE = 'read_cache_size';
const KEY_DOWNLOAD_LOCATION = 'download_location';
const KEY_NEED_SIGN_IN = 'need_sign_in';
const KEY_DISPLAY_NAME = 'display_name';
const KEY_AVATAR = 'avatar';
const KEY_SHOW_GALLERY_PAGES = 'show_gallery_pages';
const KEY_FIX_THUMB_URL = 'fix_thumb_url';
const KEY_SAVE_PARSE_ERROR_BODY = 'save_parse_error_body';
const KEY_SECURITY = 'security';
const KEY_ENABLE_FINGERPRINT = 'enable_fingerprint';
const KEY_ENABLED_SECURITY = 'enable_secure';

export class SettingsService {
  private static store: PreferencesStore = new MemoryPreferencesStore();

  /**
   * Initialize with a PreferencesStore implementation.
   * In production, pass an OhosPreferencesStore backed by @ohos.data.preferences.
   * For tests, pass a MemoryPreferencesStore (or call resetDefaults).
   */
  static initialize(store: PreferencesStore): void {
    SettingsService.store = store;
  }

  /** Returns the underlying store for direct access if needed. */
  static getStore(): PreferencesStore {
    return SettingsService.store;
  }

  // ---- Gallery ----

  static getGallerySite(): number {
    return SettingsService.store.getNumber(KEY_GALLERY_SITE, SITE_E);
  }

  static setGallerySite(site: number): void {
    SettingsService.store.putNumber(KEY_GALLERY_SITE, site);
  }

  static getShowJpnTitle(): boolean {
    return SettingsService.store.getBoolean(KEY_SHOW_JPN_TITLE, false);
  }

  static setShowJpnTitle(show: boolean): void {
    SettingsService.store.putBoolean(KEY_SHOW_JPN_TITLE, show);
  }

  static getThumbResolution(): number {
    return SettingsService.store.getNumber(KEY_THUMB_RESOLUTION, 0);
  }

  static setThumbResolution(resolution: number): void {
    SettingsService.store.putNumber(KEY_THUMB_RESOLUTION, resolution);
  }

  // ---- Download ----

  static getMultiThreadDownload(): number {
    return clamp(SettingsService.store.getNumber(KEY_MULTI_THREAD_DOWNLOAD, 3), 1, 10);
  }

  static setMultiThreadDownload(count: number): void {
    SettingsService.store.putNumber(KEY_MULTI_THREAD_DOWNLOAD, clamp(count, 1, 10));
  }

  static getConcurrentDownloadLimit(): number {
    return clamp(SettingsService.store.getNumber(KEY_CONCURRENT_DOWNLOAD_LIMIT, 1), 1, 5);
  }

  static setConcurrentDownloadLimit(count: number): void {
    SettingsService.store.putNumber(KEY_CONCURRENT_DOWNLOAD_LIMIT, clamp(count, 1, 5));
  }

  static getPreloadImage(): number {
    return clamp(SettingsService.store.getNumber(KEY_PRELOAD_IMAGE, 5), 0, 100);
  }

  static setPreloadImage(count: number): void {
    SettingsService.store.putNumber(KEY_PRELOAD_IMAGE, clamp(count, 0, 100));
  }

  static getDownloadOriginImage(): boolean {
    return SettingsService.store.getBoolean(KEY_DOWNLOAD_ORIGIN_IMAGE, false);
  }

  static setDownloadOriginImage(enable: boolean): void {
    SettingsService.store.putBoolean(KEY_DOWNLOAD_ORIGIN_IMAGE, enable);
  }

  // ---- Read ----

  static getReadCacheSize(): number {
    return clamp(SettingsService.store.getNumber(KEY_READ_CACHE_SIZE, 160), 40, 640);
  }

  static setReadCacheSize(sizeMB: number): void {
    SettingsService.store.putNumber(KEY_READ_CACHE_SIZE, clamp(sizeMB, 40, 640));
  }

  // ---- Download location ----

  static getDownloadLocation(): string | null {
    return SettingsService.store.getString(KEY_DOWNLOAD_LOCATION, null);
  }

  static setDownloadLocation(path: string | null): void {
    SettingsService.store.putString(KEY_DOWNLOAD_LOCATION, path);
  }

  // ---- Account & Sign-In ----

  static getNeedSignIn(): boolean {
    return SettingsService.store.getBoolean(KEY_NEED_SIGN_IN, true);
  }

  static putNeedSignIn(value: boolean): void {
    SettingsService.store.putBoolean(KEY_NEED_SIGN_IN, value);
  }

  static getDisplayName(): string {
    return SettingsService.store.getString(KEY_DISPLAY_NAME, '') ?? '';
  }

  static putDisplayName(value: string): void {
    SettingsService.store.putString(KEY_DISPLAY_NAME, value);
  }

  static getAvatar(): string {
    return SettingsService.store.getString(KEY_AVATAR, '') ?? '';
  }

  static putAvatar(value: string): void {
    SettingsService.store.putString(KEY_AVATAR, value);
  }

  // ---- Gallery display ----

  static getShowGalleryPages(): boolean {
    return SettingsService.store.getBoolean(KEY_SHOW_GALLERY_PAGES, false);
  }

  static setShowGalleryPages(show: boolean): void {
    SettingsService.store.putBoolean(KEY_SHOW_GALLERY_PAGES, show);
  }

  static getFixThumbUrl(): boolean {
    return SettingsService.store.getBoolean(KEY_FIX_THUMB_URL, false);
  }

  static setFixThumbUrl(fix: boolean): void {
    SettingsService.store.putBoolean(KEY_FIX_THUMB_URL, fix);
  }

  static getSaveParseErrorBody(): boolean {
    return SettingsService.store.getBoolean(KEY_SAVE_PARSE_ERROR_BODY, false);
  }

  static setSaveParseErrorBody(save: boolean): void {
    SettingsService.store.putBoolean(KEY_SAVE_PARSE_ERROR_BODY, save);
  }

  // ---- Security & Privacy ----

  static getSecurity(): string {
    return SettingsService.store.getString(KEY_SECURITY, '') ?? '';
  }

  static putSecurity(value: string): void {
    SettingsService.store.putString(KEY_SECURITY, value);
  }

  static getEnableFingerprint(): boolean {
    return SettingsService.store.getBoolean(KEY_ENABLE_FINGERPRINT, false);
  }

  static putEnableFingerprint(value: boolean): void {
    SettingsService.store.putBoolean(KEY_ENABLE_FINGERPRINT, value);
  }

  static getEnabledSecurity(): boolean {
    return SettingsService.store.getBoolean(KEY_ENABLED_SECURITY, false);
  }

  static putEnabledSecurity(value: boolean): void {
    SettingsService.store.putBoolean(KEY_ENABLED_SECURITY, value);
  }

  /**
   * Reset all settings to their defaults by replacing the store with a fresh
   * MemoryPreferencesStore. Intended for testing only.
   */
  static resetDefaults(): void {
    SettingsService.store = new MemoryPreferencesStore();
  }
}
