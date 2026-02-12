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
 * Thrown when the gallery has been removed or banned ("pining for the fjords").
 */
export class PiningException extends EhException {
  constructor() {
    super('pining for the fjords');
    this.name = 'PiningException';
  }
}
