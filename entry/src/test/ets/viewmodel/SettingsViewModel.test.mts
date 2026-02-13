import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  SettingsViewModel,
  AboutInfo,
  SettingsSection,
  SITE_LABELS,
  THUMB_RESOLUTION_LABELS,
} from '../../../main/ets/viewmodel/SettingsViewModel.ets';
import type { SettingsGroup, SettingItem } from '../../../main/ets/viewmodel/SettingsViewModel.ets';
import { SettingsService } from '../../../main/ets/service/SettingsService.ets';

describe('SettingsViewModel', () => {
  let vm: SettingsViewModel;

  beforeEach(() => {
    SettingsService.resetDefaults();
    vm = new SettingsViewModel();
  });

  // ---- EH Settings ----

  describe('gallery site', () => {
    it('should default to E-Hentai (0)', () => {
      assert.strictEqual(vm.getGallerySite(), 0);
      assert.strictEqual(vm.getGallerySiteLabel(), 'E-Hentai');
    });

    it('should update gallery site', () => {
      vm.setGallerySite(1);
      assert.strictEqual(vm.getGallerySite(), 1);
      assert.strictEqual(vm.getGallerySiteLabel(), 'ExHentai');
    });

    it('should return fallback label for unknown site', () => {
      vm.setGallerySite(99);
      assert.strictEqual(vm.getGallerySiteLabel(), 'E-Hentai');
    });
  });

  describe('show JPN title', () => {
    it('should default to false', () => {
      assert.strictEqual(vm.getShowJpnTitle(), false);
    });

    it('should toggle', () => {
      vm.setShowJpnTitle(true);
      assert.strictEqual(vm.getShowJpnTitle(), true);
      vm.setShowJpnTitle(false);
      assert.strictEqual(vm.getShowJpnTitle(), false);
    });
  });

  describe('thumb resolution', () => {
    it('should default to Low (0)', () => {
      assert.strictEqual(vm.getThumbResolution(), 0);
      assert.strictEqual(vm.getThumbResolutionLabel(), 'Low');
    });

    it('should update to High (1)', () => {
      vm.setThumbResolution(1);
      assert.strictEqual(vm.getThumbResolution(), 1);
      assert.strictEqual(vm.getThumbResolutionLabel(), 'High');
    });

    it('should return fallback label for unknown resolution', () => {
      vm.setThumbResolution(99);
      assert.strictEqual(vm.getThumbResolutionLabel(), 'Low');
    });
  });

  // ---- Read Settings ----

  describe('read cache size', () => {
    it('should default to 160 MB', () => {
      assert.strictEqual(vm.getReadCacheSize(), 160);
    });

    it('should update and clamp', () => {
      vm.setReadCacheSize(320);
      assert.strictEqual(vm.getReadCacheSize(), 320);

      // Clamp to min 40
      vm.setReadCacheSize(10);
      assert.strictEqual(vm.getReadCacheSize(), 40);

      // Clamp to max 640
      vm.setReadCacheSize(999);
      assert.strictEqual(vm.getReadCacheSize(), 640);
    });
  });

  // ---- Download Settings ----

  describe('multi-thread download', () => {
    it('should default to 3', () => {
      assert.strictEqual(vm.getMultiThreadDownload(), 3);
    });

    it('should update and clamp', () => {
      vm.setMultiThreadDownload(8);
      assert.strictEqual(vm.getMultiThreadDownload(), 8);

      vm.setMultiThreadDownload(0);
      assert.strictEqual(vm.getMultiThreadDownload(), 1);

      vm.setMultiThreadDownload(20);
      assert.strictEqual(vm.getMultiThreadDownload(), 10);
    });
  });

  describe('preload image', () => {
    it('should default to 5', () => {
      assert.strictEqual(vm.getPreloadImage(), 5);
    });

    it('should update and clamp', () => {
      vm.setPreloadImage(50);
      assert.strictEqual(vm.getPreloadImage(), 50);

      vm.setPreloadImage(-1);
      assert.strictEqual(vm.getPreloadImage(), 0);

      vm.setPreloadImage(200);
      assert.strictEqual(vm.getPreloadImage(), 100);
    });
  });

  describe('download origin image', () => {
    it('should default to false', () => {
      assert.strictEqual(vm.getDownloadOriginImage(), false);
    });

    it('should toggle', () => {
      vm.setDownloadOriginImage(true);
      assert.strictEqual(vm.getDownloadOriginImage(), true);
    });
  });

  describe('download location', () => {
    it('should default to null', () => {
      assert.strictEqual(vm.getDownloadLocation(), null);
    });

    it('should update', () => {
      vm.setDownloadLocation('/data/downloads');
      assert.strictEqual(vm.getDownloadLocation(), '/data/downloads');
    });

    it('should reset to null', () => {
      vm.setDownloadLocation('/data/downloads');
      vm.setDownloadLocation(null);
      assert.strictEqual(vm.getDownloadLocation(), null);
    });
  });

  // ---- Privacy Settings ----

  describe('security lock', () => {
    it('should default to no lock', () => {
      assert.strictEqual(vm.hasSecurityLock(), false);
    });

    it('should detect lock when set', () => {
      SettingsService.putSecurity('1234');
      assert.strictEqual(vm.hasSecurityLock(), true);
    });
  });

  describe('fingerprint', () => {
    it('should default to disabled', () => {
      assert.strictEqual(vm.getEnableFingerprint(), false);
    });

    it('should toggle', () => {
      vm.setEnableFingerprint(true);
      assert.strictEqual(vm.getEnableFingerprint(), true);
    });
  });

  describe('enabled security', () => {
    it('should default to disabled', () => {
      assert.strictEqual(vm.getEnabledSecurity(), false);
    });

    it('should toggle', () => {
      vm.setEnabledSecurity(true);
      assert.strictEqual(vm.getEnabledSecurity(), true);
    });
  });

  // ---- Build Groups ----

  describe('buildGroups', () => {
    it('should return 6 groups', () => {
      const groups = vm.buildGroups();
      assert.strictEqual(groups.length, 6);
    });

    it('should have correct section identifiers', () => {
      const groups = vm.buildGroups();
      const sections = groups.map((g: SettingsGroup) => g.section);
      assert.deepStrictEqual(sections, [
        SettingsSection.EH,
        SettingsSection.READ,
        SettingsSection.DOWNLOAD,
        SettingsSection.ADVANCED,
        SettingsSection.PRIVACY,
        SettingsSection.ABOUT,
      ]);
    });

    it('should have correct group titles', () => {
      const groups = vm.buildGroups();
      const titles = groups.map((g: SettingsGroup) => g.title);
      assert.deepStrictEqual(titles, [
        'EH', 'Read', 'Download', 'Advanced', 'Privacy', 'About',
      ]);
    });
  });

  describe('buildEhGroup', () => {
    it('should contain 3 items', () => {
      const group = vm.buildEhGroup();
      assert.strictEqual(group.items.length, 3);
    });

    it('should reflect current settings values', () => {
      vm.setGallerySite(1);
      vm.setShowJpnTitle(true);
      vm.setThumbResolution(1);
      const group = vm.buildEhGroup();

      const siteItem = group.items.find((i: SettingItem) => i.key === 'gallery_site');
      assert.ok(siteItem);
      assert.strictEqual(siteItem!.summary, 'ExHentai');

      const jpnItem = group.items.find((i: SettingItem) => i.key === 'show_jpn_title');
      assert.ok(jpnItem);
      assert.strictEqual(jpnItem!.summary, 'On');

      const thumbItem = group.items.find((i: SettingItem) => i.key === 'thumb_resolution');
      assert.ok(thumbItem);
      assert.strictEqual(thumbItem!.summary, 'High');
    });
  });

  describe('buildDownloadGroup', () => {
    it('should contain 5 items', () => {
      const group = vm.buildDownloadGroup();
      assert.strictEqual(group.items.length, 5);
    });

    it('should show download location or Not set', () => {
      let group = vm.buildDownloadGroup();
      const locItem = group.items.find((i: SettingItem) => i.key === 'download_location');
      assert.ok(locItem);
      assert.strictEqual(locItem!.summary, 'Not set');

      vm.setDownloadLocation('/sdcard/EhViewer');
      group = vm.buildDownloadGroup();
      const locItem2 = group.items.find((i: SettingItem) => i.key === 'download_location');
      assert.ok(locItem2);
      assert.strictEqual(locItem2!.summary, '/sdcard/EhViewer');
    });
  });

  describe('buildPrivacyGroup', () => {
    it('should contain 2 items', () => {
      const group = vm.buildPrivacyGroup();
      assert.strictEqual(group.items.length, 2);
    });

    it('should reflect security lock status', () => {
      let group = vm.buildPrivacyGroup();
      const lockItem = group.items.find((i: SettingItem) => i.key === 'security_lock');
      assert.ok(lockItem);
      assert.strictEqual(lockItem!.summary, 'Not set');

      SettingsService.putSecurity('pattern123');
      group = vm.buildPrivacyGroup();
      const lockItem2 = group.items.find((i: SettingItem) => i.key === 'security_lock');
      assert.ok(lockItem2);
      assert.strictEqual(lockItem2!.summary, 'Enabled');
    });
  });

  describe('buildAboutGroup', () => {
    it('should contain 3 items', () => {
      const group = vm.buildAboutGroup();
      assert.strictEqual(group.items.length, 3);
    });

    it('should include version info', () => {
      const group = vm.buildAboutGroup();
      const versionItem = group.items.find((i: SettingItem) => i.key === 'version');
      assert.ok(versionItem);
      assert.ok(versionItem!.summary.includes('1.7.3'));
    });
  });
});

