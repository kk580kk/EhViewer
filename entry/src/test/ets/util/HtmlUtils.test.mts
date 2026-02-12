import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { HtmlUtils, HtmlLink, HtmlImage } from '../../../main/ets/util/HtmlUtils.ets';

describe('HtmlUtils', () => {

  describe('stripHtml', () => {
    it('should return empty string for empty input', () => {
      assert.strictEqual(HtmlUtils.stripHtml(''), '');
    });

    it('should strip simple HTML tags', () => {
      assert.strictEqual(HtmlUtils.stripHtml('<b>bold</b>'), 'bold');
    });

    it('should convert <br> to newline', () => {
      assert.strictEqual(HtmlUtils.stripHtml('line1<br>line2'), 'line1\nline2');
    });

    it('should convert <br/> and <br /> variants', () => {
      assert.strictEqual(HtmlUtils.stripHtml('a<br/>b<br />c'), 'a\nb\nc');
    });

    it('should convert </p> to double newline', () => {
      const result = HtmlUtils.stripHtml('<p>first</p><p>second</p>');
      assert.ok(result.includes('first'));
      assert.ok(result.includes('second'));
    });

    it('should strip nested HTML tags', () => {
      assert.strictEqual(HtmlUtils.stripHtml('<div><span>hello</span></div>'), 'hello');
    });

    it('should decode entities in stripped text', () => {
      assert.strictEqual(HtmlUtils.stripHtml('<p>A &amp; B</p>'), 'A & B');
    });

    it('should handle tags with attributes', () => {
      assert.strictEqual(
        HtmlUtils.stripHtml('<a href="http://example.com">link</a>'),
        'link',
      );
    });

    it('should collapse multiple blank lines', () => {
      const result = HtmlUtils.stripHtml('<p>a</p><p></p><p></p><p>b</p>');
      assert.ok(!result.includes('\n\n\n'));
    });
  });

  describe('decodeEntities', () => {
    it('should decode common named entities', () => {
      assert.strictEqual(HtmlUtils.decodeEntities('&amp;'), '&');
      assert.strictEqual(HtmlUtils.decodeEntities('&lt;'), '<');
      assert.strictEqual(HtmlUtils.decodeEntities('&gt;'), '>');
      assert.strictEqual(HtmlUtils.decodeEntities('&quot;'), '"');
      assert.strictEqual(HtmlUtils.decodeEntities('&#39;'), "'");
      assert.strictEqual(HtmlUtils.decodeEntities('&nbsp;'), ' ');
    });

    it('should decode decimal numeric references', () => {
      assert.strictEqual(HtmlUtils.decodeEntities('&#65;'), 'A');
      assert.strictEqual(HtmlUtils.decodeEntities('&#97;'), 'a');
    });

    it('should decode hex numeric references', () => {
      assert.strictEqual(HtmlUtils.decodeEntities('&#x41;'), 'A');
      assert.strictEqual(HtmlUtils.decodeEntities('&#x61;'), 'a');
    });

    it('should handle mixed content', () => {
      assert.strictEqual(
        HtmlUtils.decodeEntities('A &amp; B &#x3E; C'),
        'A & B > C',
      );
    });

    it('should leave unknown entities as-is', () => {
      assert.strictEqual(HtmlUtils.decodeEntities('&unknown;'), '&unknown;');
    });
  });

  describe('extractLinks', () => {
    it('should return empty array for no links', () => {
      assert.deepStrictEqual(HtmlUtils.extractLinks('<p>no links</p>'), []);
    });

    it('should extract a single link', () => {
      const html = '<a href="http://example.com">Example</a>';
      const links = HtmlUtils.extractLinks(html);
      assert.strictEqual(links.length, 1);
      assert.strictEqual(links[0].url, 'http://example.com');
      assert.strictEqual(links[0].text, 'Example');
    });

    it('should extract multiple links', () => {
      const html = '<a href="http://a.com">A</a> and <a href="http://b.com">B</a>';
      const links = HtmlUtils.extractLinks(html);
      assert.strictEqual(links.length, 2);
      assert.strictEqual(links[0].url, 'http://a.com');
      assert.strictEqual(links[1].url, 'http://b.com');
    });

    it('should strip HTML from link text', () => {
      const html = '<a href="http://x.com"><b>Bold Link</b></a>';
      const links = HtmlUtils.extractLinks(html);
      assert.strictEqual(links[0].text, 'Bold Link');
    });

    it('should handle single-quoted href', () => {
      const html = "<a href='http://q.com'>Q</a>";
      const links = HtmlUtils.extractLinks(html);
      assert.strictEqual(links.length, 1);
      assert.strictEqual(links[0].url, 'http://q.com');
    });
  });

  describe('extractImages', () => {
    it('should return empty array for no images', () => {
      assert.deepStrictEqual(HtmlUtils.extractImages('<p>text</p>'), []);
    });

    it('should extract image src', () => {
      const html = '<img src="http://img.com/pic.jpg">';
      const images = HtmlUtils.extractImages(html);
      assert.strictEqual(images.length, 1);
      assert.strictEqual(images[0].src, 'http://img.com/pic.jpg');
    });

    it('should extract alt text', () => {
      const html = '<img src="pic.jpg" alt="A picture">';
      const images = HtmlUtils.extractImages(html);
      assert.strictEqual(images[0].alt, 'A picture');
    });

    it('should handle missing alt', () => {
      const html = '<img src="pic.jpg">';
      const images = HtmlUtils.extractImages(html);
      assert.strictEqual(images[0].alt, '');
    });

    it('should extract multiple images', () => {
      const html = '<img src="a.jpg"><img src="b.png">';
      const images = HtmlUtils.extractImages(html);
      assert.strictEqual(images.length, 2);
    });
  });

  describe('escapeHtml', () => {
    it('should escape special characters', () => {
      assert.strictEqual(HtmlUtils.escapeHtml('<div>'), '&lt;div&gt;');
      assert.strictEqual(HtmlUtils.escapeHtml('"quotes"'), '&quot;quotes&quot;');
      assert.strictEqual(HtmlUtils.escapeHtml("it's"), "it&#39;s");
      assert.strictEqual(HtmlUtils.escapeHtml('A & B'), 'A &amp; B');
    });

    it('should not modify plain text', () => {
      assert.strictEqual(HtmlUtils.escapeHtml('hello world'), 'hello world');
    });
  });

  describe('truncate', () => {
    it('should not truncate short text', () => {
      assert.strictEqual(HtmlUtils.truncate('hello', 10), 'hello');
    });

    it('should truncate and add ellipsis', () => {
      const result = HtmlUtils.truncate('hello world this is a long text', 11);
      assert.ok(result.length <= 12); // 11 + ellipsis char
      assert.ok(result.endsWith('\u2026'));
    });

    it('should handle exact length', () => {
      assert.strictEqual(HtmlUtils.truncate('12345', 5), '12345');
    });
  });
});
