import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { EhConfig, DEFAULT_USER_AGENT } from '../../../main/ets/client/EhConfig.ets';
import { SettingsService } from '../../../main/ets/service/SettingsService.ets';
import { MemoryPreferencesStore } from '../../../main/ets/preferences/MemoryPreferencesStore.ets';
import { EhUrl } from '../../../main/ets/client/EhUrl.ets';

describe('EhConfig', () => {
  beforeEach(() => {
    const store = new MemoryPreferencesStore();
    SettingsService.initialize(store);
  });

  describe('getGalleryDomain', () => {
    it('returns DOMAIN_E when gallery site is E', () => {
      SettingsService.setGallerySite(EhUrl.SITE_E);
      assert.strictEqual(EhConfig.getGalleryDomain(), EhUrl.DOMAIN_E);
    });

    it('returns DOMAIN_EX when gallery site is EX', () => {
      SettingsService.setGallerySite(EhUrl.SITE_EX);
      assert.strictEqual(EhConfig.getGalleryDomain(), EhUrl.DOMAIN_EX);
    });
  });

  describe('userAgent', () => {
    it('defaults to DEFAULT_USER_AGENT', () => {
      const config = new EhConfig();
      assert.strictEqual(config.userAgent, DEFAULT_USER_AGENT);
    });

    it('can be overridden', () => {
      const config = new EhConfig();
      config.userAgent = 'CustomAgent/1.0';
      assert.strictEqual(config.userAgent, 'CustomAgent/1.0');
    });
  });

  describe('uconfig', () => {
    it('contains image size', () => {
      const config = new EhConfig();
      config.imageSize = EhConfig.IMAGE_SIZE_1280X;
      config.setDirty();
      const uconfig = config.uconfig();
      assert.ok(uconfig.includes('xr_1280'));
    });

    it('contains excluded languages', () => {
      const config = new EhConfig();
      config.excludedLanguages = '0x1024x2048';
      config.setDirty();
      const uconfig = config.uconfig();
      assert.ok(uconfig.includes('xl_0x1024x2048'));
    });

    it('contains excluded namespaces', () => {
      const config = new EhConfig();
      config.excludedNamespaces = 0x5;
      config.setDirty();
      const uconfig = config.uconfig();
      assert.ok(uconfig.includes('xns_5'));
    });

    it('contains default categories', () => {
      const config = new EhConfig();
      config.defaultCategories = EhConfig.ALL_CATEGORY;
      config.setDirty();
      const uconfig = config.uconfig();
      assert.ok(uconfig.includes('cats_1023'));
    });

    it('caches until setDirty', () => {
      const config = new EhConfig();
      config.imageSize = EhConfig.IMAGE_SIZE_AUTO;
      config.setDirty();
      const first = config.uconfig();
      const second = config.uconfig();
      assert.strictEqual(first, second);
      config.imageSize = EhConfig.IMAGE_SIZE_1600X;
      config.setDirty();
      const third = config.uconfig();
      assert.notStrictEqual(first, third);
      assert.ok(third.includes('xr_1600'));
    });

    it('is not null', () => {
      const config = new EhConfig();
      assert.ok(config.uconfig().length > 0);
    });
  });

  describe('clone', () => {
    it('copies imageSize and excludedLanguages', () => {
      const config = new EhConfig();
      config.imageSize = EhConfig.IMAGE_SIZE_780X;
      config.excludedLanguages = '1x2';
      config.defaultCategories = 0x3;
      const cloned = config.clone();
      assert.strictEqual(cloned.imageSize, config.imageSize);
      assert.strictEqual(cloned.excludedLanguages, config.excludedLanguages);
      assert.strictEqual(cloned.defaultCategories, config.defaultCategories);
    });
  });

  describe('defaults', () => {
    it('has expected default values', () => {
      const config = new EhConfig();
      assert.strictEqual(config.imageSize, EhConfig.IMAGE_SIZE_AUTO);
      assert.strictEqual(config.excludedLanguages, '');
      assert.strictEqual(config.excludedNamespaces, 0);
      assert.strictEqual(config.defaultCategories, 0);
    });
  });

  describe('constants', () => {
    it('category bitmasks match', () => {
      assert.strictEqual(EhConfig.MISC, 0x1);
      assert.strictEqual(EhConfig.DOUJINSHI, 0x2);
      assert.strictEqual(EhConfig.ALL_CATEGORY, 0x3ff);
    });

    it('namespace bitmasks match', () => {
      assert.strictEqual(EhConfig.NAMESPACES_RECLASS, 0x1);
      assert.strictEqual(EhConfig.NAMESPACES_LANGUAGE, 0x2);
      assert.strictEqual(EhConfig.NAMESPACES_FEMALE, 0x80);
    });
  });
});
