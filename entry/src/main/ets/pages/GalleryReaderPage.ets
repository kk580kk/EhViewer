/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import router from '@ohos.router';

/**
 * Gallery reader / viewer page — placeholder for the full reading scene.
 *
 * Receives route params: { gid: number, token: string, page?: number }
 */

interface ReaderParams {
  gid: number;
  token: string;
  page: number;
}

@Entry
@Component
struct GalleryReaderPage {
  @State gid: number = 0;
  @State token: string = '';
  @State page: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as ReaderParams | undefined;
    if (params) {
      this.gid = params.gid ?? 0;
      this.token = params.token ?? '';
      this.page = params.page ?? 0;
    }
  }

  build() {
    Stack() {
      // Full-screen reader placeholder
      Column() {
        Text('Reader')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .margin({ bottom: 8 })

        Text(`GID: ${this.gid}  Page: ${this.page + 1}`)
          .fontSize(14)
          .fontColor('#cccccc')
          .margin({ bottom: 16 })

        Text('Gallery reader will be displayed here')
          .fontSize(14)
          .fontColor('#999999')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#1a1a1a')

      // Back button overlay
      Text('\u2190')
        .fontSize(22)
        .fontColor('#ffffff')
        .width(48)
        .height(48)
        .textAlign(TextAlign.Center)
        .backgroundColor('#66000000')
        .borderRadius(24)
        .position({ x: 16, y: 16 })
        .onClick(() => { router.back(); })
    }
    .width('100%')
    .height('100%')
  }
}
