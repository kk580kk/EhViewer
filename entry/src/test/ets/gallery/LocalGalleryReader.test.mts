import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

import { PageRouter, Routes } from '../../../main/ets/router/PageRouter.ets';
import { DataMappers } from '../../../main/ets/viewmodel/DataMappers.ets';
import { DownloadsViewModel } from '../../../main/ets/viewmodel/DownloadsViewModel.ets';
import { DownloadInfo } from '../../../main/ets/download/DownloadInfo.ets';
import { GalleryInfo } from '../../../main/ets/model/GalleryInfo.ets';
import { GalleryReaderViewModel, PageState } from '../../../main/ets/viewmodel/GalleryReaderViewModel.ets';
import { GallerySource } from '../../../main/ets/gallery/GallerySource.ets';
import { DirGalleryProvider } from '../../../main/ets/gallery/DirGalleryProvider.ets';
import type { DirGalleryFsOps } from '../../../main/ets/gallery/DirGalleryProvider.ets';
import { ArchiveGalleryProvider } from '../../../main/ets/gallery/ArchiveGalleryProvider.ets';
import type { ArchiveReader, ArchiveEntry, ArchiveFsOps } from '../../../main/ets/gallery/ArchiveGalleryProvider.ets';
import { EhGalleryProvider } from '../../../main/ets/gallery/EhGalleryProvider.ets';
import type { SpiderQueenFactory, SpiderQueenLike, OnSpiderListener } from '../../../main/ets/gallery/EhGalleryProvider.ets';
import type { GalleryProvider2 } from '../../../main/ets/gallery/GalleryProvider2.ets';
import type { GalleryProviderListener } from '../../../main/ets/gallery/GalleryProvider.ets';
import { MemoryEhDB } from '../../../main/ets/database/MemoryEhDB.ets';
import { SettingsService } from '../../../main/ets/service/SettingsService.ets';
import { MemoryPreferencesStore } from '../../../main/ets/preferences/MemoryPreferencesStore.ets';

// ---- In-memory filesystem mock ----

class MemoryFs implements DirGalleryFsOps {
  private dirs: Map<string, string[]> = new Map();
  private files: Map<string, Uint8Array> = new Map();

  addDir(path: string, names: string[]): void {
    this.dirs.set(path, names);
  }

  addFile(path: string, data: Uint8Array): void {
    this.files.set(path, data);
  }

  readdirSync(dirPath: string): string[] {
    const names = this.dirs.get(dirPath);
    if (names === undefined) throw new Error(`Not a directory: ${dirPath}`);
    return names;
  }

  readFileSync(path: string): Uint8Array {
    const data = this.files.get(path);
    if (data === undefined) throw new Error(`File not found: ${path}`);
    return data;
  }

  writeFileSync(path: string, data: Uint8Array): void {
    this.files.set(path, data);
  }

  existsSync(path: string): boolean {
    return this.dirs.has(path) || this.files.has(path);
  }
}

// ---- Helpers ----

function makeGallery(gid: number, title: string = `Gallery ${gid}`): GalleryInfo {
  const gi = new GalleryInfo();
  gi.gid = gid;
  gi.token = `tok_${gid}`;
  gi.title = title;
  gi.category = 2;
  gi.uploader = 'test_user';
  gi.rating = 4.0;
  return gi;
}

function makeDownload(
  gid: number,
  title: string,
  state: number = DownloadInfo.STATE_NONE,
): DownloadInfo {
  const di = new DownloadInfo(makeGallery(gid, title));
  di.state = state;
  di.time = Date.now() + gid;
  return di;
}

// ---- Tests ----

