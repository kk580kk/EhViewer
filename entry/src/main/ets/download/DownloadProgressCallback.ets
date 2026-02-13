/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import type { DownloadProgressEvent } from './DownloadProgressEvent.ets';

/**
 * Callback interface for observing download progress and state changes.
 *
 * UI components implement this to display progress bars and status text
 * without coupling to DownloadManager internals.
 */
export interface DownloadProgressCallback {
  /**
   * Called when download progress is updated (page finished, speed changed, etc.).
   */
  onDownloadProgress(event: DownloadProgressEvent): void;

  /**
   * Called when a download's state changes (e.g. WAIT → DOWNLOAD → FINISH).
   */
  onDownloadStateChanged(event: DownloadProgressEvent): void;
}
