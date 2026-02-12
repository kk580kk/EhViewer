/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { SettingsService } from '../service/SettingsService.ets';

/**
 * Settings section identifiers.
 */
export const SettingsSection = {
  EH: 'eh',
  READ: 'read',
  DOWNLOAD: 'download',
  ADVANCED: 'advanced',
  PRIVACY: 'privacy',
  ABOUT: 'about',
} as const;

export type SettingsSectionType = (typeof SettingsSection)[keyof typeof SettingsSection];

/**
 * A single setting item descriptor for UI rendering.
 */
export interface SettingItem {
  key: string;
  title: string;
  summary: string;
  type: 'toggle' | 'select' | 'action' | 'info';
}

/**
 * A settings group with a title and list of items.
 */
export interface SettingsGroup {
  section: SettingsSectionType;
  title: string;
  items: SettingItem[];
}

/** Gallery site labels. */
export const SITE_LABELS: string[] = ['E-Hentai', 'ExHentai'];

/** Thumb resolution labels. */
export const THUMB_RESOLUTION_LABELS: string[] = ['Low', 'High'];

/**
 * ViewModel for the Settings page.
 *
 * Reads / writes through SettingsService and provides a flat structure
 * that the UI can render as grouped preference items.
 */
export class SettingsViewModel {
  // ---- EH Settings ----

  getGallerySite(): number {
    return SettingsService.getGallerySite();
  }

  setGallerySite(site: number): void {
    SettingsService.setGallerySite(site);
  }

  getGallerySiteLabel(): string {
    const site = this.getGallerySite();
    return SITE_LABELS[site] ?? 'E-Hentai';
  }

  getShowJpnTitle(): boolean {
    return SettingsService.getShowJpnTitle();
  }

  setShowJpnTitle(show: boolean): void {
    SettingsService.setShowJpnTitle(show);
  }

  getThumbResolution(): number {
    return SettingsService.getThumbResolution();
  }

  setThumbResolution(res: number): void {
    SettingsService.setThumbResolution(res);
  }

  getThumbResolutionLabel(): string {
    const res = this.getThumbResolution();
    return THUMB_RESOLUTION_LABELS[res] ?? 'Low';
  }

  // ---- Read Settings ----

  getReadCacheSize(): number {
    return SettingsService.getReadCacheSize();
  }

  setReadCacheSize(sizeMB: number): void {
    SettingsService.setReadCacheSize(sizeMB);
  }

  // ---- Download Settings ----

  getMultiThreadDownload(): number {
    return SettingsService.getMultiThreadDownload();
  }

  setMultiThreadDownload(count: number): void {
    SettingsService.setMultiThreadDownload(count);
  }

  getPreloadImage(): number {
    return SettingsService.getPreloadImage();
  }

  setPreloadImage(count: number): void {
    SettingsService.setPreloadImage(count);
  }

  getDownloadOriginImage(): boolean {
    return SettingsService.getDownloadOriginImage();
  }

  setDownloadOriginImage(enable: boolean): void {
    SettingsService.setDownloadOriginImage(enable);
  }

  getDownloadLocation(): string | null {
    return SettingsService.getDownloadLocation();
  }

  setDownloadLocation(path: string | null): void {
    SettingsService.setDownloadLocation(path);
  }

  // ---- Privacy Settings ----

  getEnabledSecurity(): boolean {
    return SettingsService.getEnabledSecurity();
  }

  setEnabledSecurity(enable: boolean): void {
    SettingsService.putEnabledSecurity(enable);
  }

  getEnableFingerprint(): boolean {
    return SettingsService.getEnableFingerprint();
  }

  setEnableFingerprint(enable: boolean): void {
    SettingsService.putEnableFingerprint(enable);
  }

  hasSecurityLock(): boolean {
    return SettingsService.getSecurity().length > 0;
  }

  // ---- Build settings groups for UI ----

  buildGroups(): SettingsGroup[] {
    return [
      this.buildEhGroup(),
      this.buildReadGroup(),
      this.buildDownloadGroup(),
      this.buildAdvancedGroup(),
      this.buildPrivacyGroup(),
      this.buildAboutGroup(),
    ];
  }