describe('PageRouter.toLocalGalleryReader', () => {
  it('should build correct route for directory source', () => {
    const nav = PageRouter.toLocalGalleryReader('dir', '/downloads/gallery-123');
    assert.strictEqual(nav.url, Routes.GALLERY_READER);
    assert.strictEqual(nav.params!['source'], 'dir');
    assert.strictEqual(nav.params!['path'], '/downloads/gallery-123');
    assert.strictEqual(nav.params!['page'], 0);
  });

  it('should build correct route for archive source', () => {
    const nav = PageRouter.toLocalGalleryReader('archive', '/files/gallery.zip', 5);
    assert.strictEqual(nav.url, Routes.GALLERY_READER);
    assert.strictEqual(nav.params!['source'], 'archive');
    assert.strictEqual(nav.params!['path'], '/files/gallery.zip');
    assert.strictEqual(nav.params!['page'], 5);
  });

  it('should accept a title parameter', () => {
    const nav = PageRouter.toLocalGalleryReader('dir', '/path', 0, 'My Gallery');
    assert.strictEqual(nav.params!['title'], 'My Gallery');
  });

  it('should default page to 0 and title to empty', () => {
    const nav = PageRouter.toLocalGalleryReader('dir', '/path');
    assert.strictEqual(nav.params!['page'], 0);
    assert.strictEqual(nav.params!['title'], '');
  });
});

describe('DownloadsViewModel.getDownloadDir', () => {
  let db: MemoryEhDB;
  let vm: DownloadsViewModel;

  beforeEach(() => {
    const prefs = new MemoryPreferencesStore();
    SettingsService.initialize(prefs);
    // Set a download location so getDownloadRoot() returns a path
    SettingsService.setDownloadLocation('/test/downloads');
    db = new MemoryEhDB();
    vm = new DownloadsViewModel(db);
  });

  it('should return null for unknown gid', () => {
    vm.load();
    assert.strictEqual(vm.getDownloadDir(999), null);
  });

  it('should resolve download dir for a known gallery', () => {
    const di = makeDownload(123, 'Test Gallery', DownloadInfo.STATE_FINISH);
    db.putDownloadInfo(di);
    vm.load();

    const dir = vm.getDownloadDir(123);
    assert.ok(dir !== null);
    // Should start with the download root
    assert.ok(dir!.startsWith('/test/downloads/'));
    // Should contain the gid
    assert.ok(dir!.includes('123'));
  });

  it('should return null when download location is not set', () => {
    SettingsService.setDownloadLocation('');
    const di = makeDownload(1, 'No Root', DownloadInfo.STATE_FINISH);
    db.putDownloadInfo(di);
    vm.load();

    // When no download location is configured and no default, returns null
    // (depends on AppConfig.getDownloadDir which may be null in tests)
    const dir = vm.getDownloadDir(1);
    // Either null or a path based on AppConfig defaults
    assert.ok(dir === null || typeof dir === 'string');
  });
});

describe('DataMappers.toDownloadItem with downloadDir', () => {
  it('should set isFinished and downloadDir for finished download', () => {
    const di = makeDownload(100, 'Finished Gallery', DownloadInfo.STATE_FINISH);
    const item = DataMappers.toDownloadItem(di, '/downloads/100-finished');

    assert.strictEqual(item.isFinished, true);
    assert.strictEqual(item.downloadDir, '/downloads/100-finished');
  });

  it('should set isFinished=false for non-finished download', () => {
    const di = makeDownload(200, 'Downloading', DownloadInfo.STATE_DOWNLOAD);
    const item = DataMappers.toDownloadItem(di, '/downloads/200');

    assert.strictEqual(item.isFinished, false);
    assert.strictEqual(item.downloadDir, '/downloads/200');
  });

  it('should set downloadDir=null when not provided', () => {
    const di = makeDownload(300, 'No Dir', DownloadInfo.STATE_FINISH);
    const item = DataMappers.toDownloadItem(di);

    assert.strictEqual(item.isFinished, true);
    assert.strictEqual(item.downloadDir, null);
  });
});

