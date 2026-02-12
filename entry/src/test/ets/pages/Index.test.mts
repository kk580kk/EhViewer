import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  TAB_ITEMS,
  TAB_COUNT,
  TAB_GALLERY,
  TAB_FAVORITES,
  TAB_HISTORY,
  TAB_DOWNLOADS,
  TAB_SETTINGS,
  getTabTitle,
} from '../../../main/ets/router/TabConfig.ets';

describe('TAB_ITEMS configuration', () => {
  it('should have exactly 5 tabs', () => {
    assert.strictEqual(TAB_ITEMS.length, 5);
    assert.strictEqual(TAB_COUNT, 5);
  });

  it('should have correct tab titles', () => {
    const titles = TAB_ITEMS.map(t => t.title);
    assert.deepStrictEqual(titles, [
      'Gallery', 'Favorites', 'History', 'Downloads', 'Settings',
    ]);
  });

  it('each tab should have non-empty icon and iconSelected', () => {
    for (const tab of TAB_ITEMS) {
      assert.ok(tab.icon.length > 0, `${tab.title} icon is empty`);
      assert.ok(tab.iconSelected.length > 0, `${tab.title} iconSelected is empty`);
    }
  });
});

describe('Tab index constants', () => {
  it('should be sequential from 0 to 4', () => {
    assert.strictEqual(TAB_GALLERY,   0);
    assert.strictEqual(TAB_FAVORITES, 1);
    assert.strictEqual(TAB_HISTORY,   2);
    assert.strictEqual(TAB_DOWNLOADS, 3);
    assert.strictEqual(TAB_SETTINGS,  4);
  });

  it('should map to correct TAB_ITEMS entries', () => {
    assert.strictEqual(TAB_ITEMS[TAB_GALLERY].title,   'Gallery');
    assert.strictEqual(TAB_ITEMS[TAB_FAVORITES].title,  'Favorites');
    assert.strictEqual(TAB_ITEMS[TAB_HISTORY].title,    'History');
    assert.strictEqual(TAB_ITEMS[TAB_DOWNLOADS].title,  'Downloads');
    assert.strictEqual(TAB_ITEMS[TAB_SETTINGS].title,   'Settings');
  });
});

describe('getTabTitle', () => {
  it('should return correct title for valid index', () => {
    assert.strictEqual(getTabTitle(0), 'Gallery');
    assert.strictEqual(getTabTitle(4), 'Settings');
  });

  it('should return empty string for out-of-bounds index', () => {
    assert.strictEqual(getTabTitle(-1), '');
    assert.strictEqual(getTabTitle(5), '');
    assert.strictEqual(getTabTitle(999), '');
  });
});
