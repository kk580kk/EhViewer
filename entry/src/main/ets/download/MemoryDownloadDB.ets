/*
 * Copyright 2016 Hippo Seven
 * Ported to HarmonyOS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import type { DownloadDB } from './DownloadDB.ets';
import { DownloadInfo } from './DownloadInfo.ets';
import { DownloadLabel } from './DownloadLabel.ets';

/**
 * In-memory implementation of DownloadDB for testing.
 */
export class MemoryDownloadDB implements DownloadDB {
  private infos: Map<number, DownloadInfo> = new Map();
  private labels: DownloadLabel[] = [];
  private nextLabelId: number = 1;

  getAllDownloadInfo(): DownloadInfo[] {
    const list = Array.from(this.infos.values());
    list.sort((a, b) => b.time - a.time);
    return list;
  }

  putDownloadInfo(info: DownloadInfo): void {
    this.infos.set(info.gid, info);
  }

  removeDownloadInfo(gid: number): void {
    this.infos.delete(gid);
  }

  getAllDownloadLabelList(): DownloadLabel[] {
    return [...this.labels];
  }

  addDownloadLabel(label: string): DownloadLabel {
    const dl = new DownloadLabel(label);
    dl.id = this.nextLabelId++;
    this.labels.push(dl);
    return dl;
  }

  addDownloadLabelObject(label: DownloadLabel): DownloadLabel {
    const dl = new DownloadLabel(label.label);
    dl.id = this.nextLabelId++;
    dl.time = label.time;
    this.labels.push(dl);
    return dl;
  }

  updateDownloadLabel(label: DownloadLabel): void {
    const idx = this.labels.findIndex(l => l.id === label.id);
    if (idx >= 0) {
      this.labels[idx] = label;
    }
  }

  moveDownloadLabel(fromPosition: number, toPosition: number): void {
    if (fromPosition < 0 || fromPosition >= this.labels.length) return;
    if (toPosition < 0 || toPosition >= this.labels.length) return;
    const item = this.labels.splice(fromPosition, 1)[0];
    this.labels.splice(toPosition, 0, item);
  }

  removeDownloadLabel(label: DownloadLabel): void {
    const idx = this.labels.findIndex(l => l.id === label.id);
    if (idx >= 0) {
      this.labels.splice(idx, 1);
    }
  }
}