  buildEhGroup(): SettingsGroup {
    return {
      section: SettingsSection.EH,
      title: 'EH',
      items: [
        {
          key: 'gallery_site',
          title: 'Gallery Site',
          summary: this.getGallerySiteLabel(),
          type: 'select',
        },
        {
          key: 'show_jpn_title',
          title: 'Show Japanese Title',
          summary: this.getShowJpnTitle() ? 'On' : 'Off',
          type: 'toggle',
        },
        {
          key: 'thumb_resolution',
          title: 'Thumbnail Resolution',
          summary: this.getThumbResolutionLabel(),
          type: 'select',
        },
      ],
    };
  }

  buildReadGroup(): SettingsGroup {
    return {
      section: SettingsSection.READ,
      title: 'Read',
      items: [
        {
          key: 'read_cache_size',
          title: 'Read Cache Size',
          summary: `${this.getReadCacheSize()} MB`,
          type: 'info',
        },
      ],
    };
  }

  buildDownloadGroup(): SettingsGroup {
    const location = this.getDownloadLocation();
    return {
      section: SettingsSection.DOWNLOAD,
      title: 'Download',
      items: [
        {
          key: 'multi_thread_download',
          title: 'Multi-thread Download',
          summary: `${this.getMultiThreadDownload()} threads`,
          type: 'info',
        },
        {
          key: 'preload_image',
          title: 'Preload Image',
          summary: `${this.getPreloadImage()} pages`,
          type: 'info',
        },
        {
          key: 'download_origin_image',
          title: 'Download Original Image',
          summary: this.getDownloadOriginImage() ? 'On' : 'Off',
          type: 'toggle',
        },
        {
          key: 'download_location',
          title: 'Download Location',
          summary: location ?? 'Not set',
          type: 'action',
        },
      ],
    };
  }

  buildAdvancedGroup(): SettingsGroup {
    return {
      section: SettingsSection.ADVANCED,
      title: 'Advanced',
      items: [
        {
          key: 'clear_memory_cache',
          title: 'Clear Memory Cache',
          summary: 'Free up memory used by image cache',
          type: 'action',
        },
      ],
    };
  }

  buildPrivacyGroup(): SettingsGroup {
    return {
      section: SettingsSection.PRIVACY,
      title: 'Privacy',
      items: [
        {
          key: 'security_lock',
          title: 'App Lock',
          summary: this.hasSecurityLock() ? 'Enabled' : 'Not set',
          type: 'action',
        },
        {
          key: 'enable_fingerprint',
          title: 'Fingerprint Unlock',
          summary: this.getEnableFingerprint() ? 'On' : 'Off',
          type: 'toggle',
        },
      ],
    };
  }

  buildAboutGroup(): SettingsGroup {
    return {
      section: SettingsSection.ABOUT,
      title: 'About',
      items: [
        {
          key: 'version',
          title: 'Version',
          summary: AboutInfo.getVersionString(),
          type: 'info',
        },
        {
          key: 'author',
          title: 'Author',
          summary: AboutInfo.getAuthor(),
          type: 'action',
        },
        {
          key: 'check_for_updates',
          title: 'Check for Updates',
          summary: 'Check if a new version is available',
          type: 'action',
        },
      ],
    };
  }
}

/**
 * Static helper for app "About" information.
 */
export class AboutInfo {
  private static readonly APP_NAME: string = 'EhViewer';
  private static readonly VERSION_NAME: string = '1.7.3';
  private static readonly VERSION_CODE: number = 173;
  private static readonly AUTHOR: string = 'Hippo Seven';
  private static readonly AUTHOR_EMAIL: string = 'seven332@163.com';

  static getAppName(): string {
    return AboutInfo.APP_NAME;
  }

  static getVersionName(): string {
    return AboutInfo.VERSION_NAME;
  }

  static getVersionCode(): number {
    return AboutInfo.VERSION_CODE;
  }

  static getVersionString(): string {
    return `${AboutInfo.VERSION_NAME} (${AboutInfo.VERSION_CODE})`;
  }

  static getAuthor(): string {
    return AboutInfo.AUTHOR;
  }

  static getAuthorEmail(): string {
    return AboutInfo.AUTHOR_EMAIL;
  }
}
