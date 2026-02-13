import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { DownloadManager } from '../../../main/ets/download/DownloadManager.ets';
import { MemoryDownloadDB } from '../../../main/ets/download/MemoryDownloadDB.ets';
import { DownloadInfo } from '../../../main/ets/download/DownloadInfo.ets';
import { DownloadProgressEvent } from '../../../main/ets/download/DownloadProgressEvent.ets';
import type { DownloadProgressCallback } from '../../../main/ets/download/DownloadProgressCallback.ets';
import { GalleryInfo } from '../../../main/ets/model/GalleryInfo.ets';

function makeGallery(gid: number): GalleryInfo {
  const gi = new GalleryInfo();
  gi.gid = gid;
  gi.token = `tok_${gid}`;
  gi.title = `Gallery ${gid}`;
  gi.category = 2;
  gi.uploader = 'test';
  gi.rating = 4.0;
  return gi;
}

/** Records all callback invocations for assertions. */
class SpyProgressCallback implements DownloadProgressCallback {
  progressEvents: DownloadProgressEvent[] = [];
  stateChangedEvents: DownloadProgressEvent[] = [];

  onDownloadProgress(event: DownloadProgressEvent): void {
    this.progressEvents.push(event);
  }
  onDownloadStateChanged(event: DownloadProgressEvent): void {
    this.stateChangedEvents.push(event);
  }
}

describe('DownloadProgressCallback integration', () => {
  let db: MemoryDownloadDB;
  let dm: DownloadManager;
  let spy: SpyProgressCallback;

  beforeEach(() => {
    db = new MemoryDownloadDB();
    dm = new DownloadManager(db);
    spy = new SpyProgressCallback();
    dm.addProgressCallback(spy);
  });

  it('should fire onDownloadStateChanged when download starts', () => {
    dm.startDownload(makeGallery(1));
    assert.strictEqual(spy.stateChangedEvents.length, 1);
    assert.strictEqual(spy.stateChangedEvents[0].gid, 1);
    assert.strictEqual(spy.stateChangedEvents[0].state, DownloadInfo.STATE_DOWNLOAD);
    assert.ok(spy.stateChangedEvents[0].isActive());
  });

  it('should fire onDownloadProgress when download starts', () => {
    dm.startDownload(makeGallery(1));
    assert.strictEqual(spy.progressEvents.length, 1);
    assert.strictEqual(spy.progressEvents[0].gid, 1);
  });

  it('should fire onDownloadStateChanged when download is cancelled', () => {
    dm.startDownload(makeGallery(1));
    spy.stateChangedEvents = [];
    spy.progressEvents = [];

    dm.stopDownload(1);
    assert.strictEqual(spy.stateChangedEvents.length, 1);
    assert.strictEqual(spy.stateChangedEvents[0].state, DownloadInfo.STATE_NONE);
    assert.ok(!spy.stateChangedEvents[0].isActive());
  });

  it('should fire onDownloadStateChanged when download finishes successfully', () => {
    dm.startDownload(makeGallery(1));
    spy.stateChangedEvents = [];

    dm.onDownloadFinished(10, 10, 10);
    assert.strictEqual(spy.stateChangedEvents.length, 1);
    assert.strictEqual(spy.stateChangedEvents[0].state, DownloadInfo.STATE_FINISH);
    assert.strictEqual(spy.stateChangedEvents[0].progressPercent, 100);
  });

  it('should fire onDownloadStateChanged when download finishes with failures', () => {
    dm.startDownload(makeGallery(1));
    spy.stateChangedEvents = [];

    dm.onDownloadFinished(8, 10, 10);
    assert.strictEqual(spy.stateChangedEvents.length, 1);
    assert.strictEqual(spy.stateChangedEvents[0].state, DownloadInfo.STATE_FAILED);
    assert.ok(spy.stateChangedEvents[0].statusText.includes('Failed'));
    assert.ok(spy.stateChangedEvents[0].statusText.includes('2'));
  });

  it('should fire progress-only (no state change) on onDownloadProgress', () => {
    dm.startDownload(makeGallery(1));
    spy.stateChangedEvents = [];
    spy.progressEvents = [];

    dm.onDownloadProgress(5, 5, 10, 2048, 30000);
    assert.strictEqual(spy.progressEvents.length, 1);
    assert.strictEqual(spy.stateChangedEvents.length, 0);

    const event = spy.progressEvents[0];
    assert.strictEqual(event.gid, 1);
    assert.strictEqual(event.finished, 5);
    assert.strictEqual(event.total, 10);
    assert.strictEqual(event.progressPercent, 50);
    assert.strictEqual(event.speed, 2048);
    assert.strictEqual(event.remaining, 30000);
    assert.ok(event.isDeterminate());
    assert.ok(event.speedText !== null);
  });

  it('should not fire callbacks after removal', () => {
    dm.removeProgressCallback(spy);
    dm.startDownload(makeGallery(1));
    assert.strictEqual(spy.stateChangedEvents.length, 0);
    assert.strictEqual(spy.progressEvents.length, 0);
  });

  it('should fire state change on stopAllDownload', () => {
    dm.startDownload(makeGallery(1));
    spy.stateChangedEvents = [];

    dm.stopAllDownload();
    // stopAllDownload stops the current download which fires state change
    assert.ok(spy.stateChangedEvents.length >= 1);
    const lastEvent = spy.stateChangedEvents[spy.stateChangedEvents.length - 1];
    assert.strictEqual(lastEvent.state, DownloadInfo.STATE_NONE);
  });

  it('should chain downloads and fire callbacks for second task', () => {
    dm.startDownload(makeGallery(1));
    dm.startDownload(makeGallery(2));
    spy.stateChangedEvents = [];
    spy.progressEvents = [];

    // Finish first download — second should start automatically
    dm.onDownloadFinished(10, 10, 10);

    // Should have: finish for gid=1 + start for gid=2
    const finishEvent = spy.stateChangedEvents.find(e => e.gid === 1);
    const startEvent = spy.stateChangedEvents.find(e => e.gid === 2);
    assert.ok(finishEvent !== undefined);
    assert.strictEqual(finishEvent!.state, DownloadInfo.STATE_FINISH);
    assert.ok(startEvent !== undefined);
    assert.strictEqual(startEvent!.state, DownloadInfo.STATE_DOWNLOAD);
  });
});

