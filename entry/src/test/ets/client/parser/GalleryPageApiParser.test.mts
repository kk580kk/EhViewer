import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { GalleryPageApiParser } from '../../../../main/ets/client/parser/GalleryPageApiParser.ets';
import { ParseException } from '../../../../main/ets/client/exception/ParseException.ets';

// Same fixture as app/src/test/resources/.../GalleryPageApiParserTest.json
const GALLERY_PAGE_API_JSON = `{"p":3,"s":"s/7e7a4305a4/1366222-3","n":"<div class=\\"sn\\"><a onclick=\\"return load_image(1, '3913869966')\\" href=\\"https://e-hentai.org/s/3913869966/1366222-1\\"><img src=\\"https://ehgt.org/g/f.png\\" /></a><a id=\\"prev\\" onclick=\\"return load_image(2, '34972180ed')\\" href=\\"https://e-hentai.org/s/34972180ed/1366222-2\\"><img src=\\"https://ehgt.org/g/p.png\\" /></a><div><span>3</span> / <span>13</span></div><a id=\\"next\\" onclick=\\"return load_image(4, 'd2b5dac191')\\" href=\\"https://e-hentai.org/s/d2b5dac191/1366222-4\\"><img src=\\"https://ehgt.org/g/n.png\\" /></a><a onclick=\\"return load_image(13, 'f264699329')\\" href=\\"https://e-hentai.org/s/f264699329/1366222-13\\"><img src=\\"https://ehgt.org/g/l.png\\" /></a></div>","i":"<div>Valentines_2019_002.jpg :: 1280 x 960 :: 178.8 KB</div>","k":"7e7a4305a4","i3":"<a onclick=\\"return load_image(4, 'd2b5dac191')\\" href=\\"https://e-hentai.org/s/d2b5dac191/1366222-4\\"><img id=\\"img\\" src=\\"http://69.30.203.46:60111/h/6047fa2f194742f6fa541ec1f631ec3ab438f960-183117-1280-960-jpg/keystamp=1550291100-c4438f48c8;fileindex=67379169;xres=1280/Valentines_2019_002.jpg\\" style=\\"height:960px;width:1280px\\" onerror=\\"this.onerror=null; nl('15151-430636')\\" /></a>","i5":"<div class=\\"sb\\"><a href=\\"https://e-hentai.org/g/1366222/c0bf6f0a8e/\\"><img src=\\"https://ehgt.org/g/b.png\\" referrerpolicy=\\"no-referrer\\" /></a></div>","i6":" &nbsp; <img src=\\"https://ehgt.org/g/mr.gif\\" class=\\"mr\\" /> <a href=\\"https://e-hentai.org/?f_shash=7e7a4305a47ebd25a11454003f042f1adc1015b1&amp;fs_from=Valentines_2019_002.jpg+from+%5BMr.+Phoenyxx%5D+Valentines+2019\\">Show all galleries with this file</a>  &nbsp; <img src=\\"https://ehgt.org/g/mr.gif\\" class=\\"mr\\" /> <a href=\\"#\\" onclick=\\"prompt('Copy the URL below.', 'https://e-hentai.org/r/6047fa2f194742f6fa541ec1f631ec3ab438f960-183117-1280-960-jpg/forumtoken/1366222-3/Valentines_2019_002.jpg'); return false\\">Generate a static forum image link</a>  &nbsp; <img src=\\"https://ehgt.org/g/mr.gif\\" class=\\"mr\\" /> <a href=\\"#\\" id=\\"loadfail\\" onclick=\\"return nl('15151-430636')\\">Click here if the image fails loading</a> ","i7":" &nbsp; <img src=\\"https://ehgt.org/g/mr.gif\\" class=\\"mr\\" /> <a href=\\"https://e-hentai.org/fullimg.php?gid=1366222&amp;page=3&amp;key=puxxvyg98a4\\">Download original 1600 x 1200 335.9 KB source</a>","si":15151,"x":"1280","y":"960"}`;

describe('GalleryPageApiParser', () => {
  it('should parse imageUrl, skipHathKey and originImageUrl from gallery page API JSON', () => {
    const result = GalleryPageApiParser.parse(GALLERY_PAGE_API_JSON);
    assert.strictEqual(
      result.imageUrl,
      'http://69.30.203.46:60111/h/6047fa2f194742f6fa541ec1f631ec3ab438f960-183117-1280-960-jpg/keystamp=1550291100-c4438f48c8;fileindex=67379169;xres=1280/Valentines_2019_002.jpg',
    );
    assert.strictEqual(result.skipHathKey, '15151-430636');
    assert.strictEqual(
      result.originImageUrl,
      'https://e-hentai.org/fullimg.php?gid=1366222&page=3&key=puxxvyg98a4',
    );
  });

  it('should throw ParseException when API returns error', () => {
    const body = '{"error":"Invalid request"}';
    assert.throws(
      () => GalleryPageApiParser.parse(body),
      (err: Error) => {
        assert.ok(err instanceof ParseException);
        assert.strictEqual(err.message, 'Invalid request');
        return true;
      },
    );
  });

  it('should throw ParseException for invalid JSON', () => {
    assert.throws(
      () => GalleryPageApiParser.parse('not json'),
      (err: Error) => {
        assert.ok(err instanceof ParseException);
        assert.ok(err.message.includes("Can't parse json"));
        return true;
      },
    );
  });

  it('should throw ParseException when imageUrl is missing', () => {
    const body = '{"i3":"<div>no image here</div>","i6":"","i7":""}';
    assert.throws(
      () => GalleryPageApiParser.parse(body),
      (err: Error) => {
        assert.ok(err instanceof ParseException);
        assert.ok(err.message.includes('Parse image url and skip hath key error'));
        return true;
      },
    );
  });
});
