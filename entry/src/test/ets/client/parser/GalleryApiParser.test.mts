import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { GalleryApiParser } from '../../../../main/ets/client/parser/GalleryApiParser.ets';
import { GalleryInfo } from '../../../../main/ets/model/GalleryInfo.ets';

describe('GalleryApiParser', () => {
  it('should parse gallery API JSON and fill matching GalleryInfo', () => {
    const body = JSON.stringify({
      gmetadata: [{
        gid: 12345,
        token: 'abcdef1234',
        title: 'Test Gallery',
        title_jpn: 'テストギャラリー',
        category: 'Doujinshi',
        thumb: 'https://ehgt.org/ab/cd/thumb.jpg',
        uploader: 'testuser',
        posted: '1550000000',
        rating: '4.25',
        tags: ['language:english', 'parody:original'],
        filecount: '25',
      }],
    });

    const list: GalleryInfo[] = [];
    const gi = new GalleryInfo();
    gi.gid = 12345;
    list.push(gi);

    GalleryApiParser.parse(body, list);

    assert.strictEqual(gi.title, 'Test Gallery');
    assert.strictEqual(gi.titleJpn, 'テストギャラリー');
    assert.strictEqual(gi.uploader, 'testuser');
    assert.strictEqual(gi.rating, 4.25);
    assert.ok(gi.simpleTags !== null);
    assert.strictEqual(gi.simpleTags!.length, 2);
    assert.strictEqual(gi.simpleTags![0], 'language:english');
    assert.strictEqual(gi.pages, 25);
    assert.strictEqual(gi.simpleLanguage, GalleryInfo.S_LANG_EN);
  });

  it('should not update GalleryInfo when gid does not match', () => {
    const body = JSON.stringify({
      gmetadata: [{
        gid: 99999,
        token: 'abcdef1234',
        title: 'Other Gallery',
        title_jpn: '',
        category: 'Manga',
        thumb: 'https://ehgt.org/thumb.jpg',
        uploader: 'other',
        posted: '1550000000',
        rating: '3.0',
        tags: [],
        filecount: '10',
      }],
    });

    const list: GalleryInfo[] = [];
    const gi = new GalleryInfo();
    gi.gid = 12345;
    list.push(gi);

    GalleryApiParser.parse(body, list);

    assert.strictEqual(gi.title, '');
  });

  it('should handle empty gmetadata array', () => {
    const body = JSON.stringify({ gmetadata: [] });
    const list: GalleryInfo[] = [];
    const gi = new GalleryInfo();
    gi.gid = 1;
    list.push(gi);

    GalleryApiParser.parse(body, list);

    assert.strictEqual(gi.title, '');
  });
});
