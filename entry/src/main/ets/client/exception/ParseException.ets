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
 * Thrown when an HTML or API response cannot be parsed.
 * Retains the raw response body for debugging.
 */
export class ParseException extends EhException {
  readonly body: string;

  constructor(message: string, body: string, cause?: Error) {
    super(message, cause);
    this.name = 'ParseException';
    this.body = body;
  }
}
