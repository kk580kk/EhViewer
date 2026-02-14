/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import { Logger } from '../util/Logger.ets';
import type { WantLauncher, WantDescriptor, ToastPresenter, InputMethodController } from '../util/AppHelper.ets';

const log = Logger.tag('OhosAppHelperAdapters');

// ---- Harmony Want / UIAbilityContext abstraction ----

/**
 * Abstraction over HarmonyOS Want object.
 * Maps to @ohos.app.ability.Want.
 */
export interface OhosWant {
  action?: string;
  uri?: string;
  type?: string;
  parameters?: Record<string, Object>;
}

/**
 * Abstraction over UIAbilityContext for launching abilities.
 *
 * Production: pass the real UIAbilityContext.
 * Tests: supply a mock implementation.
 */
export interface OhosAbilityContextApi {
  startAbility(want: OhosWant): Promise<void>;
}

/**
 * OhosWantLauncher — production implementation of WantLauncher
 * using HarmonyOS UIAbilityContext.startAbility().
 *
 * Note: startAbility is async in HarmonyOS, but WantLauncher.startAbility
 * is sync. We fire-and-forget, returning true if the call was initiated.
 *
 * Usage (production):
 *   const launcher = new OhosWantLauncher(this.context);
 */
export class OhosWantLauncher implements WantLauncher {
  private context: OhosAbilityContextApi;

  constructor(context: OhosAbilityContextApi) {
    this.context = context;
  }

  startAbility(want: WantDescriptor): boolean {
    const ohosWant: OhosWant = {
      action: want.action,
      uri: want.uri,
      type: want.type,
      parameters: want.parameters as Record<string, Object> | undefined,
    };

    try {
      // Fire-and-forget: initiate the ability launch.
      // Errors are caught asynchronously and logged.
      this.context.startAbility(ohosWant).catch((e: Error) => {
        log.e('startAbility async error', e);
      });
      return true;
    } catch (e) {
      log.e('startAbility sync error', e instanceof Error ? e : new Error(String(e)));
      return false;
    }
  }
}

// ---- Harmony promptAction abstraction ----

/**
 * Abstraction over @ohos.promptAction API.
 *
 * Production: pass the real promptAction module.
 * Tests: supply a mock implementation.
 */
export interface OhosPromptActionApi {
  showToast(options: { message: string; duration?: number }): void;
}

/**
 * OhosToastPresenter — production implementation of ToastPresenter
 * using HarmonyOS @ohos.promptAction.showToast().
 *
 * Usage (production):
 *   import promptAction from '@ohos.promptAction';
 *   const toast = new OhosToastPresenter(promptAction);
 */
export class OhosToastPresenter implements ToastPresenter {
  private promptAction: OhosPromptActionApi;

  constructor(promptAction: OhosPromptActionApi) {
    this.promptAction = promptAction;
  }

  showShort(message: string): void {
    try {
      this.promptAction.showToast({ message, duration: 2000 });
    } catch (e) {
      log.e('Failed to show toast', e instanceof Error ? e : new Error(String(e)));
    }
  }
}

// ---- Harmony inputMethod abstraction ----

/**
 * Abstraction over @ohos.inputMethod.InputMethodController.
 *
 * Production: pass inputMethod.getController().
 * Tests: supply a mock implementation.
 */
export interface OhosInputMethodApi {
  showSoftKeyboard(): Promise<void>;
  hideSoftKeyboard(): Promise<void>;
}

/**
 * OhosInputMethodController — production implementation of InputMethodController
 * using HarmonyOS @ohos.inputMethod API.
 *
 * Note: The Harmony API is async, but our interface is sync.
 * We fire-and-forget and return true if the call was initiated.
 *
 * Usage (production):
 *   import inputMethod from '@ohos.inputMethod';
 *   const ime = new OhosInputMethodController(inputMethod.getController());
 */
export class OhosInputMethodController implements InputMethodController {
  private controller: OhosInputMethodApi;

  constructor(controller: OhosInputMethodApi) {
    this.controller = controller;
  }

  showSoftKeyboard(): boolean {
    try {
      this.controller.showSoftKeyboard().catch((e: Error) => {
        log.e('showSoftKeyboard async error', e);
      });
      return true;
    } catch (e) {
      log.e('showSoftKeyboard sync error', e instanceof Error ? e : new Error(String(e)));
      return false;
    }
  }

  hideSoftKeyboard(): boolean {
    try {
      this.controller.hideSoftKeyboard().catch((e: Error) => {
        log.e('hideSoftKeyboard async error', e);
      });
      return true;
    } catch (e) {
      log.e('hideSoftKeyboard sync error', e instanceof Error ? e : new Error(String(e)));
      return false;
    }
  }
}
