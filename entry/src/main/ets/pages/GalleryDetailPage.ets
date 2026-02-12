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
import { AppToolbar } from '../ui/components/AppToolbar.ets';

/**
 * Gallery detail page — placeholder for the full GalleryDetailScene.
 *
 * Receives route params: { gid: number, token: string }
 */

interface DetailParams {
  gid: number;
  token: string;
}

@Entry
@Component
struct GalleryDetailPage {
  @State gid: number = 0;
  @State token: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as DetailParams | undefined;
    if (params) {
      this.gid = params.gid ?? 0;
      this.token = params.token ?? '';
    }
  }

  build() {
    Column() {
      AppToolbar({
        title: 'Gallery Detail',
        showBack: true,
        onBack: () => { router.back(); },
      })

      Column() {
        Text(`GID: ${this.gid}`)
          .fontSize(16)
          .fontColor('#333333')
          .margin({ bottom: 4 })

        Text(`Token: ${this.token}`)
          .fontSize(16)
          .fontColor('#333333')
          .margin({ bottom: 16 })

        Text('Gallery detail content will be displayed here')
          .fontSize(14)
          .fontColor('#999999')
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
