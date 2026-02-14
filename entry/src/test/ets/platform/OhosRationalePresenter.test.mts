import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  OhosRationalePresenter,
} from '../../../main/ets/platform/OhosRationalePresenter.ets';
import type {
  OhosDialogApi,
  OhosDialogAction,
} from '../../../main/ets/platform/OhosRationalePresenter.ets';

// ---- Mock implementations ----

class MockDialogApi implements OhosDialogApi {
  calls: Array<{ message: string; buttons: Array<{ text: string }> }> = [];
  /** Button index to return. 0 = OK, 1 = Cancel. */
  selectedIndex = 0;
  shouldThrow = false;

  async showDialog(options: {
    title?: string;
    message: string;
    buttons: Array<{ text: string; color?: string }>;
  }): Promise<OhosDialogAction> {
    if (this.shouldThrow) {
      throw new Error('Dialog error');
    }
    this.calls.push({
      message: options.message,
      buttons: options.buttons.map(b => ({ text: b.text })),
    });
    return { index: this.selectedIndex };
  }
}

describe('OhosRationalePresenter', () => {
  let dialogApi: MockDialogApi;
  let presenter: OhosRationalePresenter;

  beforeEach(() => {
    dialogApi = new MockDialogApi();
    presenter = new OhosRationalePresenter(dialogApi);
  });

  it('should return true when user taps OK (index 0)', async () => {
    dialogApi.selectedIndex = 0;
    const result = await presenter.showRationale('Need camera access');
    assert.strictEqual(result, true);
  });

  it('should return false when user taps Cancel (index 1)', async () => {
    dialogApi.selectedIndex = 1;
    const result = await presenter.showRationale('Need camera access');
    assert.strictEqual(result, false);
  });

  it('should pass message to dialog', async () => {
    await presenter.showRationale('We need your location');
    assert.strictEqual(dialogApi.calls.length, 1);
    assert.strictEqual(dialogApi.calls[0].message, 'We need your location');
  });

  it('should use default OK/Cancel button labels', async () => {
    await presenter.showRationale('msg');
    const buttons = dialogApi.calls[0].buttons;
    assert.strictEqual(buttons.length, 2);
    assert.strictEqual(buttons[0].text, 'OK');
    assert.strictEqual(buttons[1].text, 'Cancel');
  });

  it('should use custom button labels', async () => {
    const custom = new OhosRationalePresenter(dialogApi, '确定', '取消');
    await custom.showRationale('msg');
    const buttons = dialogApi.calls[0].buttons;
    assert.strictEqual(buttons[0].text, '确定');
    assert.strictEqual(buttons[1].text, '取消');
  });

  it('should return false when dialog throws', async () => {
    dialogApi.shouldThrow = true;
    const result = await presenter.showRationale('msg');
    assert.strictEqual(result, false);
  });

  it('should return false for non-zero button index', async () => {
    dialogApi.selectedIndex = 2;
    const result = await presenter.showRationale('msg');
    assert.strictEqual(result, false);
  });
});
