import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  AppHelper,
  ACTION_SEND_TO,
  ACTION_SHARE,
} from '../../../main/ets/util/AppHelper.ets';
import type {
  WantLauncher,
  WantDescriptor,
  ToastPresenter,
  InputMethodController,
} from '../../../main/ets/util/AppHelper.ets';

// ---- Mock implementations ----

class MockWantLauncher implements WantLauncher {
  calls: WantDescriptor[] = [];
  shouldSucceed = true;
  shouldThrow = false;

  startAbility(want: WantDescriptor): boolean {
    if (this.shouldThrow) {
      throw new Error('startAbility failed');
    }
    this.calls.push(want);
    return this.shouldSucceed;
  }
}

class MockToastPresenter implements ToastPresenter {
  messages: string[] = [];

  showShort(message: string): void {
    this.messages.push(message);
  }
}

class MockInputMethodController implements InputMethodController {
  showCalled = false;
  hideCalled = false;
  shouldSucceed = true;
  shouldThrow = false;

  showSoftKeyboard(): boolean {
    if (this.shouldThrow) throw new Error('IME error');
    this.showCalled = true;
    return this.shouldSucceed;
  }

  hideSoftKeyboard(): boolean {
    if (this.shouldThrow) throw new Error('IME error');
    this.hideCalled = true;
    return this.shouldSucceed;
  }
}

describe('AppHelper', () => {
  let launcher: MockWantLauncher;
  let toast: MockToastPresenter;
  let ime: MockInputMethodController;
  let helper: AppHelper;

  beforeEach(() => {
    launcher = new MockWantLauncher();
    toast = new MockToastPresenter();
    ime = new MockInputMethodController();
    helper = new AppHelper(launcher, toast, ime);
  });

  // ---- sendEmail ----

  describe('sendEmail', () => {
    it('should launch email want with correct uri', () => {
      const result = helper.sendEmail('test@example.com');
      assert.strictEqual(result, true);
      assert.strictEqual(launcher.calls.length, 1);
      assert.strictEqual(launcher.calls[0].action, ACTION_SEND_TO);
      assert.strictEqual(launcher.calls[0].uri, 'mailto:test@example.com');
    });

    it('should include subject and text in parameters', () => {
      helper.sendEmail('a@b.com', 'Hello', 'Body text');
      const want = launcher.calls[0];
      assert.strictEqual(want.parameters?.['email_subject'], 'Hello');
      assert.strictEqual(want.parameters?.['email_body'], 'Body text');
    });

    it('should omit parameters when subject and text are undefined', () => {
      helper.sendEmail('a@b.com');
      const want = launcher.calls[0];
      assert.strictEqual(want.parameters, undefined);
    });

    it('should return false and show toast when launcher fails', () => {
      launcher.shouldSucceed = false;
      const result = helper.sendEmail('a@b.com');
      assert.strictEqual(result, false);
      assert.strictEqual(toast.messages.length, 1);
    });

    it('should return false and show toast when launcher throws', () => {
      launcher.shouldThrow = true;
      const result = helper.sendEmail('a@b.com');
      assert.strictEqual(result, false);
      assert.strictEqual(toast.messages.length, 1);
    });
  });

  // ---- share ----

  describe('share', () => {
    it('should launch share want with correct action and type', () => {
      const result = helper.share('Check this out!');
      assert.strictEqual(result, true);
      assert.strictEqual(launcher.calls.length, 1);
      assert.strictEqual(launcher.calls[0].action, ACTION_SHARE);
      assert.strictEqual(launcher.calls[0].type, 'text/plain');
      assert.strictEqual(launcher.calls[0].parameters?.['shareText'], 'Check this out!');
    });

    it('should return false and show toast when launcher fails', () => {
      launcher.shouldSucceed = false;
      const result = helper.share('text');
      assert.strictEqual(result, false);
      assert.strictEqual(toast.messages.length, 1);
    });

    it('should return false and show toast when launcher throws', () => {
      launcher.shouldThrow = true;
      const result = helper.share('text');
      assert.strictEqual(result, false);
      assert.strictEqual(toast.messages.length, 1);
    });
  });

  // ---- showSoftInput ----

  describe('showSoftInput', () => {
    it('should call ime.showSoftKeyboard and return true', () => {
      const result = helper.showSoftInput();
      assert.strictEqual(result, true);
      assert.strictEqual(ime.showCalled, true);
    });

    it('should return false when ime returns false', () => {
      ime.shouldSucceed = false;
      const result = helper.showSoftInput();
      assert.strictEqual(result, false);
    });

    it('should return false when ime throws', () => {
      ime.shouldThrow = true;
      const result = helper.showSoftInput();
      assert.strictEqual(result, false);
    });
  });

  // ---- hideSoftInput ----

  describe('hideSoftInput', () => {
    it('should call ime.hideSoftKeyboard and return true', () => {
      const result = helper.hideSoftInput();
      assert.strictEqual(result, true);
      assert.strictEqual(ime.hideCalled, true);
    });

    it('should return false when ime returns false', () => {
      ime.shouldSucceed = false;
      const result = helper.hideSoftInput();
      assert.strictEqual(result, false);
    });

    it('should return false when ime throws', () => {
      ime.shouldThrow = true;
      const result = helper.hideSoftInput();
      assert.strictEqual(result, false);
    });
  });
});
