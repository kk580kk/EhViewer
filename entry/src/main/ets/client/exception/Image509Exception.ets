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

import { EhException } from './EhException.ets';

/**
 * Thrown when the server returns a 509 bandwidth limit for image loading.
 */
export class Image509Exception extends EhException {
  constructor() {
    super('509');
    this.name = 'Image509Exception';
  }
}
