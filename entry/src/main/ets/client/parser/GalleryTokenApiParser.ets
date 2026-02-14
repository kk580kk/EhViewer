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

import { EhException } from '../exception/EhException.ets';

export class GalleryTokenApiParser {

  static parse(body: string): string {
    const jo = JSON.parse(body);
    const item = jo['tokenlist']?.[0];
    if (item && typeof item['token'] === 'string') {
      return item['token'];
    }
    if (item && typeof item['error'] === 'string') {
      throw new EhException(item['error']);
    }
    throw new EhException('No token in response');
  }
}
