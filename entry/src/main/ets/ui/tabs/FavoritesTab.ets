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
 * Favorites tab content — placeholder for Phase-4 FavoritesScene.
 *
 * Will eventually show the user's cloud/local favourite galleries.
 */

@Component
export struct FavoritesTab {
  build() {
    Column() {
      Text('Favorites')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1a1a1a')
        .margin({ bottom: 8 })

      Text('Your favourite galleries will appear here')
        .fontSize(14)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
