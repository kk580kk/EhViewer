import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { GalleryTagGroup } from '../../../main/ets/model/GalleryTagGroup.ets';

describe('GalleryTagGroup', () => {
  describe('structure (Android-aligned)', () => {
    it('has default groupName and empty tag list', () => {
      const g = new GalleryTagGroup();
      assert.strictEqual(g.groupName, '');
      assert.strictEqual(g.size(), 0);
    });

    it('addTag increases size and getTagAt returns tag at index', () => {
      const g = new GalleryTagGroup();
      g.groupName = 'artist';
      g.addTag('tag1');
      g.addTag('tag2');
      assert.strictEqual(g.size(), 2);
      assert.strictEqual(g.getTagAt(0), 'tag1');
      assert.strictEqual(g.getTagAt(1), 'tag2');
    });

    it('getTags returns all tags in order', () => {
      const g = new GalleryTagGroup();
      g.addTag('a');
      g.addTag('b');
      assert.deepStrictEqual(g.getTags(), ['a', 'b']);
    });
  });

  describe('toJSON / fromJSON', () => {
    it('round-trips groupName and tagList', () => {
      const g = new GalleryTagGroup();
      g.groupName = 'language';
      g.addTag('japanese');
      g.addTag('translated');
      const json = g.toJSON();
      const restored = GalleryTagGroup.fromJSON(json as Record<string, Object | null>);
      assert.strictEqual(restored.groupName, 'language');
      assert.strictEqual(restored.size(), 2);
      assert.strictEqual(restored.getTagAt(0), 'japanese');
      assert.strictEqual(restored.getTagAt(1), 'translated');
    });

    it('fromJSON handles missing or null tagList', () => {
      const empty = GalleryTagGroup.fromJSON({ groupName: 'ns' } as Record<string, Object | null>);
      assert.strictEqual(empty.groupName, 'ns');
      assert.strictEqual(empty.size(), 0);

      const withNull = GalleryTagGroup.fromJSON({
        groupName: 'x',
        tagList: null,
      } as Record<string, Object | null>);
      assert.strictEqual(withNull.size(), 0);
    });
  });
});
