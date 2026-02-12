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
 * FabAction — data class for a secondary FAB action.
 */
export class FabAction {
  icon: string;
  label: string;
  id: string;

  constructor(id: string, icon: string, label: string = '') {
    this.id = id;
    this.icon = icon;
    this.label = label;
  }
}

/**
 * FabLayout — floating action button with optional expandable secondary actions.
 *
 * Equivalent to Android's FabLayout. Provides a primary FAB and
 * optional secondary action buttons that expand on long-press or toggle.
 *
 * Usage:
 *   FabLayout({
 *     icon: '+',
 *     actions: [
 *       new FabAction('search', '\u{1F50D}', 'Search'),
 *       new FabAction('filter', '\u{2699}', 'Filter'),
 *     ],
 *     onPrimaryClick: () => { ... },
 *     onActionClick: (id) => { ... },
 *   })
 */
@Component
export struct FabLayout {
  @Prop icon: string = '+';
  @Prop actions: FabAction[] = [];
  @State expanded: boolean = false;
  onPrimaryClick: () => void = () => {};
  onActionClick: (actionId: string) => void = () => {};

  build() {
    Column() {
      // Secondary actions (shown when expanded)
      if (this.expanded && this.actions.length > 0) {
        Column() {
          ForEach(this.actions, (action: FabAction) => {
            Row() {
              if (action.label.length > 0) {
                Text(action.label)
                  .fontSize(12)
                  .fontColor('#FFFFFF')
                  .backgroundColor('#66000000')
                  .borderRadius(4)
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .margin({ right: 8 })
              }

              Text(action.icon)
                .fontSize(20)
                .fontColor('#FFFFFF')
                .width(44)
                .height(44)
                .textAlign(TextAlign.Center)
                .backgroundColor('#4169E1')
                .borderRadius(22)
                .shadow({ radius: 4, color: '#33000000', offsetY: 2 })
                .onClick(() => {
                  this.expanded = false;
                  this.onActionClick(action.id);
                })
            }
            .justifyContent(FlexAlign.End)
            .margin({ bottom: 8 })
          }, (action: FabAction) => action.id)
        }
        .alignItems(HorizontalAlign.End)
        .margin({ bottom: 8 })
      }

      // Primary FAB
      Text(this.icon)
        .fontSize(24)
        .fontColor('#FFFFFF')
        .width(56)
        .height(56)
        .textAlign(TextAlign.Center)
        .backgroundColor('#4169E1')
        .borderRadius(28)
        .shadow({ radius: 6, color: '#33000000', offsetY: 3 })
        .onClick(() => {
          if (this.actions.length > 0) {
            this.expanded = !this.expanded;
          } else {
            this.onPrimaryClick();
          }
        })
    }
    .alignItems(HorizontalAlign.End)
    .position({ right: 16, bottom: 16 })
  }
}
