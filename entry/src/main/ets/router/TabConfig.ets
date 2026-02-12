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
 * Tab configuration for the main bottom navigation.
 *
 * Separated from Index.ets so it can be tested without ArkTS decorators.
 */

/** Tab item descriptor used by the bottom tab bar. */
export interface TabItem {
  title: string;
  icon: string;
  iconSelected: string;
}

/** Tab index constants. */
export const TAB_GALLERY   = 0;
export const TAB_FAVORITES = 1;
export const TAB_HISTORY   = 2;
export const TAB_DOWNLOADS = 3;
export const TAB_SETTINGS  = 4;

/** The five primary navigation tabs. */
export const TAB_ITEMS: TabItem[] = [
  { title: 'Gallery',    icon: '\u{1F4F0}', iconSelected: '\u{1F4F0}' },
  { title: 'Favorites',  icon: '\u2606',     iconSelected: '\u2605'     },
  { title: 'History',    icon: '\u{1F553}',  iconSelected: '\u{1F553}'  },
  { title: 'Downloads',  icon: '\u2B07',     iconSelected: '\u2B07'     },
  { title: 'Settings',   icon: '\u2699',     iconSelected: '\u2699'     },
];

/** Total number of tabs. */
export const TAB_COUNT = TAB_ITEMS.length;

/** Get tab title by index. Returns empty string if out of bounds. */
export function getTabTitle(index: number): string {
  if (index < 0 || index >= TAB_ITEMS.length) {
    return '';
  }
  return TAB_ITEMS[index].title;
}