describe('DownloadProgressEvent', () => {
  it('from() creates correct event for downloading state', () => {
    const info = new DownloadInfo();
    info.gid = 42;
    info.state = DownloadInfo.STATE_DOWNLOAD;
    info.finished = 5;
    info.total = 10;
    info.speed = 2048;
    info.remaining = 60000;

    const event = DownloadProgressEvent.from(info);
    assert.strictEqual(event.gid, 42);
    assert.strictEqual(event.state, DownloadInfo.STATE_DOWNLOAD);
    assert.strictEqual(event.finished, 5);
    assert.strictEqual(event.total, 10);
    assert.strictEqual(event.progressPercent, 50);
    assert.strictEqual(event.speed, 2048);
    assert.strictEqual(event.remaining, 60000);
    assert.ok(event.isDeterminate());
    assert.ok(event.isActive());
    assert.strictEqual(event.statusText, '5/10');
    assert.ok(event.speedText !== null);
    assert.ok(event.speedText!.includes('/s'));
  });

  it('from() creates correct event for finished state', () => {
    const info = new DownloadInfo();
    info.gid = 99;
    info.state = DownloadInfo.STATE_FINISH;
    info.finished = 10;
    info.total = 10;

    const event = DownloadProgressEvent.from(info);
    assert.strictEqual(event.progressPercent, 100);
    assert.strictEqual(event.statusText, 'Completed');
    assert.strictEqual(event.speedText, null);
    assert.ok(!event.isActive());
  });

  it('from() creates correct event for waiting state', () => {
    const info = new DownloadInfo();
    info.gid = 10;
    info.state = DownloadInfo.STATE_WAIT;

    const event = DownloadProgressEvent.from(info);
    assert.strictEqual(event.progressPercent, -1);
    assert.strictEqual(event.statusText, 'Waiting');
    assert.ok(event.isActive());
    assert.ok(!event.isDeterminate());
  });

  it('from() creates correct event for none state', () => {
    const info = new DownloadInfo();
    info.gid = 5;
    info.state = DownloadInfo.STATE_NONE;

    const event = DownloadProgressEvent.from(info);
    assert.strictEqual(event.statusText, 'Not started');
    assert.ok(!event.isActive());
    assert.strictEqual(event.speedText, null);
  });

  it('from() creates correct event for failed state with legacy', () => {
    const info = new DownloadInfo();
    info.gid = 7;
    info.state = DownloadInfo.STATE_FAILED;
    info.legacy = 3;

    const event = DownloadProgressEvent.from(info);
    assert.ok(event.statusText.includes('Failed'));
    assert.ok(event.statusText.includes('3'));
    assert.ok(!event.isActive());
  });

  it('from() handles indeterminate download progress', () => {
    const info = new DownloadInfo();
    info.gid = 8;
    info.state = DownloadInfo.STATE_DOWNLOAD;
    info.finished = -1;
    info.total = -1;
    info.speed = 0;
    info.remaining = -1;

    const event = DownloadProgressEvent.from(info);
    assert.strictEqual(event.progressPercent, -1);
    assert.ok(!event.isDeterminate());
    assert.strictEqual(event.statusText, 'Downloading...');
  });

  it('speedText includes remaining time when available', () => {
    const info = new DownloadInfo();
    info.state = DownloadInfo.STATE_DOWNLOAD;
    info.speed = 1024 * 1024; // 1MB/s
    info.remaining = 120000; // 2 minutes

    const event = DownloadProgressEvent.from(info);
    assert.ok(event.speedText !== null);
    assert.ok(event.speedText!.includes('left'));
    assert.ok(event.speedText!.includes('2m'));
  });

  it('speedText omits remaining when not available', () => {
    const info = new DownloadInfo();
    info.state = DownloadInfo.STATE_DOWNLOAD;
    info.speed = 512;
    info.remaining = -1;

    const event = DownloadProgressEvent.from(info);
    assert.ok(event.speedText !== null);
    assert.ok(!event.speedText!.includes('left'));
  });
});