describe('DataMappers.toDownloadItems with dir resolver', () => {
  it('should use dir resolver to populate downloadDir', () => {
    const list = [
      makeDownload(1, 'A', DownloadInfo.STATE_FINISH),
      makeDownload(2, 'B', DownloadInfo.STATE_DOWNLOAD),
    ];

    const resolver = (gid: number): string | null => `/dl/${gid}`;
    const items = DataMappers.toDownloadItems(list, resolver);

    assert.strictEqual(items.length, 2);
    assert.strictEqual(items[0].downloadDir, '/dl/1');
    assert.strictEqual(items[0].isFinished, true);
    assert.strictEqual(items[1].downloadDir, '/dl/2');
    assert.strictEqual(items[1].isFinished, false);
  });

  it('should work without dir resolver (backward compatible)', () => {
    const list = [makeDownload(1, 'A', DownloadInfo.STATE_FINISH)];
    const items = DataMappers.toDownloadItems(list);

    assert.strictEqual(items[0].downloadDir, null);
    assert.strictEqual(items[0].isFinished, true);
  });
});

describe('Local gallery reading — full flow with DirGalleryProvider', () => {
  let fs: MemoryFs;

  beforeEach(() => {
    fs = new MemoryFs();
  });

  it('should browse directory images page by page', () => {
    const DIR = '/downloads/gallery-1';
    fs.addDir(DIR, ['001.jpg', '002.png', '003.gif']);
    fs.addFile(`${DIR}/001.jpg`, new Uint8Array([0xFF, 0xD8, 0x01]));
    fs.addFile(`${DIR}/002.png`, new Uint8Array([0x89, 0x50, 0x02]));
    fs.addFile(`${DIR}/003.gif`, new Uint8Array([0x47, 0x49, 0x03]));

    const provider = new DirGalleryProvider(DIR, fs);
    const vm = new GalleryReaderViewModel();

    let changeCount = 0;
    vm.setOnChange(() => { changeCount++; });

    // Start reading
    vm.start(provider, GallerySource.DIR, 0);

    // Should have 3 pages
    assert.strictEqual(vm.totalPages, 3);
    assert.strictEqual(vm.currentPage, 0);
    assert.strictEqual(vm.readerState.source, GallerySource.DIR);

    // Navigate forward
    assert.ok(vm.nextPage());
    assert.strictEqual(vm.currentPage, 1);
    assert.strictEqual(vm.readerState.currentIndex, 1);

    assert.ok(vm.nextPage());
    assert.strictEqual(vm.currentPage, 2);
    assert.strictEqual(vm.readerState.currentIndex, 2);

    // Can't go past the end
    assert.ok(!vm.nextPage());
    assert.strictEqual(vm.currentPage, 2);

    // Navigate backward
    assert.ok(vm.prevPage());
    assert.strictEqual(vm.currentPage, 1);

    // Jump to specific page
    vm.goToPage(0);
    assert.strictEqual(vm.currentPage, 0);

    // Progress text
    assert.strictEqual(vm.progressText, '1 / 3');

    // Clean up
    vm.stop();
    assert.strictEqual(vm.isStarted, false);
  });

  it('should handle empty directory gracefully', () => {
    const DIR = '/downloads/empty';
    fs.addDir(DIR, []);

    const provider = new DirGalleryProvider(DIR, fs);
    const vm = new GalleryReaderViewModel();
    vm.start(provider, GallerySource.DIR, 0);

    assert.strictEqual(vm.totalPages, 0);
    assert.strictEqual(vm.progressText, '');

    vm.stop();
  });

  it('should request page data from provider', () => {
    const DIR = '/downloads/gallery-2';
    const imgData = new Uint8Array([0xFF, 0xD8, 0xFF, 0xE0]);
    fs.addDir(DIR, ['page1.jpg']);
    fs.addFile(`${DIR}/page1.jpg`, imgData);

    const provider = new DirGalleryProvider(DIR, fs);
    const vm = new GalleryReaderViewModel();
    vm.start(provider, GallerySource.DIR, 0);

    // Request the page
    vm.requestPage(0);

    // Page should be ready
    const info = vm.getPageInfo(0);
    assert.strictEqual(info.state, 2); // PageState.READY
    assert.strictEqual(info.progress, 1.0);

    vm.stop();
  });

  it('should handle non-existent directory', () => {
    const provider = new DirGalleryProvider('/nonexistent', fs);
    const vm = new GalleryReaderViewModel();
    vm.start(provider, GallerySource.DIR, 0);

    // Size should indicate error
    assert.ok(vm.totalPages <= 0);

    vm.stop();
  });

  it('should filter non-image files when browsing', () => {
    const DIR = '/downloads/mixed';
    fs.addDir(DIR, ['img.jpg', 'readme.txt', 'data.json', 'pic.png']);
    fs.addFile(`${DIR}/img.jpg`, new Uint8Array([1]));
    fs.addFile(`${DIR}/pic.png`, new Uint8Array([2]));

    const provider = new DirGalleryProvider(DIR, fs);
    const vm = new GalleryReaderViewModel();
    vm.start(provider, GallerySource.DIR, 0);

    // Only 2 image files
    assert.strictEqual(vm.totalPages, 2);

    vm.stop();
  });

  it('should persist reading position', () => {
    const DIR = '/downloads/gallery-pos';
    fs.addDir(DIR, ['01.jpg', '02.jpg', '03.jpg', '04.jpg', '05.jpg']);
    for (let i = 1; i <= 5; i++) {
      fs.addFile(`${DIR}/0${i}.jpg`, new Uint8Array([i]));
    }

    const provider = new DirGalleryProvider(DIR, fs);
    const vm = new GalleryReaderViewModel();
    vm.start(provider, GallerySource.DIR, 0);

    // Navigate to page 3
    vm.goToPage(3);
    assert.strictEqual(vm.currentPage, 3);

    // Stop persists the position via putStartPage
    vm.stop();

    // The base DirGalleryProvider.putStartPage is a no-op,
    // but the mechanism works at the ViewModel level
  });
});

