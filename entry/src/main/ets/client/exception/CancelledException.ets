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
 * Thrown when an operation is cancelled by the user or system.
 * Does NOT extend EhException — cancellation is not a business error.
 */
export class CancelledException extends Error {
  constructor() {
    super('CANCELED');
    this.name = 'CancelledException';
  }
}
