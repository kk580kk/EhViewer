import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { GalleryListParser } from '../../../../main/ets/client/parser/GalleryListParser.ets';
import { ParseException } from '../../../../main/ets/client/exception/ParseException.ets';

const NO_HITS_BODY = '<html><body>No hits found</p></body></html>';

const MINIMAL_LIST_BODY = `<html><body>
<table class="itg"><tbody>
<tr class="gtr0">
  <td class="gl1e"><div id="glthumb_12345"><a href="https://e-hentai.org/g/12345/abcdef0123/"><img data-src="https://ehgt.org/ab/cd/abcdef.jpg" /></a></div></td>
  <td class="gl3e">
    <div class="cn">Doujinshi</div>
    <a href="https://e-hentai.org/g/12345/abcdef0123/">Test Gallery Title</a>
    <div class="ir irg " style="background-position:0px -1px;opacity:1"></div>
    <div id="posted_12345" style="">2024-01-15 12:00</div>
    <div class="glhide"><a href="https://e-hentai.org/uploader/testuser">testuser</a></div>
    <div>25 pages</div>
  </td>
</tr>
</tbody></table>
</body></html>`;

const WATCHED_NO_TAGS_BODY = '<html><body><p>You do not have any watched tags</p>No hits found</p></body></html>';

const PAGINATED_BODY = `<html><body>
<table class="ptt"><tr>
<td onclick="d()"><a href="https://e-hentai.org/?page=0">1</a></td>
<td onclick="d()"><a href="https://e-hentai.org/?page=1">2</a></td>
<td class="ptds">3</td>
<td onclick="d()"><a href="https://e-hentai.org/?page=1">&gt;</a></td>
</tr></table>
<table class="itg"><tbody>
<tr class="gtr0">
  <td><a href="https://e-hentai.org/g/100/aaaaaaaaaa/">Gallery One</a></td>
  <td class="gl3e">
    <div class="cn">Manga</div>
    <a href="https://e-hentai.org/g/100/aaaaaaaaaa/">Gallery One</a>
    <div id="posted_100" style="">2024-01-01</div>
  </td>
</tr>
</tbody></table>
</body></html>`;

describe('GalleryListParser', () => {
  it('should return empty list and pages=0 for No hits found', () => {
    const result = GalleryListParser.parse(NO_HITS_BODY);
    assert.strictEqual(result.galleryInfoList.length, 0);
    assert.strictEqual(result.pages, 0);
  });

  it('should detect noWatchedTags', () => {
    const result = GalleryListParser.parse(WATCHED_NO_TAGS_BODY);
    assert.strictEqual(result.noWatchedTags, true);
    assert.strictEqual(result.galleryInfoList.length, 0);
  });

  it('should parse minimal gallery list', () => {
    const result = GalleryListParser.parse(MINIMAL_LIST_BODY);
    assert.ok(result.galleryInfoList.length > 0);
    const gi = result.galleryInfoList[0];
    assert.strictEqual(gi.gid, 12345);
    assert.strictEqual(gi.token, 'abcdef0123');
    assert.ok(gi.title.includes('Test Gallery Title'));
  });

  it('should parse pages from pagination', () => {
    const result = GalleryListParser.parse(PAGINATED_BODY);
    assert.strictEqual(result.pages, 3);
    assert.strictEqual(result.nextPage, 1);
  });

  it('should set noWatchedTags to false for normal body', () => {
    const result = GalleryListParser.parse(MINIMAL_LIST_BODY);
    assert.strictEqual(result.noWatchedTags, false);
  });
});