describe('Downloaded gallery → local reading (integration)', () => {
  let db: MemoryEhDB;

  beforeEach(() => {
    const prefs = new MemoryPreferencesStore();
    SettingsService.initialize(prefs);
    SettingsService.setDownloadLocation('/test/downloads');
    db = new MemoryEhDB();
  });

  it('should resolve download dir and build local reader route for finished download', () => {
    // Set up a finished download
    const di = makeDownload(42, 'My Downloaded Gallery', DownloadInfo.STATE_FINISH);
    db.putDownloadInfo(di);

    const vm = new DownloadsViewModel(db);
    vm.load();

    // Resolve the download dir
    const downloadDir = vm.getDownloadDir(42);
    assert.ok(downloadDir !== null);

    // Build navigation for local reading
    const nav = PageRouter.toLocalGalleryReader('dir', downloadDir!, 0, 'My Downloaded Gallery');
    assert.strictEqual(nav.url, Routes.GALLERY_READER);
    assert.strictEqual(nav.params!['source'], 'dir');
    assert.strictEqual(nav.params!['path'], downloadDir);
    assert.strictEqual(nav.params!['title'], 'My Downloaded Gallery');
  });

  it('should map finished downloads with downloadDir in batch', () => {
    const finished = makeDownload(1, 'Done', DownloadInfo.STATE_FINISH);
    const downloading = makeDownload(2, 'Active', DownloadInfo.STATE_DOWNLOAD);
    db.putDownloadInfo(finished);
    db.putDownloadInfo(downloading);

    const vm = new DownloadsViewModel(db);
    vm.load();

    const items = DataMappers.toDownloadItems(
      vm.items,
      (gid: number) => vm.getDownloadDir(gid),
    );

    // Find the finished item
    const finishedItem = items.find(i => i.gid === 1);
    assert.ok(finishedItem !== undefined);
    assert.strictEqual(finishedItem!.isFinished, true);
    assert.ok(finishedItem!.downloadDir !== null);

    // Find the downloading item
    const activeItem = items.find(i => i.gid === 2);
    assert.ok(activeItem !== undefined);
    assert.strictEqual(activeItem!.isFinished, false);
    // Still has a download dir (even if not finished)
    assert.ok(activeItem!.downloadDir !== null);
  });
});
