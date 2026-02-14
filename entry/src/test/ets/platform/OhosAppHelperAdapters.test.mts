import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  OhosWantLauncher,
  OhosToastPresenter,
  OhosInputMethodController,
} from '../../../main/ets/platform/OhosAppHelperAdapters.ets';
import type {
  OhosAbilityContextApi,
  OhosWant,
  OhosPromptActionApi,
  OhosInputMethodApi,
} from '../../../main/ets/platform/OhosAppHelperAdapters.ets';

// ---- Mock implementations ----

class MockAbilityContext implements OhosAbilityContextApi {
  calls: OhosWant[] = [];
  shouldThrow = false;
  shouldRejectAsync = false;

  async startAbility(want: OhosWant): Promise<void> {
    if (this.shouldThrow) {
      throw new Error('startAbility failed');
    }
    if (this.shouldRejectAsync) {
      throw new Error('async rejection');
    }
    this.calls.push(want);
  }
}

class MockPromptAction implements OhosPromptActionApi {
  toasts: Array<{ message: string; duration?: number }> = [];
  shouldThrow = false;

  showToast(options: { message: string; duration?: number }): void {
    if (this.shouldThrow) {
      throw new Error('showToast error');
    }
    this.toasts.push(options);
  }
}

class MockInputMethod implements OhosInputMethodApi {
  showCalls = 0;
  hideCalls = 0;
  shouldThrowShow = false;
  shouldThrowHide = false;

  async showSoftKeyboard(): Promise<void> {
    if (this.shouldThrowShow) {
      throw new Error('show error');
    }
    this.showCalls++;
  }

  async hideSoftKeyboard(): Promise<void> {
    if (this.shouldThrowHide) {
      throw new Error('hide error');
    }
    this.hideCalls++;
  }
}

// ---- OhosWantLauncher ----

describe('OhosWantLauncher', () => {
  let context: MockAbilityContext;
  let launcher: OhosWantLauncher;

  beforeEach(() => {
    context = new MockAbilityContext();
    launcher = new OhosWantLauncher(context);
  });

  it('should pass want fields to context.startAbility', () => {
    const result = launcher.startAbility({
      action: 'ohos.want.action.sendToData',
      uri: 'mailto:test@example.com',
      type: 'text/plain',
      parameters: { key: 'value' },
    });

    assert.strictEqual(result, true);
    assert.strictEqual(context.calls.length, 1);
    assert.strictEqual(context.calls[0].action, 'ohos.want.action.sendToData');
    assert.strictEqual(context.calls[0].uri, 'mailto:test@example.com');
    assert.strictEqual(context.calls[0].type, 'text/plain');
  });

  it('should return true even for fire-and-forget', () => {
    const result = launcher.startAbility({ action: 'test' });
    assert.strictEqual(result, true);
  });

  it('should return false when context throws synchronously', () => {
    context.shouldThrow = true;
    // Mock synchronous throw by overriding
    const syncContext: OhosAbilityContextApi = {
      startAbility(_want: OhosWant): Promise<void> {
        throw new Error('sync error');
      },
    };
    const syncLauncher = new OhosWantLauncher(syncContext);
    const result = syncLauncher.startAbility({ action: 'test' });
    assert.strictEqual(result, false);
  });

  it('should handle undefined optional fields', () => {
    launcher.startAbility({ action: 'test' });
    assert.strictEqual(context.calls.length, 1);
    assert.strictEqual(context.calls[0].uri, undefined);
    assert.strictEqual(context.calls[0].type, undefined);
  });
});

// ---- OhosToastPresenter ----

describe('OhosToastPresenter', () => {
  let promptAction: MockPromptAction;
  let toast: OhosToastPresenter;

  beforeEach(() => {
    promptAction = new MockPromptAction();
    toast = new OhosToastPresenter(promptAction);
  });

  it('should call showToast with message and duration', () => {
    toast.showShort('Hello!');
    assert.strictEqual(promptAction.toasts.length, 1);
    assert.strictEqual(promptAction.toasts[0].message, 'Hello!');
    assert.strictEqual(promptAction.toasts[0].duration, 2000);
  });

  it('should not throw when promptAction fails', () => {
    promptAction.shouldThrow = true;
    assert.doesNotThrow(() => toast.showShort('msg'));
  });

  it('should handle empty message', () => {
    toast.showShort('');
    assert.strictEqual(promptAction.toasts.length, 1);
    assert.strictEqual(promptAction.toasts[0].message, '');
  });
});

// ---- OhosInputMethodController ----

describe('OhosInputMethodController', () => {
  let inputMethod: MockInputMethod;
  let ime: OhosInputMethodController;

  beforeEach(() => {
    inputMethod = new MockInputMethod();
    ime = new OhosInputMethodController(inputMethod);
  });

  it('should return true when showSoftKeyboard succeeds', () => {
    const result = ime.showSoftKeyboard();
    assert.strictEqual(result, true);
  });

  it('should return true when hideSoftKeyboard succeeds', () => {
    const result = ime.hideSoftKeyboard();
    assert.strictEqual(result, true);
  });

  it('should return false when showSoftKeyboard throws synchronously', () => {
    const throwingApi: OhosInputMethodApi = {
      showSoftKeyboard(): Promise<void> { throw new Error('sync'); },
      hideSoftKeyboard(): Promise<void> { return Promise.resolve(); },
    };
    const throwingIme = new OhosInputMethodController(throwingApi);
    assert.strictEqual(throwingIme.showSoftKeyboard(), false);
  });

  it('should return false when hideSoftKeyboard throws synchronously', () => {
    const throwingApi: OhosInputMethodApi = {
      showSoftKeyboard(): Promise<void> { return Promise.resolve(); },
      hideSoftKeyboard(): Promise<void> { throw new Error('sync'); },
    };
    const throwingIme = new OhosInputMethodController(throwingApi);
    assert.strictEqual(throwingIme.hideSoftKeyboard(), false);
  });
});
