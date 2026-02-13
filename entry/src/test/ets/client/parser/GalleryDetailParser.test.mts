import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { GalleryDetailParser } from '../../../../main/ets/client/parser/GalleryDetailParser.ets';
import { EhException } from '../../../../main/ets/client/exception/EhException.ets';
import { ParseException } from '../../../../main/ets/client/exception/ParseException.ets';
import { OffensiveException } from '../../../../main/ets/client/exception/OffensiveException.ets';

const DETAIL_BODY = `<html><body>
<script>var gid = 12345;var token = "abcdef0123";var apiuid = 100;var apikey = "deadbeef01234567890abcdef0123456"</script>
<div id="gn">Test Gallery Title</div>
<div id="gj">テストギャラリー</div>
<div id="gdc"><div class="cn">Doujinshi</div></div>
<div id="gdn">testuser</div>
<tr><td class="gdt1">Posted:</td><td class="gdt2">2024-01-15 12:00</td></tr>
<tr><td class="gdt1">Length:</td><td class="gdt2">25 pages</td></tr>
<tr><td class="gdt1">Favorited:</td><td class="gdt2">42 times</td></tr>
<tr><td class="gdt1">Language:</td><td class="gdt2">English</td></tr>
<tr><td class="gdt1">File Size:</td><td class="gdt2">100.5 MB</td></tr>
<div id="rating_count">50</div>
<div id="rating_label">Average: 4.25</div>
<div id="gdf">Add to Favorites</div>
<tr><td class="gdt1">tag_row</td><td><div id="taglist">
<tr><td class="tc">language:</td><td><div class="gt" id="td_language:english"><a id="ta_language:english" href="..." class="tl" onclick="...">english</a></div></td></tr>
</div></td></tr>
</body></html>`;

const OFFENSIVE_BODY = '<html><body><p>(And if you choose to ignore this warning, you lose all rights to complain about it in the future.)</p></body></html>';

const ERROR_BODY = '<html><body><div class="d"><p>This gallery has been removed.</p></div></body></html>';

const COMMENT_BODY = `<html><body>
<div class="c3">Posted on 15 January 2024, 12:00 by: &nbsp; <a href="#">user1</a></div><div class="c6" id="comment_1">Great gallery!</div><div class="c7"></div>
<div class="c3">Posted on 16 January 2024, 14:30 by: &nbsp; <a href="#">user2</a></div><div class="c6" id="comment_2">Thanks for sharing</div><div class="c7"></div>
</body></html>`;

const PREVIEW_PAGES_BODY = `<html><body>
<table class="ptt"><tr>
<td class="ptds"><a href="#">1</a></td>
<td class="ptdd"><a href="#">2</a></td>
<td class="ptdd"><a href="#">3</a></td><td class="ptdd"><a href="#">&gt;</a></td>
</tr></table>
</body></html>`;

describe('GalleryDetailParser', () => {
  describe('parse', () => {
    it('should parse gallery detail fields', () => {
      const gd = GalleryDetailParser.parse(DETAIL_BODY);
      assert.strictEqual(gd.gid, 12345);
      assert.strictEqual(gd.token, 'abcdef0123');
      assert.strictEqual(gd.apiUid, 100);
      assert.strictEqual(gd.apiKey, 'deadbeef01234567890abcdef0123456');
      assert.strictEqual(gd.title, 'Test Gallery Title');
      assert.strictEqual(gd.titleJpn, 'テストギャラリー');
      assert.strictEqual(gd.uploader, 'testuser');
      assert.strictEqual(gd.pages, 25);
      assert.strictEqual(gd.language, 'English');
      assert.strictEqual(gd.size, '100.5 MB');
      assert.strictEqual(gd.ratingCount, 50);
      assert.strictEqual(gd.rating, 4.25);
      assert.strictEqual(gd.isFavorited, false);
    });

    it('should throw OffensiveException for offensive content', () => {
      assert.throws(
        () => GalleryDetailParser.parse(OFFENSIVE_BODY),
        (err: Error) => err instanceof OffensiveException,
      );
    });

    it('should throw EhException for error response', () => {
      assert.throws(
        () => GalleryDetailParser.parse(ERROR_BODY),
        (err: Error) => err instanceof EhException && err.message.includes('removed'),
      );
    });

    it('should throw ParseException when detail pattern not found', () => {
      assert.throws(
        () => GalleryDetailParser.parse('<html><body></body></html>'),
        (err: Error) => err instanceof ParseException,
      );
    });
  });

  describe('parseCommentsFromBody', () => {
    it('should parse comments from body HTML', () => {
      const commentList = GalleryDetailParser.parseCommentsFromBody(COMMENT_BODY);
      assert.ok(commentList.comments.length >= 2);
      assert.strictEqual(commentList.comments[0].user, 'user1');
      assert.strictEqual(commentList.comments[0].comment, 'Great gallery!');
      assert.strictEqual(commentList.comments[1].user, 'user2');
    });

    it('should detect hasMore when click to show all is present', () => {
      const body = COMMENT_BODY + '<a href="#">click to show all</a>';
      const commentList = GalleryDetailParser.parseCommentsFromBody(body);
      assert.strictEqual(commentList.hasMore, true);
    });

    it('should set hasMore false when no click to show all', () => {
      const commentList = GalleryDetailParser.parseCommentsFromBody(COMMENT_BODY);
      assert.strictEqual(commentList.hasMore, false);
    });
  });

  describe('parsePreviewPages', () => {
    it('should parse preview page count from pagination', () => {
      const pages = GalleryDetailParser.parsePreviewPages(PREVIEW_PAGES_BODY);
      assert.strictEqual(pages, 3);
    });

    it('should return 0 when no pagination found', () => {
      const pages = GalleryDetailParser.parsePreviewPages('<html></html>');
      assert.strictEqual(pages, 0);
    });
  });
});
