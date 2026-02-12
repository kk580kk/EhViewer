import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { TextUrl } from '../../../main/ets/util/TextUrl.ets';
import type { TextSegment, UrlMatch } from '../../../main/ets/util/TextUrl.ets';

describe('TextUrl', () => {

  describe('findUrls', () => {
    it('should return empty array for text with no URLs', () => {
      assert.deepStrictEqual(TextUrl.findUrls('hello world'), []);
    });

    it('should find a single http URL', () => {
      const matches = TextUrl.findUrls('visit http://example.com please');
      assert.strictEqual(matches.length, 1);
      assert.strictEqual(matches[0].url, 'http://example.com');
      assert.strictEqual(matches[0].start, 6);
      assert.strictEqual(matches[0].end, 24);
    });

    it('should find a single https URL', () => {
      const matches = TextUrl.findUrls('go to https://example.com/path');
      assert.strictEqual(matches.length, 1);
      assert.strictEqual(matches[0].url, 'https://example.com/path');
    });

    it('should find multiple URLs', () => {
      const text = 'http://a.com and https://b.org/page';
      const matches = TextUrl.findUrls(text);
      assert.strictEqual(matches.length, 2);
      assert.strictEqual(matches[0].url, 'http://a.com');
      assert.strictEqual(matches[1].url, 'https://b.org/page');
    });

    it('should match URLs with port numbers', () => {
      const matches = TextUrl.findUrls('http://example.com:8080/api');
      assert.strictEqual(matches.length, 1);
      assert.strictEqual(matches[0].url, 'http://example.com:8080/api');
    });

    it('should not match single-label hosts like localhost', () => {
      // The pattern requires at least one dot in the hostname (same as Java original)
      assert.deepStrictEqual(TextUrl.findUrls('http://localhost:8080/api'), []);
    });

    it('should match URLs with query parameters', () => {
      const matches = TextUrl.findUrls('https://example.com/search?q=test&page=1');
      assert.strictEqual(matches.length, 1);
      assert.strictEqual(matches[0].url, 'https://example.com/search?q=test&page=1');
    });

    it('should match URLs with fragments', () => {
      const matches = TextUrl.findUrls('https://example.com/page#section');
      assert.strictEqual(matches.length, 1);
      assert.strictEqual(matches[0].url, 'https://example.com/page#section');
    });

    it('should match URLs with percent-encoded characters', () => {
      const matches = TextUrl.findUrls('https://example.com/path%20with%20spaces');
      assert.strictEqual(matches.length, 1);
      assert.strictEqual(matches[0].url, 'https://example.com/path%20with%20spaces');
    });

    it('should not match ftp or other protocols', () => {
      assert.deepStrictEqual(TextUrl.findUrls('ftp://files.example.com'), []);
    });

    it('should return empty for empty string', () => {
      assert.deepStrictEqual(TextUrl.findUrls(''), []);
    });
  });

  describe('handleTextUrl', () => {
    it('should return empty array for empty string', () => {
      assert.deepStrictEqual(TextUrl.handleTextUrl(''), []);
    });

    it('should return single plain segment for text without URLs', () => {
      const segments = TextUrl.handleTextUrl('hello world');
      assert.strictEqual(segments.length, 1);
      assert.strictEqual(segments[0].text, 'hello world');
      assert.strictEqual(segments[0].url, undefined);
    });

    it('should parse text with URL at the start', () => {
      const segments = TextUrl.handleTextUrl('http://example.com is great');
      assert.strictEqual(segments.length, 2);
      assert.strictEqual(segments[0].text, 'http://example.com');
      assert.strictEqual(segments[0].url, 'http://example.com');
      assert.strictEqual(segments[1].text, ' is great');
      assert.strictEqual(segments[1].url, undefined);
    });

    it('should parse text with URL in the middle', () => {
      const segments = TextUrl.handleTextUrl('visit http://example.com today');
      assert.strictEqual(segments.length, 3);
      assert.strictEqual(segments[0].text, 'visit ');
      assert.strictEqual(segments[0].url, undefined);
      assert.strictEqual(segments[1].text, 'http://example.com');
      assert.strictEqual(segments[1].url, 'http://example.com');
      assert.strictEqual(segments[2].text, ' today');
      assert.strictEqual(segments[2].url, undefined);
    });

    it('should parse text with URL at the end', () => {
      const segments = TextUrl.handleTextUrl('go to http://example.com');
      assert.strictEqual(segments.length, 2);
      assert.strictEqual(segments[0].text, 'go to ');
      assert.strictEqual(segments[0].url, undefined);
      assert.strictEqual(segments[1].text, 'http://example.com');
      assert.strictEqual(segments[1].url, 'http://example.com');
    });

    it('should parse text that is only a URL', () => {
      const segments = TextUrl.handleTextUrl('https://example.com/path');
      assert.strictEqual(segments.length, 1);
      assert.strictEqual(segments[0].text, 'https://example.com/path');
      assert.strictEqual(segments[0].url, 'https://example.com/path');
    });

    it('should parse multiple URLs', () => {
      const text = 'see http://a.com and https://b.org end';
      const segments = TextUrl.handleTextUrl(text);
      assert.strictEqual(segments.length, 5);
      assert.strictEqual(segments[0].text, 'see ');
      assert.strictEqual(segments[1].url, 'http://a.com');
      assert.strictEqual(segments[2].text, ' and ');
      assert.strictEqual(segments[3].url, 'https://b.org');
      assert.strictEqual(segments[4].text, ' end');
    });

    it('should skip URLs overlapping with existingUrls', () => {
      const text = 'check http://example.com now';
      const existing: UrlMatch[] = [{ url: 'http://example.com', start: 6, end: 24 }];
      const segments = TextUrl.handleTextUrl(text, existing);
      // All URLs overlap with existing, so result is plain text
      assert.strictEqual(segments.length, 1);
      assert.strictEqual(segments[0].text, text);
      assert.strictEqual(segments[0].url, undefined);
    });

    it('should keep non-overlapping URLs when existingUrls provided', () => {
      const text = 'http://a.com and http://b.com end';
      // Only first URL is already linked
      const existing: UrlMatch[] = [{ url: 'http://a.com', start: 0, end: 12 }];
      const segments = TextUrl.handleTextUrl(text, existing);
      // http://a.com is skipped, http://b.com is detected
      assert.strictEqual(segments.length, 3);
      assert.strictEqual(segments[0].text, 'http://a.com and ');
      assert.strictEqual(segments[0].url, undefined);
      assert.strictEqual(segments[1].text, 'http://b.com');
      assert.strictEqual(segments[1].url, 'http://b.com');
      assert.strictEqual(segments[2].text, ' end');
      assert.strictEqual(segments[2].url, undefined);
    });
  });

  describe('containsUrl', () => {
    it('should return false for plain text', () => {
      assert.strictEqual(TextUrl.containsUrl('hello world'), false);
    });

    it('should return true when text contains a URL', () => {
      assert.strictEqual(TextUrl.containsUrl('visit http://example.com'), true);
    });

    it('should return true for https', () => {
      assert.strictEqual(TextUrl.containsUrl('https://example.com'), true);
    });

    it('should return false for empty string', () => {
      assert.strictEqual(TextUrl.containsUrl(''), false);
    });

    it('should return false for non-http protocol', () => {
      assert.strictEqual(TextUrl.containsUrl('ftp://example.com'), false);
    });
  });
});
