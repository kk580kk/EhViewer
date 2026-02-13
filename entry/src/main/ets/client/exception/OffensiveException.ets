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
 * 敏感内容异常。当页面返回 offensive 提示（如 g.e-hentai.org 的敏感内容警告）时抛出。
 */
export class OffensiveException extends EhException {
  constructor(message?: string) {
    super(message ?? 'OFFENSIVE');
    this.name = 'OffensiveException';
  }
}
