import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { GalleryDetail } from '../../../main/ets/model/GalleryDetail.ets';
import { GalleryTagGroup } from '../../../main/ets/model/GalleryTagGroup.ets';
import { GalleryComment, GalleryCommentList } from '../../../main/ets/model/GalleryComment.ets';
import { LargePreviewSet } from '../../../main/ets/model/LargePreviewSet.ets';
import { NormalPreviewSet } from '../../../main/ets/model/NormalPreviewSet.ets';

describe('GalleryDetail', () => {
  describe('fromJSON / toJSON', () => {
    it('round-trips a minimal detail', () => {
      const d = new GalleryDetail();
      d.gid = 100;
      d.token = 'abc';
      d.title = 'Test Gallery';
      d.pages = 10;
      d.language = 'Japanese';
      d.size = '50 MB';
      d.favoriteCount = 5;
      d.ratingCount = 20;
      d.posted = '2024-01-01 12:00';

      const json = d.toJSON();
      const restored = GalleryDetail.fromJSON(json as Record<string, Object | null>);
      assert.strictEqual(restored.gid, 100);
      assert.strictEqual(restored.token, 'abc');
      assert.strictEqual(restored.title, 'Test Gallery');
      assert.strictEqual(restored.pages, 10);
      assert.strictEqual(restored.language, 'Japanese');
      assert.strictEqual(restored.size, '50 MB');
      assert.strictEqual(restored.favoriteCount, 5);
      assert.strictEqual(restored.ratingCount, 20);
      assert.strictEqual(restored.posted, '2024-01-01 12:00');
    });

    it('round-trips tags', () => {
      const d = new GalleryDetail();
      const g = new GalleryTagGroup();
      g.groupName = 'artist';
      g.addTag('tag1');
      g.addTag('tag2');
      d.tags = [g];

      const json = d.toJSON();
      const restored = GalleryDetail.fromJSON(json as Record<string, Object | null>);
      assert.strictEqual(restored.tags.length, 1);
      assert.strictEqual(restored.tags[0].groupName, 'artist');
      assert.deepStrictEqual(restored.tags[0].getTags(), ['tag1', 'tag2']);
    });

    it('round-trips comments', () => {
      const d = new GalleryDetail();
      const list = new GalleryCommentList();
      const c = new GalleryComment();
      c.id = 1;
      c.user = 'u';
      c.comment = 'text';
      list.comments = [c];
      list.hasMore = true;
      d.comments = list;

      const json = d.toJSON();
      const restored = GalleryDetail.fromJSON(json as Record<string, Object | null>);
      assert.strictEqual(restored.comments.comments.length, 1);
      assert.strictEqual(restored.comments.comments[0].user, 'u');
      assert.strictEqual(restored.comments.comments[0].comment, 'text');
      assert.strictEqual(restored.comments.hasMore, true);
    });

    it('round-trips LargePreviewSet', () => {
      const d = new GalleryDetail();
      d.gid = 1;
      const ps = new LargePreviewSet();
      ps.addItem(0, 'http://a/b.jpg', 'http://page/0');
      ps.addItem(1, 'http://a/c.jpg', 'http://page/1');
      d.previewSet = ps;
      d.previewPages = 2;

      const json = d.toJSON();
      const restored = GalleryDetail.fromJSON(json as Record<string, Object | null>);
      assert.ok(restored.previewSet !== null);
      assert.strictEqual(restored.previewSet!.size(), 2);
      const p0 = restored.previewSet!.getGalleryPreview(1, 0);
      assert.strictEqual(p0.imageUrl, 'http://a/b.jpg');
      assert.strictEqual(p0.pageUrl, 'http://page/0');
    });

    it('round-trips NormalPreviewSet', () => {
      const d = new GalleryDetail();
      d.gid = 2;
      const ps = new NormalPreviewSet();
      ps.addItem(0, 'http://img/0.jpg', 0, 0, 100, 140, 'http://p/0');
      d.previewSet = ps;

      const json = d.toJSON();
      const restored = GalleryDetail.fromJSON(json as Record<string, Object | null>);
      assert.ok(restored.previewSet !== null);
      assert.strictEqual(restored.previewSet!.size(), 1);
    });
  });

  describe('copyFrom', () => {
    it('copies all detail fields from another GalleryDetail', () => {
      const src = new GalleryDetail();
      src.gid = 1;
      src.token = 't';
      src.title = 'A';
      src.pages = 5;
      src.language = 'EN';
      src.size = '10 MB';
      src.apiUid = 99;
      src.torrentCount = 2;
      src.favoriteCount = 10;
      src.ratingCount = 50;
      src.posted = '2024-06-01';

      const dest = new GalleryDetail();
      dest.copyFrom(src);
      assert.strictEqual(dest.gid, 1);
      assert.strictEqual(dest.token, 't');
      assert.strictEqual(dest.title, 'A');
      assert.strictEqual(dest.pages, 5);
      assert.strictEqual(dest.language, 'EN');
      assert.strictEqual(dest.size, '10 MB');
      assert.strictEqual(dest.apiUid, 99);
      assert.strictEqual(dest.torrentCount, 2);
      assert.strictEqual(dest.favoriteCount, 10);
      assert.strictEqual(dest.ratingCount, 50);
      assert.strictEqual(dest.posted, '2024-06-01');
    });
  });
});