describe('DownloadInfo progress helpers', () => {
  it('getProgressPercent returns -1 for STATE_NONE', () => {
    const info = new DownloadInfo();
    info.state = DownloadInfo.STATE_NONE;
    assert.strictEqual(info.getProgressPercent(), -1);
  });

  it('getProgressPercent returns -1 for STATE_WAIT', () => {
    const info = new DownloadInfo();
    info.state = DownloadInfo.STATE_WAIT;
    assert.strictEqual(info.getProgressPercent(), -1);
  });

  it('getProgressPercent returns 100 for STATE_FINISH', () => {
    const info = new DownloadInfo();
    info.state = DownloadInfo.STATE_FINISH;
    assert.strictEqual(info.getProgressPercent(), 100);
  });

  it('getProgressPercent returns -1 for STATE_FAILED', () => {
    const info = new DownloadInfo();
    info.state = DownloadInfo.STATE_FAILED;
    assert.strictEqual(info.getProgressPercent(), -1);
  });

  it('getProgressPercent returns correct percentage when downloading', () => {
    const info = new DownloadInfo();
    info.state = DownloadInfo.STATE_DOWNLOAD;
    info.finished = 50;
    info.total = 100;
    assert.strictEqual(info.getProgressPercent(), 50);
  });

  it('getProgressPercent returns 0 when finished is 0', () => {
    const info = new DownloadInfo();
    info.state = DownloadInfo.STATE_DOWNLOAD;
    info.finished = 0;
    info.total = 100;
    assert.strictEqual(info.getProgressPercent(), 0);
  });

  it('getProgressPercent returns -1 when total is 0', () => {
    const info = new DownloadInfo();
    info.state = DownloadInfo.STATE_DOWNLOAD;
    info.finished = 0;
    info.total = 0;
    assert.strictEqual(info.getProgressPercent(), -1);
  });

  it('getProgressPercent returns -1 when total is negative', () => {
    const info = new DownloadInfo();
    info.state = DownloadInfo.STATE_DOWNLOAD;
    info.finished = 0;
    info.total = -1;
    assert.strictEqual(info.getProgressPercent(), -1);
  });

  it('getProgressPercent returns -1 when finished is negative', () => {
    const info = new DownloadInfo();
    info.state = DownloadInfo.STATE_DOWNLOAD;
    info.finished = -1;
    info.total = 100;
    assert.strictEqual(info.getProgressPercent(), -1);
  });

  it('isActive returns true for STATE_WAIT', () => {
    const info = new DownloadInfo();
    info.state = DownloadInfo.STATE_WAIT;
    assert.ok(info.isActive());
  });

  it('isActive returns true for STATE_DOWNLOAD', () => {
    const info = new DownloadInfo();
    info.state = DownloadInfo.STATE_DOWNLOAD;
    assert.ok(info.isActive());
  });

  it('isActive returns false for STATE_NONE', () => {
    const info = new DownloadInfo();
    info.state = DownloadInfo.STATE_NONE;
    assert.ok(!info.isActive());
  });

  it('isActive returns false for STATE_FINISH', () => {
    const info = new DownloadInfo();
    info.state = DownloadInfo.STATE_FINISH;
    assert.ok(!info.isActive());
  });

  it('isActive returns false for STATE_FAILED', () => {
    const info = new DownloadInfo();
    info.state = DownloadInfo.STATE_FAILED;
    assert.ok(!info.isActive());
  });
});
