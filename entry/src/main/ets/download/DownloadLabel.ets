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

/**
 * A named label used to group download tasks.
 *
 * Mirrors the Android DownloadLabel DAO entity.
 */
export class DownloadLabel {
  id: number | null = null;
  label: string = '';
  time: number = 0;

  constructor(label?: string) {
    if (label !== undefined) {
      this.label = label;
      this.time = Date.now();
    }
  }
}
