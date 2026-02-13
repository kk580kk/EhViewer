import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { SettingsService } from '../../../main/ets/service/SettingsService.ets';
import { MemoryPreferencesStore } from '../../../main/ets/preferences/MemoryPreferencesStore.ets';
import type { PreferencesStore } from '../../../main/ets/preferences/PreferencesStore.ets';

describe('SettingsService', () => {
  let store: MemoryPreferencesStore;

  beforeEach(() => {
    store = new MemoryPreferencesStore();
    SettingsService.initialize(store);
  });

  // ---- initialize / getStore ----

  describe('initialize', () => {
    it('should use the provided store', () => {
      assert.strictEqual(SettingsService.getStore(), store);
    });

    it('should read values previously written to the store', () => {
      store.putNumber('gallery_site', 1);
      assert.strictEqual(SettingsService.getGallerySite(), 1);
    });
  });

  // ---- Gallery site ----

  describe('gallerySite', () => {
    it('should default to 0 (E-Hentai)', () => {
      assert.strictEqual(SettingsService.getGallerySite(), 0);
    });

    it('should persist site value', () => {
      SettingsService.setGallerySite(1);
      assert.strictEqual(SettingsService.getGallerySite(), 1);
      assert.strictEqual(store.getNumber('gallery_site', -1), 1);
    });
  });

  // ---- Show JPN title ----

  describe('showJpnTitle', () => {
    it('should default to false', () => {
      assert.strictEqual(SettingsService.getShowJpnTitle(), false);
    });

    it('should persist', () => {
      SettingsService.setShowJpnTitle(true);
      assert.strictEqual(SettingsService.getShowJpnTitle(), true);
      assert.strictEqual(store.getBoolean('show_jpn_title', false), true);
    });
  });

  // ---- Thumb resolution ----

  describe('thumbResolution', () => {
    it('should default to 0', () => {
      assert.strictEqual(SettingsService.getThumbResolution(), 0);
    });

    it('should persist', () => {
      SettingsService.setThumbResolution(1);
      assert.strictEqual(SettingsService.getThumbResolution(), 1);
    });
  });

  // ---- Multi-thread download ----

  describe('multiThreadDownload', () => {
    it('should default to 3', () => {
      assert.strictEqual(SettingsService.getMultiThreadDownload(), 3);
    });

    it('should clamp to min 1', () => {
      SettingsService.setMultiThreadDownload(0);
      assert.strictEqual(SettingsService.getMultiThreadDownload(), 1);
    });

    it('should clamp to max 10', () => {
      SettingsService.setMultiThreadDownload(20);
      assert.strictEqual(SettingsService.getMultiThreadDownload(), 10);
    });

    it('should accept values in range', () => {
      SettingsService.setMultiThreadDownload(8);
      assert.strictEqual(SettingsService.getMultiThreadDownload(), 8);
    });
  });

  // ---- Concurrent download limit ----

  describe('concurrentDownloadLimit', () => {
    it('should default to 1', () => {
      assert.strictEqual(SettingsService.getConcurrentDownloadLimit(), 1);
    });

    it('should clamp to min 1', () => {
      SettingsService.setConcurrentDownloadLimit(0);
      assert.strictEqual(SettingsService.getConcurrentDownloadLimit(), 1);
    });

    it('should clamp to max 5', () => {
      SettingsService.setConcurrentDownloadLimit(10);
      assert.strictEqual(SettingsService.getConcurrentDownloadLimit(), 5);
    });

    it('should accept values in range', () => {
      SettingsService.setConcurrentDownloadLimit(3);
      assert.strictEqual(SettingsService.getConcurrentDownloadLimit(), 3);
    });

    it('should persist to store', () => {
      SettingsService.setConcurrentDownloadLimit(4);
      assert.strictEqual(store.getNumber('concurrent_download_limit', -1), 4);
    });
  });

  // ---- Preload image ----

  describe('preloadImage', () => {
    it('should default to 5', () => {
      assert.strictEqual(SettingsService.getPreloadImage(), 5);
    });

    it('should clamp to min 0', () => {
      SettingsService.setPreloadImage(-1);
      assert.strictEqual(SettingsService.getPreloadImage(), 0);
    });

    it('should clamp to max 100', () => {
      SettingsService.setPreloadImage(200);
      assert.strictEqual(SettingsService.getPreloadImage(), 100);
    });
  });

  // ---- Download origin image ----

  describe('downloadOriginImage', () => {
    it('should default to false', () => {
      assert.strictEqual(SettingsService.getDownloadOriginImage(), false);
    });

    it('should persist', () => {
      SettingsService.setDownloadOriginImage(true);
      assert.strictEqual(SettingsService.getDownloadOriginImage(), true);
    });
  });

  // ---- Read cache size ----

  describe('readCacheSize', () => {
    it('should default to 160', () => {
      assert.strictEqual(SettingsService.getReadCacheSize(), 160);
    });

    it('should clamp to min 40', () => {
      SettingsService.setReadCacheSize(10);
      assert.strictEqual(SettingsService.getReadCacheSize(), 40);
    });

    it('should clamp to max 640', () => {
      SettingsService.setReadCacheSize(999);
      assert.strictEqual(SettingsService.getReadCacheSize(), 640);
    });

    it('should accept values in range', () => {
      SettingsService.setReadCacheSize(320);
      assert.strictEqual(SettingsService.getReadCacheSize(), 320);
    });
  });

  // ---- Download location ----

  describe('downloadLocation', () => {
    it('should default to null', () => {
      assert.strictEqual(SettingsService.getDownloadLocation(), null);
    });

    it('should persist a path', () => {
      SettingsService.setDownloadLocation('/data/downloads');
      assert.strictEqual(SettingsService.getDownloadLocation(), '/data/downloads');
    });

    it('should reset to null', () => {
      SettingsService.setDownloadLocation('/data/downloads');
      SettingsService.setDownloadLocation(null);
      assert.strictEqual(SettingsService.getDownloadLocation(), null);
    });
  });

  // ---- Account & Sign-In ----

  describe('needSignIn', () => {
    it('should default to true', () => {
      assert.strictEqual(SettingsService.getNeedSignIn(), true);
    });

    it('should persist', () => {
      SettingsService.putNeedSignIn(false);
      assert.strictEqual(SettingsService.getNeedSignIn(), false);
    });
  });

  describe('displayName', () => {
    it('should default to empty string', () => {
      assert.strictEqual(SettingsService.getDisplayName(), '');
    });

    it('should persist', () => {
      SettingsService.putDisplayName('TestUser');
      assert.strictEqual(SettingsService.getDisplayName(), 'TestUser');
    });
  });

  describe('avatar', () => {
    it('should default to empty string', () => {
      assert.strictEqual(SettingsService.getAvatar(), '');
    });

    it('should persist', () => {
      SettingsService.putAvatar('https://example.com/avatar.png');
      assert.strictEqual(SettingsService.getAvatar(), 'https://example.com/avatar.png');
    });
  });

  // ---- Gallery display ----

  describe('showGalleryPages', () => {
    it('should default to false', () => {
      assert.strictEqual(SettingsService.getShowGalleryPages(), false);
    });

    it('should persist', () => {
      SettingsService.setShowGalleryPages(true);
      assert.strictEqual(SettingsService.getShowGalleryPages(), true);
    });
  });

  describe('fixThumbUrl', () => {
    it('should default to false', () => {
      assert.strictEqual(SettingsService.getFixThumbUrl(), false);
    });

    it('should persist', () => {
      SettingsService.setFixThumbUrl(true);
      assert.strictEqual(SettingsService.getFixThumbUrl(), true);
    });
  });

  describe('saveParseErrorBody', () => {
    it('should default to false', () => {
      assert.strictEqual(SettingsService.getSaveParseErrorBody(), false);
    });

    it('should persist', () => {
      SettingsService.setSaveParseErrorBody(true);
      assert.strictEqual(SettingsService.getSaveParseErrorBody(), true);
    });
  });

  // ---- Security & Privacy ----

  describe('security', () => {
    it('should default to empty string', () => {
      assert.strictEqual(SettingsService.getSecurity(), '');
    });

    it('should persist a pattern', () => {
      SettingsService.putSecurity('1234');
      assert.strictEqual(SettingsService.getSecurity(), '1234');
    });
  });

  describe('enableFingerprint', () => {
    it('should default to false', () => {
      assert.strictEqual(SettingsService.getEnableFingerprint(), false);
    });

    it('should persist', () => {
      SettingsService.putEnableFingerprint(true);
      assert.strictEqual(SettingsService.getEnableFingerprint(), true);
    });
  });

  describe('enabledSecurity', () => {
    it('should default to false', () => {
      assert.strictEqual(SettingsService.getEnabledSecurity(), false);
    });

    it('should persist', () => {
      SettingsService.putEnabledSecurity(true);
      assert.strictEqual(SettingsService.getEnabledSecurity(), true);
    });
  });

  // ---- Reading settings ----

  describe('readingDirection', () => {
    it('should default to 0 (LTR)', () => {
      assert.strictEqual(SettingsService.getReadingDirection(), 0);
    });

    it('should persist RTL direction', () => {
      SettingsService.setReadingDirection(1);
      assert.strictEqual(SettingsService.getReadingDirection(), 1);
    });

    it('should persist vertical direction', () => {
      SettingsService.setReadingDirection(2);
      assert.strictEqual(SettingsService.getReadingDirection(), 2);
    });

    it('should clamp to valid range', () => {
      SettingsService.setReadingDirection(-1);
      assert.strictEqual(SettingsService.getReadingDirection(), 0);
      SettingsService.setReadingDirection(5);
      assert.strictEqual(SettingsService.getReadingDirection(), 2);
    });
  });

  describe('keepScreenOn', () => {
    it('should default to false', () => {
      assert.strictEqual(SettingsService.getKeepScreenOn(), false);
    });

    it('should persist', () => {
      SettingsService.setKeepScreenOn(true);
      assert.strictEqual(SettingsService.getKeepScreenOn(), true);
    });
  });

  describe('showProgress', () => {
    it('should default to true', () => {
      assert.strictEqual(SettingsService.getShowProgress(), true);
    });

    it('should persist', () => {
      SettingsService.setShowProgress(false);
      assert.strictEqual(SettingsService.getShowProgress(), false);
    });
  });

  describe('volumePage', () => {
    it('should default to false', () => {
      assert.strictEqual(SettingsService.getVolumePage(), false);
    });

    it('should persist', () => {
      SettingsService.setVolumePage(true);
      assert.strictEqual(SettingsService.getVolumePage(), true);
    });
  });

  describe('readingFullscreen', () => {
    it('should default to true', () => {
      assert.strictEqual(SettingsService.getReadingFullscreen(), true);
    });

    it('should persist', () => {
      SettingsService.setReadingFullscreen(false);
      assert.strictEqual(SettingsService.getReadingFullscreen(), false);
    });
  });

  describe('screenLightness', () => {
    it('should default to 100', () => {
      assert.strictEqual(SettingsService.getScreenLightness(), 100);
    });

    it('should clamp to 0–200', () => {
      SettingsService.setScreenLightness(-10);
      assert.strictEqual(SettingsService.getScreenLightness(), 0);
      SettingsService.setScreenLightness(300);
      assert.strictEqual(SettingsService.getScreenLightness(), 200);
    });

    it('should persist valid value', () => {
      SettingsService.setScreenLightness(150);
      assert.strictEqual(SettingsService.getScreenLightness(), 150);
    });
  });

  describe('pageScaling', () => {
    it('should default to 0 (Fit)', () => {
      assert.strictEqual(SettingsService.getPageScaling(), 0);
    });

    it('should clamp to valid range', () => {
      SettingsService.setPageScaling(-1);
      assert.strictEqual(SettingsService.getPageScaling(), 0);
      SettingsService.setPageScaling(10);
      assert.strictEqual(SettingsService.getPageScaling(), 3);
    });

    it('should persist', () => {
      SettingsService.setPageScaling(2);
      assert.strictEqual(SettingsService.getPageScaling(), 2);
    });
  });

  describe('startPosition', () => {
    it('should default to 0 (Top)', () => {
      assert.strictEqual(SettingsService.getStartPosition(), 0);
    });

    it('should clamp to valid range', () => {
      SettingsService.setStartPosition(-1);
      assert.strictEqual(SettingsService.getStartPosition(), 0);
      SettingsService.setStartPosition(5);
      assert.strictEqual(SettingsService.getStartPosition(), 1);
    });

    it('should persist', () => {
      SettingsService.setStartPosition(1);
      assert.strictEqual(SettingsService.getStartPosition(), 1);
    });
  });

  // ---- resetDefaults ----

  describe('resetDefaults', () => {
    it('should reset all values to defaults', () => {
      SettingsService.setGallerySite(1);
      SettingsService.setShowJpnTitle(true);
      SettingsService.setMultiThreadDownload(8);
      SettingsService.putSecurity('pattern');

      SettingsService.resetDefaults();

      assert.strictEqual(SettingsService.getGallerySite(), 0);
      assert.strictEqual(SettingsService.getShowJpnTitle(), false);
      assert.strictEqual(SettingsService.getMultiThreadDownload(), 3);
      assert.strictEqual(SettingsService.getSecurity(), '');
    });

    it('should replace the store with a fresh instance', () => {
      const oldStore = SettingsService.getStore();
      SettingsService.resetDefaults();
      assert.notStrictEqual(SettingsService.getStore(), oldStore);
    });
  });

  // ---- Cross-store persistence ----

  describe('cross-store persistence', () => {
    it('values written via SettingsService are visible in the store', () => {
      SettingsService.setGallerySite(1);
      SettingsService.setShowJpnTitle(true);
      SettingsService.putSecurity('abc');
      SettingsService.setMultiThreadDownload(7);

      assert.strictEqual(store.getNumber('gallery_site', -1), 1);
      assert.strictEqual(store.getBoolean('show_jpn_title', false), true);
      assert.strictEqual(store.getString('security', null), 'abc');
      assert.strictEqual(store.getNumber('download_thread', -1), 7);
    });

    it('values written directly to store are visible via SettingsService', () => {
      store.putNumber('gallery_site', 1);
      store.putBoolean('show_jpn_title', true);
      store.putString('security', 'xyz');

      assert.strictEqual(SettingsService.getGallerySite(), 1);
      assert.strictEqual(SettingsService.getShowJpnTitle(), true);
      assert.strictEqual(SettingsService.getSecurity(), 'xyz');
    });
  });
});
