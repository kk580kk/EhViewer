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
 * TagItem — data class for a tag in the auto-wrap layout.
 */
export class TagItem {
  text: string;
  color: string;
  bgColor: string;

  constructor(text: string, color: string = '#FFFFFF', bgColor: string = '#666666') {
    this.text = text;
    this.color = color;
    this.bgColor = bgColor;
  }
}

/**
 * AutoWrapLayout — a flex-based flow layout that wraps items automatically.
 *
 * Equivalent to Android's AutoWrapLayout. Used for displaying tags
 * in gallery detail pages where items flow left-to-right and wrap
 * to the next line when space runs out.
 *
 * Usage:
 *   AutoWrapLayout({
 *     tags: tagItems,
 *     onTagClick: (tag) => { ... },
 *   })
 */
@Component
export struct AutoWrapLayout {
  @Prop tags: TagItem[] = [];
  onTagClick: (tag: string) => void = () => {};

  build() {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
      ForEach(this.tags, (item: TagItem) => {
        Text(item.text)
          .fontSize(12)
          .fontColor(item.color)
          .backgroundColor(item.bgColor)
          .borderRadius(4)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .margin({ right: 6, bottom: 6 })
          .onClick(() => this.onTagClick(item.text))
      }, (item: TagItem, index: number) => `${index}_${item.text}`)
    }
    .width('100%')
  }
}
