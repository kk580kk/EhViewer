/*
 * Copyright 2015 Hippo Seven
 * Ported to HarmonyOS ArkTS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * LogCat — save application logs to a file.
 *
 * ArkTS equivalent of Android's LogCat utility.
 * On Android this shells out to `logcat -d`; in HarmonyOS we dump the
 * in-memory log buffer maintained by {@link Logger}.
 *
 * Usage:
 *   const ok = LogCat.save(fs, '/data/logs/logcat.txt');
 */

import { Logger } from './Logger.ets';
import type { FsOps } from './FileUtils.ets';
import { writeToFile } from './FileUtils.ets';

export class LogCat {
  private constructor() {}

  /**
   * Dump the current in-memory log buffer to a file.
   *
   * @param fs   Filesystem adapter (injected for testability)
   * @param path Absolute path of the output file
   * @returns true if the file was written successfully
   */
  static save(fs: FsOps, path: string): boolean {
    const content = Logger.getBuffer().dump();
    return writeToFile(fs, path, content);
  }
}
