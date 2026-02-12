/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * Dialog configuration data classes — pure logic, no UI framework dependencies.
 *
 * Used by dialog components and testable independently.
 */

/** Config object for CheckBoxDialog. */
export class CheckBoxDialogConfig {
  title: string;
  message: string;
  checkBoxLabel: string;
  checked: boolean;

  constructor(title: string, message: string, checkBoxLabel: string, checked: boolean = false) {
    this.title = title;
    this.message = message;
    this.checkBoxLabel = checkBoxLabel;
    this.checked = checked;
  }
}

/** Config object for EditTextDialog. */
export class EditTextDialogConfig {
  title: string;
  hint: string;
  initialText: string;

  constructor(title: string, hint: string = '', initialText: string = '') {
    this.title = title;
    this.hint = hint;
    this.initialText = initialText;
  }
}

/** Item data for a list checkbox entry. */
export class ListCheckBoxItem {
  label: string;
  checked: boolean;

  constructor(label: string, checked: boolean = false) {
    this.label = label;
    this.checked = checked;
  }
}

/**
 * Build a ListCheckBoxItem array from labels and a checked boolean array.
 * Pure function — testable without UI framework.
 */
export function buildListCheckBoxItems(labels: string[], checked: boolean[]): ListCheckBoxItem[] {
  const items: ListCheckBoxItem[] = [];
  for (let i = 0; i < labels.length; i++) {
    items.push(new ListCheckBoxItem(labels[i], i < checked.length ? checked[i] : false));
  }
  return items;
}

/**
 * Extract the checked boolean array from a ListCheckBoxItem array.
 */
export function extractCheckedState(items: ListCheckBoxItem[]): boolean[] {
  return items.map(item => item.checked);
}
