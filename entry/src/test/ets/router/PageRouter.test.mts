import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  Routes,
  PageRouter,
  buildNavResult,
} from '../../../main/ets/router/PageRouter.ets';

describe('Routes constants', () => {
  it('should define MAIN route', () => {
    assert.strictEqual(Routes.MAIN, 'pages/Index');
  });

  it('should define GALLERY_DETAIL route', () => {
    assert.strictEqual(Routes.GALLERY_DETAIL, 'pages/GalleryDetailPage');
  });

  it('should define GALLERY_READER route', () => {
    assert.strictEqual(Routes.GALLERY_READER, 'pages/GalleryReaderPage');
  });
});

describe('buildNavResult', () => {
  it('should create result with url only', () => {
    const result = buildNavResult('pages/Index');
    assert.strictEqual(result.url, 'pages/Index');
    assert.strictEqual(result.params, undefined);
  });

  it('should create result with url and params', () => {
    const params = { gid: 12345 as Object, token: 'abc' as Object };
    const result = buildNavResult('pages/GalleryDetailPage', params);
    assert.strictEqual(result.url, 'pages/GalleryDetailPage');
    assert.deepStrictEqual(result.params, params);
  });
});

describe('PageRouter.toGalleryDetail', () => {
  it('should build correct route with gid and token', () => {
    const nav = PageRouter.toGalleryDetail(99999, 'deadbeef');
    assert.strictEqual(nav.url, Routes.GALLERY_DETAIL);
    assert.strictEqual(nav.params!['gid'], 99999);
    assert.strictEqual(nav.params!['token'], 'deadbeef');
  });

  it('should handle zero gid', () => {
    const nav = PageRouter.toGalleryDetail(0, '');
    assert.strictEqual(nav.params!['gid'], 0);
    assert.strictEqual(nav.params!['token'], '');
  });
});

describe('PageRouter.toGalleryReader', () => {
  it('should build correct route with default page 0', () => {
    const nav = PageRouter.toGalleryReader(100, 'tok');
    assert.strictEqual(nav.url, Routes.GALLERY_READER);
    assert.strictEqual(nav.params!['gid'], 100);
    assert.strictEqual(nav.params!['token'], 'tok');
    assert.strictEqual(nav.params!['page'], 0);
  });

  it('should accept explicit page number', () => {
    const nav = PageRouter.toGalleryReader(200, 'xyz', 42);
    assert.strictEqual(nav.params!['page'], 42);
  });
});

describe('PageRouter.toMain', () => {
  it('should build route to main page without params', () => {
    const nav = PageRouter.toMain();
    assert.strictEqual(nav.url, Routes.MAIN);
    assert.strictEqual(nav.params, undefined);
  });
});
