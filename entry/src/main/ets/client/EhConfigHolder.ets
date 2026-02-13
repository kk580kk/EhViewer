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

import { EhConfig } from './EhConfig.ets';

/**
 * Holds the application-wide EhConfig instance used for uconfig cookie and User-Agent.
 * Set during app init; cookie store and HTTP client read from here.
 */
export class EhConfigHolder {
  private static instance: EhConfig | null = null;

  static get(): EhConfig {
    if (EhConfigHolder.instance === null) {
      EhConfigHolder.instance = new EhConfig();
    }
    return EhConfigHolder.instance;
  }

  static set(config: EhConfig): void {
    EhConfigHolder.instance = config;
  }

  /** Reset for tests. */
  static reset(): void {
    EhConfigHolder.instance = null;
  }
}
