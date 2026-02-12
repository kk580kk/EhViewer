import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { DataMappers } from '../../../main/ets/viewmodel/DataMappers.ets';
import { GalleryInfo } from '../../../main/ets/model/GalleryInfo.ets';
import { HistoryInfo } from '../../../main/ets/model/HistoryInfo.ets';
import { DownloadInfo } from '../../../main/ets/download/DownloadInfo.ets';
import { EhConfig } from '../../../main/ets/client/EhConfig';

function makeGallery(gid: number, title: string, category: number = EhConfig.DOUJINSHI): GalleryInfo {
  const gi = new GalleryInfo();
  gi.gid = gid;
  gi.token = `tok_${gid}`;
  gi.title = title;
  gi.category = category;
  gi.uploader = 'uploader_x';
  gi.rating = 4.5;
  gi.posted = '2024-01-15';
  gi.simpleLanguage = 'EN';
  return gi;
}

describe('DataMappers', () => {
  describe('toGalleryItem', () => {
    it('should map all fields correctly', () => {
      const gi = makeGallery(100, 'Test Gallery', EhConfig.MANGA);
      const item = DataMappers.toGalleryItem(gi);

      assert.strictEqual(item.gid, 100);
      assert.strictEqual(item.token, 'tok_100');
      assert.strictEqual(item.title, 'Test Gallery');
      assert.strictEqual(item.uploader, 'uploader_x');
      assert.strictEqual(item.rating, 4.5);
      assert.strictEqual(item.category, EhConfig.MANGA);
      assert.strictEqual(item.categoryText, 'manga');
      assert.ok(item.categoryColor.length > 0);
      assert.strictEqual(item.posted, '2024-01-15');
      assert.strictEqual(item.simpleLanguage, 'EN');
    });

    it('should handle null simpleLanguage', () => {
      const gi = makeGallery(1, 'No Lang');
      gi.simpleLanguage = null;
      const item = DataMappers.toGalleryItem(gi);
      assert.strictEqual(item.simpleLanguage, '');
    });
  });

  describe('toHistoryItem', () => {
    it('should map history-specific fields', () => {
      const gi = makeGallery(200, 'History Entry');
      const hi = new HistoryInfo(gi);
      hi.time = 1705334400000; // 2024-01-15 16:00:00 UTC

      const item = DataMappers.toHistoryItem(hi);
      assert.strictEqual(item.gid, 200);
      assert.strictEqual(item.title, 'History Entry');
      assert.strictEqual(item.time, 1705334400000);
      assert.ok(item.timeText.length > 0);
    });

    it('should handle zero time', () => {
      const gi = makeGallery(1, 'Zero Time');
      const hi = new HistoryInfo(gi);
      hi.time = 0;
      const item = DataMappers.toHistoryItem(hi);
      assert.strictEqual(item.timeText, '');
    });
  });

  describe('toDownloadItem', () => {
    it('should map download-specific fields', () => {
      const gi = makeGallery(300, 'Download Entry');
      const di = new DownloadInfo(gi);
      di.state = DownloadInfo.STATE_DOWNLOAD;
      di.finished = 10;
      di.total = 50;
      di.speed = 1024;
      di.label = 'MyLabel';

      const item = DataMappers.toDownloadItem(di);
      assert.strictEqual(item.gid, 300);
      assert.strictEqual(item.stateValue, DownloadInfo.STATE_DOWNLOAD);
      assert.strictEqual(item.stateText, '10/50');
      assert.strictEqual(item.progressPercent, 20);
      assert.strictEqual(item.speed, 1024);
      assert.strictEqual(item.label, 'MyLabel');
      assert.strictEqual(item.canStart, false);
      assert.strictEqual(item.canStop, true);
    });

    it('should set canStart for failed downloads', () => {
      const di = new DownloadInfo(makeGallery(1, 'Failed'));
      di.state = DownloadInfo.STATE_FAILED;
      const item = DataMappers.toDownloadItem(di);
      assert.strictEqual(item.canStart, true);
      assert.strictEqual(item.canStop, false);
    });
  });

  describe('batch mappers', () => {
    it('toGalleryItems should map array', () => {
      const list = [makeGallery(1, 'A'), makeGallery(2, 'B')];
      const items = DataMappers.toGalleryItems(list);
      assert.strictEqual(items.length, 2);
      assert.strictEqual(items[0].gid, 1);
      assert.strictEqual(items[1].gid, 2);
    });

    it('toHistoryItems should map array', () => {
      const list = [new HistoryInfo(makeGallery(1, 'A')), new HistoryInfo(makeGallery(2, 'B'))];
      list[0].time = 1000;
      list[1].time = 2000;
      const items = DataMappers.toHistoryItems(list);
      assert.strictEqual(items.length, 2);
    });

    it('toDownloadItems should map array', () => {
      const list = [new DownloadInfo(makeGallery(1, 'A')), new DownloadInfo(makeGallery(2, 'B'))];
      const items = DataMappers.toDownloadItems(list);
      assert.strictEqual(items.length, 2);
    });

    it('should return empty array for empty input', () => {
      assert.deepStrictEqual(DataMappers.toGalleryItems([]), []);
      assert.deepStrictEqual(DataMappers.toHistoryItems([]), []);
      assert.deepStrictEqual(DataMappers.toDownloadItems([]), []);
    });
  });
});
