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
 * EmptyState — reusable empty/placeholder view.
 *
 * Displays a large icon, primary text, and optional secondary text.
 * Used by Favorites, History, Downloads tabs and other list scenes.
 *
 * Usage:
 *   EmptyState({
 *     icon: '\u2606',
 *     title: 'No favorites yet',
 *     subtitle: 'Add galleries to your favorites',
 *   })
 */
@Component
export struct EmptyState {
  @Prop icon: string = '';
  @Prop title: string = '';
  @Prop subtitle: string = '';

  build() {
    Column() {
      if (this.icon.length > 0) {
        Text(this.icon)
          .fontSize(64)
          .fontColor('#CCCCCC')
          .margin({ bottom: 16 })
      }

      if (this.title.length > 0) {
        Text(this.title)
          .fontSize(16)
          .fontColor('#999999')
          .margin({ bottom: 4 })
          .textAlign(TextAlign.Center)
      }

      if (this.subtitle.length > 0) {
        Text(this.subtitle)
          .fontSize(13)
          .fontColor('#BBBBBB')
          .textAlign(TextAlign.Center)
          .padding({ left: 32, right: 32 })
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
