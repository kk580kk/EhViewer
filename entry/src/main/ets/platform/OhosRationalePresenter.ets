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
import type { RationalePresenter } from '../util/PermissionRequester.ets';

const log = Logger.tag('OhosRationalePresenter');

// ---- Harmony AlertDialog abstraction ----

/** Button action result from the dialog. */
export interface OhosDialogAction {
  index: number;
}

/**
 * Abstraction over HarmonyOS AlertDialog / promptAction.showDialog.
 *
 * Production: wraps promptAction.showDialog().
 * Tests: supply a mock implementation.
 */
export interface OhosDialogApi {
  /**
   * Show a dialog with the given message and buttons.
   *
   * @param options - dialog configuration
   * @returns promise resolving to the action (button index)
   */
  showDialog(options: {
    title?: string;
    message: string;
    buttons: Array<{ text: string; color?: string }>;
  }): Promise<OhosDialogAction>;
}

/**
 * OhosRationalePresenter — production implementation of RationalePresenter
 * using HarmonyOS promptAction.showDialog().
 *
 * Shows a two-button dialog (OK / Cancel) explaining why a permission is needed.
 * Returns true if user tapped OK (index 0), false otherwise.
 *
 * Usage (production):
 *   import promptAction from '@ohos.promptAction';
 *   const presenter = new OhosRationalePresenter(promptAction);
 */
export class OhosRationalePresenter implements RationalePresenter {
  private dialogApi: OhosDialogApi;
  private okLabel: string;
  private cancelLabel: string;

  constructor(dialogApi: OhosDialogApi, okLabel: string = 'OK', cancelLabel: string = 'Cancel') {
    this.dialogApi = dialogApi;
    this.okLabel = okLabel;
    this.cancelLabel = cancelLabel;
  }

  async showRationale(message: string): Promise<boolean> {
    try {
      const result = await this.dialogApi.showDialog({
        title: '',
        message,
        buttons: [
          { text: this.okLabel },
          { text: this.cancelLabel },
        ],
      });
      return result.index === 0;
    } catch (e) {
      log.e('Failed to show rationale dialog', e instanceof Error ? e : new Error(String(e)));
      return false;
    }
  }
}
