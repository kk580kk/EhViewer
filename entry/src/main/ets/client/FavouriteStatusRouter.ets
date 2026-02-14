/*
 * Copyright 2019 Hippo Seven
 * Ported to HarmonyOS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { GalleryInfo } from '../model/GalleryInfo.ets';

/**
 * Listener for favourite status changes.
 */
export interface FavouriteStatusListener {
  onModifyFavourites(gid: number, slot: number): void;
}

/**
 * Routes favourite status changes across data maps and listeners.
 *
 * Mirrors the Android FavouriteStatusRouter class.
 */
export class FavouriteStatusRouter {
  private nextId: number = 0;
  private maps: Map<number, Map<number, GalleryInfo>> = new Map();
  private listeners: FavouriteStatusListener[] = [];

  /** Save a data map and return its id. */
  saveDataMap(map: Map<number, GalleryInfo>): number {
    const id = this.nextId++;
    this.maps.set(id, map);
    return id;
  }

  /** Restore and remove a data map by id. */
  restoreDataMap(id: number): Map<number, GalleryInfo> | undefined {
    const map = this.maps.get(id);
    this.maps.delete(id);
    return map;
  }

  /** Update favourite slot for a gallery across all data maps and notify listeners. */
  modifyFavourites(gid: number, slot: number): void {
    for (const map of this.maps.values()) {
      const info = map.get(gid);
      if (info) {
        info.favoriteSlot = slot;
      }
    }

    for (const listener of this.listeners) {
      listener.onModifyFavourites(gid, slot);
    }
  }

  addListener(listener: FavouriteStatusListener): void {
    this.listeners.push(listener);
  }

  removeListener(listener: FavouriteStatusListener): void {
    const idx = this.listeners.indexOf(listener);
    if (idx >= 0) {
      this.listeners.splice(idx, 1);
    }
  }
}
