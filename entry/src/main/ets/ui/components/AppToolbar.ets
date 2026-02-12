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
 * Reusable toolbar component for EhViewer pages.
 *
 * Equivalent to Android's ToolbarActivity base class — provides:
 *  - title text
 *  - optional back button
 *  - optional right-side action area (menu icon / overflow)
 */

@Component
export struct AppToolbar {
  /** Title displayed in the centre / left of the toolbar. */
  @Prop title: string = '';
  /** Whether to show a back / close button on the left. */
  @Prop showBack: boolean = false;
  /** Callback when the back button is tapped. */
  onBack: () => void = () => {};
  /** Optional builder for the right-side action area. */
  @BuilderParam rightActions: () => void;

  build() {
    Row() {
      if (this.showBack) {
        Text('\u2190')
          .fontSize(22)
          .fontColor('#333333')
          .width(48)
          .height(48)
          .textAlign(TextAlign.Center)
          .onClick(() => this.onBack())
      }

      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1a1a1a')
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding({ left: this.showBack ? 0 : 16 })

      if (this.rightActions) {
        this.rightActions()
      }
    }
    .width('100%')
    .height(56)
    .padding({ right: 8 })
    .backgroundColor('#FFFFFF')
    .shadow({ radius: 2, color: '#1a000000', offsetY: 1 })
  }
}
