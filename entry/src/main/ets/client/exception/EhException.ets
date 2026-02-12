/*
 * Copyright 2016 Hippo Seven
 * Ported to HarmonyOS ArkTS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * Base exception for all E-Hentai business errors.
 * Carries a user-facing message suitable for direct display.
 */
export class EhException extends Error {
  constructor(message: string, cause?: Error) {
    super(message);
    this.name = 'EhException';
    if (cause) {
      this.cause = cause;
    }
  }
}
