import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { UrlBuilder } from '../../../main/ets/network/UrlBuilder.ets';

describe('UrlBuilder', () => {
  describe('build()', () => {
    it('should return base URL when no params', () => {
      const url = new UrlBuilder('https://e-hentai.org/').build();
      assert.strictEqual(url, 'https://e-hentai.org/');
    });

    it('should append query parameters', () => {
      const url = new UrlBuilder('https://e-hentai.org/')
        .addQuery('f_search', 'artbook')
        .addQuery('page', '2')
        .build();
      assert.strictEqual(url, 'https://e-hentai.org/?f_search=artbook&page=2');
    });

    it('should encode special characters', () => {
      const url = new UrlBuilder('https://example.com/')
        .addQuery('q', 'hello world&more')
        .build();
      assert.strictEqual(url, 'https://example.com/?q=hello%20world%26more');
    });

    it('should append with & if base already has ?', () => {
      const url = new UrlBuilder('https://example.com/?existing=1')
        .addQuery('new', '2')
        .build();
      assert.strictEqual(url, 'https://example.com/?existing=1&new=2');
    });
  });

  describe('addQueryIfNotEmpty()', () => {
    it('should skip null values', () => {
      const url = new UrlBuilder('https://example.com/')
        .addQueryIfNotEmpty('key', null)
        .build();
      assert.strictEqual(url, 'https://example.com/');
    });

    it('should skip empty string values', () => {
      const url = new UrlBuilder('https://example.com/')
        .addQueryIfNotEmpty('key', '')
        .build();
      assert.strictEqual(url, 'https://example.com/');
    });

    it('should skip undefined values', () => {
      const url = new UrlBuilder('https://example.com/')
        .addQueryIfNotEmpty('key', undefined)
        .build();
      assert.strictEqual(url, 'https://example.com/');
    });

    it('should include non-empty values', () => {
      const url = new UrlBuilder('https://example.com/')
        .addQueryIfNotEmpty('key', 'value')
        .build();
      assert.strictEqual(url, 'https://example.com/?key=value');
    });
  });

  describe('addQueryNumber()', () => {
    it('should add numeric parameter', () => {
      const url = new UrlBuilder('https://example.com/')
        .addQueryNumber('page', 5)
        .build();
      assert.strictEqual(url, 'https://example.com/?page=5');
    });

    it('should handle zero', () => {
      const url = new UrlBuilder('https://example.com/')
        .addQueryNumber('offset', 0)
        .build();
      assert.strictEqual(url, 'https://example.com/?offset=0');
    });
  });

  describe('chaining', () => {
    it('should support fluent chaining', () => {
      const url = new UrlBuilder('https://api.example.com/v1')
        .addQuery('method', 'gdata')
        .addQueryNumber('page', 0)
        .addQueryIfNotEmpty('token', 'abc123')
        .addQueryIfNotEmpty('empty', null)
        .build();
      assert.strictEqual(url, 'https://api.example.com/v1?method=gdata&page=0&token=abc123');
    });
  });
});