describe('AboutInfo', () => {
  it('should return app name', () => {
    assert.strictEqual(AboutInfo.getAppName(), 'EhViewer');
  });

  it('should return version name', () => {
    assert.strictEqual(AboutInfo.getVersionName(), '1.7.3');
  });

  it('should return version code', () => {
    assert.strictEqual(AboutInfo.getVersionCode(), 173);
  });

  it('should return formatted version string', () => {
    assert.strictEqual(AboutInfo.getVersionString(), '1.7.3 (173)');
  });

  it('should return author', () => {
    assert.strictEqual(AboutInfo.getAuthor(), 'Hippo Seven');
  });

  it('should return author email', () => {
    assert.strictEqual(AboutInfo.getAuthorEmail(), 'seven332@163.com');
  });
});

describe('constants', () => {
  it('SITE_LABELS should have 2 entries', () => {
    assert.strictEqual(SITE_LABELS.length, 2);
    assert.deepStrictEqual(SITE_LABELS, ['E-Hentai', 'ExHentai']);
  });

  it('THUMB_RESOLUTION_LABELS should have 2 entries', () => {
    assert.strictEqual(THUMB_RESOLUTION_LABELS.length, 2);
    assert.deepStrictEqual(THUMB_RESOLUTION_LABELS, ['Low', 'High']);
  });
});
