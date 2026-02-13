/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { GallerySource } from './GallerySource.ets';

/**
 * Read-only snapshot of the current gallery reader state.
 *
 * The reading page and navigation bar should depend on this interface to
 * query the gallery source and current page index without being able to
 * mutate them.
 */
export interface ReaderState {
  /** The gallery source (EH, DIR, or ARCHIVE). */
  readonly source: GallerySource;
  /** The current page index (0-based). */
  readonly currentIndex: number;
}

/**
 * Mutable implementation of {@link ReaderState}.
 *
 * Only the owner (typically the ViewModel) should hold a reference to this
 * class and call the setters. Consumers receive the {@link ReaderState}
 * interface which exposes only getters.
 */
export class MutableReaderState implements ReaderState {
  private _source: GallerySource;
  private _currentIndex: number;

  constructor(source: GallerySource, currentIndex: number = 0) {
    this._source = source;
    this._currentIndex = currentIndex;
  }

  get source(): GallerySource {
    return this._source;
  }

  get currentIndex(): number {
    return this._currentIndex;
  }

  /** Update the current page index. */
  setCurrentIndex(index: number): void {
    this._currentIndex = index;
  }

  /** Update the gallery source. */
  setSource(source: GallerySource): void {
    this._source = source;
  }
}
