import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  CheckBoxDialogConfig,
  EditTextDialogConfig,
  ListCheckBoxItem,
  buildListCheckBoxItems,
  extractCheckedState,
} from '../../../main/ets/ui/common/DialogConfigs.ets';

describe('CheckBoxDialogConfig', () => {
  it('should store title, message, checkBoxLabel', () => {
    const config = new CheckBoxDialogConfig('Title', 'Message', 'Remember');
    assert.strictEqual(config.title, 'Title');
    assert.strictEqual(config.message, 'Message');
    assert.strictEqual(config.checkBoxLabel, 'Remember');
    assert.strictEqual(config.checked, false);
  });

  it('should accept initial checked state', () => {
    const config = new CheckBoxDialogConfig('T', 'M', 'CB', true);
    assert.strictEqual(config.checked, true);
  });
});

describe('EditTextDialogConfig', () => {
  it('should store title, hint, initialText', () => {
    const config = new EditTextDialogConfig('Add Label', 'Enter name', 'default');
    assert.strictEqual(config.title, 'Add Label');
    assert.strictEqual(config.hint, 'Enter name');
    assert.strictEqual(config.initialText, 'default');
  });

  it('should default hint and initialText to empty', () => {
    const config = new EditTextDialogConfig('Title');
    assert.strictEqual(config.hint, '');
    assert.strictEqual(config.initialText, '');
  });
});

describe('ListCheckBoxItem', () => {
  it('should store label and checked', () => {
    const item = new ListCheckBoxItem('Manga', true);
    assert.strictEqual(item.label, 'Manga');
    assert.strictEqual(item.checked, true);
  });

  it('should default checked to false', () => {
    const item = new ListCheckBoxItem('Doujinshi');
    assert.strictEqual(item.checked, false);
  });
});

describe('buildListCheckBoxItems', () => {
  it('should create items from labels and checked array', () => {
    const labels = ['A', 'B', 'C'];
    const checked = [true, false, true];
    const items = buildListCheckBoxItems(labels, checked);
    assert.strictEqual(items.length, 3);
    assert.strictEqual(items[0].label, 'A');
    assert.strictEqual(items[0].checked, true);
    assert.strictEqual(items[1].label, 'B');
    assert.strictEqual(items[1].checked, false);
    assert.strictEqual(items[2].label, 'C');
    assert.strictEqual(items[2].checked, true);
  });

  it('should default to false for missing checked entries', () => {
    const items = buildListCheckBoxItems(['X', 'Y'], [true]);
    assert.strictEqual(items[0].checked, true);
    assert.strictEqual(items[1].checked, false);
  });

  it('should return empty array for empty input', () => {
    const items = buildListCheckBoxItems([], []);
    assert.strictEqual(items.length, 0);
  });
});

describe('extractCheckedState', () => {
  it('should extract checked booleans', () => {
    const items = [
      new ListCheckBoxItem('A', true),
      new ListCheckBoxItem('B', false),
      new ListCheckBoxItem('C', true),
    ];
    assert.deepStrictEqual(extractCheckedState(items), [true, false, true]);
  });

  it('should return empty array for empty input', () => {
    assert.deepStrictEqual(extractCheckedState([]), []);
  });
});
