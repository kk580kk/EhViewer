import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { GalleryPageParser } from '../../../../main/ets/client/parser/GalleryPageParser.ets';
import { ParseException } from '../../../../main/ets/client/exception/ParseException.ets';

const GALLERY_PAGE_HTML = `<!DOCTYPE html>
<html>
<body>
<div id="i3"><a onclick="return load_image(11, 'fab3e858c9')" href="https://e-hentai.org/s/fab3e858c9/1363978-11"><img id="img" src="http://108.6.41.160:2688/h/5c63e9a5810d8d9c873d9e0dfaadc4a0d70a13bf-188862-1280-879-jpg/keystamp=1550291700-145ecbbb10;fileindex=67290651;xres=1280/10.jpg" style="width:1280px;height:879px" onerror="this.onerror=null; nl('26664-430636')" /></a></div>
<div id="i6"><a href="#" id="loadfail" onclick="return nl('26664-430636')">Click here if the image fails loading</a></div>
<div id="i7"><a href="https://e-hentai.org/fullimg.php?gid=1363978&amp;page=10&amp;key=qt2hwrx98a4">Download original</a></div>
<script type="text/javascript">var gid=1363978;var startpage=10;var startkey="49c9e58c17";var showkey="ghz0e5m98a4";var base_url="https://e-hentai.org/";</script>
</body>
</html>`;

describe('GalleryPageParser', () => {
  it('should parse imageUrl, skipHathKey, originImageUrl and showKey from gallery page HTML', () => {
    const result = GalleryPageParser.parse(GALLERY_PAGE_HTML);
    assert.strictEqual(
      result.imageUrl,
      'http://108.6.41.160:2688/h/5c63e9a5810d8d9c873d9e0dfaadc4a0d70a13bf-188862-1280-879-jpg/keystamp=1550291700-145ecbbb10;fileindex=67290651;xres=1280/10.jpg',
    );
    assert.strictEqual(result.skipHathKey, '26664-430636');
    assert.strictEqual(
      result.originImageUrl,
      'https://e-hentai.org/fullimg.php?gid=1363978&page=10&key=qt2hwrx98a4',
    );
    assert.strictEqual(result.showKey, 'ghz0e5m98a4');
  });

  it('should throw ParseException when imageUrl is missing', () => {
    const body = '<html><body><script>var showkey="abc123";</script></body></html>';
    assert.throws(
      () => GalleryPageParser.parse(body),
      (err: Error) => {
        assert.ok(err instanceof ParseException);
        assert.ok(err.message.includes('Parse image url and show error'));
        return true;
      },
    );
  });

  it('should throw ParseException when showKey is missing', () => {
    const body =
      '<html><body><img src="http://example.com/1.jpg" style="width:1px" /></body></html>';
    assert.throws(
      () => GalleryPageParser.parse(body),
      (err: Error) => {
        assert.ok(err instanceof ParseException);
        assert.ok(err.message.includes('Parse image url and show error'));
        return true;
      },
    );
  });

  it('should throw ParseException for empty body', () => {
    assert.throws(
      () => GalleryPageParser.parse(''),
      (err: Error) => {
        assert.ok(err instanceof ParseException);
        return true;
      },
    );
  });
});
