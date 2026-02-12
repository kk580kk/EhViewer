/*
 * Stub SettingsService — provides compile-time defaults.
 * Will be replaced by a full Preferences-backed implementation in task 04.
 */

/** Gallery site: 0 = E-Hentai, 1 = ExHentai */
const SITE_E = 0;

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

export class SettingsService {
  private static gallerySite: number = SITE_E;
  private static showJpnTitle: boolean = false;
  private static thumbResolution: number = 0;
  private static multiThreadDownload: number = 3;
  private static preloadImage: number = 5;
  private static downloadOriginImage: boolean = false;
  private static readCacheSize: number = 160; // MB
  private static downloadLocation: string | null = null;

  static getGallerySite(): number {
    return SettingsService.gallerySite;
  }

  static setGallerySite(site: number): void {
    SettingsService.gallerySite = site;
  }

  static getShowJpnTitle(): boolean {
    return SettingsService.showJpnTitle;
  }

  static setShowJpnTitle(show: boolean): void {
    SettingsService.showJpnTitle = show;
  }

  static getThumbResolution(): number {
    return SettingsService.thumbResolution;
  }

  static setThumbResolution(resolution: number): void {
    SettingsService.thumbResolution = resolution;
  }

  static getMultiThreadDownload(): number {
    return clamp(SettingsService.multiThreadDownload, 1, 10);
  }

  static setMultiThreadDownload(count: number): void {
    SettingsService.multiThreadDownload = clamp(count, 1, 10);
  }

  static getPreloadImage(): number {
    return clamp(SettingsService.preloadImage, 0, 100);
  }

  static setPreloadImage(count: number): void {
    SettingsService.preloadImage = clamp(count, 0, 100);
  }

  static getDownloadOriginImage(): boolean {
    return SettingsService.downloadOriginImage;
  }

  static setDownloadOriginImage(enable: boolean): void {
    SettingsService.downloadOriginImage = enable;
  }

  static getReadCacheSize(): number {
    return clamp(SettingsService.readCacheSize, 40, 640);
  }

  static setReadCacheSize(sizeMB: number): void {
    SettingsService.readCacheSize = clamp(sizeMB, 40, 640);
  }

  static getDownloadLocation(): string | null {
    return SettingsService.downloadLocation;
  }

  static setDownloadLocation(path: string | null): void {
    SettingsService.downloadLocation = path;
  }

  // ---- Account & Sign-In ----

  /** Whether the app should prompt for sign-in on first launch. */
  private static needSignIn: boolean = true;
  /** Display name obtained from profile after sign-in. */
  private static displayName: string = '';
  /** Avatar URL obtained from profile after sign-in. */
  private static avatar: string = '';

  static getNeedSignIn(): boolean {
    return SettingsService.needSignIn;
  }

  static putNeedSignIn(value: boolean): void {
    SettingsService.needSignIn = value;
  }

  static getDisplayName(): string {
    return SettingsService.displayName;
  }

  static putDisplayName(value: string): void {
    SettingsService.displayName = value;
  }

  static getAvatar(): string {
    return SettingsService.avatar;
  }

  static putAvatar(value: string): void {
    SettingsService.avatar = value;
  }

  // ---- Security & Privacy ----

  /** Lock pattern string. Empty string means no lock is set. */
  private static security: string = '';
  /** Whether fingerprint/biometric unlock is enabled. */
  private static enableFingerprint: boolean = false;
  /** Whether the security lock feature is enabled at all. */
  private static enabledSecurity: boolean = false;

  static getSecurity(): string {
    return SettingsService.security;
  }

  static putSecurity(value: string): void {
    SettingsService.security = value;
  }

  static getEnableFingerprint(): boolean {
    return SettingsService.enableFingerprint;
  }

  static putEnableFingerprint(value: boolean): void {
    SettingsService.enableFingerprint = value;
  }

  static getEnabledSecurity(): boolean {
    return SettingsService.enabledSecurity;
  }

  static putEnabledSecurity(value: boolean): void {
    SettingsService.enabledSecurity = value;
  }

  /**
   * Reset all settings to their defaults.
   * Intended for testing only.
   */
  static resetDefaults(): void {
    SettingsService.gallerySite = SITE_E;
    SettingsService.showJpnTitle = false;
    SettingsService.thumbResolution = 0;
    SettingsService.multiThreadDownload = 3;
    SettingsService.preloadImage = 5;
    SettingsService.downloadOriginImage = false;
    SettingsService.readCacheSize = 160;
    SettingsService.downloadLocation = null;
    SettingsService.needSignIn = true;
    SettingsService.displayName = '';
    SettingsService.avatar = '';
    SettingsService.security = '';
    SettingsService.enableFingerprint = false;
    SettingsService.enabledSecurity = false;
  }
}
