/*
 * Copyright 2024 EhViewer
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

import {
  SettingsViewModel,
  AboutInfo,
  SITE_LABELS,
  THUMB_RESOLUTION_LABELS,
} from '../../viewmodel/SettingsViewModel.ets';
import type { SettingsGroup, SettingItem } from '../../viewmodel/SettingsViewModel.ets';

/**
 * Settings tab — displays grouped preference items backed by SettingsService.
 *
 * Groups: EH, Read, Download, Advanced, Privacy, About
 */
@Component
export struct SettingsTab {
  private vm: SettingsViewModel = new SettingsViewModel();

  @State groups: SettingsGroup[] = [];
  @State showJpnTitle: boolean = false;
  @State downloadOriginImage: boolean = false;
  @State enableFingerprint: boolean = false;
  @State gallerySiteLabel: string = '';
  @State thumbResLabel: string = '';

  aboutToAppear(): void {
    this.refreshState();
  }

  private refreshState(): void {
    this.groups = this.vm.buildGroups();
    this.showJpnTitle = this.vm.getShowJpnTitle();
    this.downloadOriginImage = this.vm.getDownloadOriginImage();
    this.enableFingerprint = this.vm.getEnableFingerprint();
    this.gallerySiteLabel = this.vm.getGallerySiteLabel();
    this.thumbResLabel = this.vm.getThumbResolutionLabel();
  }

  build() {
    Column() {
      // Title bar
      Row() {
        Text('Settings')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1a1a1a')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      // Scrollable settings list
      Scroll() {
        Column() {
          // ---- EH Group ----
          this.SectionHeader('EH')

          this.SelectRow('Gallery Site', this.gallerySiteLabel, SITE_LABELS, (index: number) => {
            this.vm.setGallerySite(index);
            this.refreshState();
          })

          this.ToggleRow('Show Japanese Title', this.showJpnTitle, (val: boolean) => {
            this.vm.setShowJpnTitle(val);
            this.showJpnTitle = val;
            this.refreshState();
          })

          this.SelectRow('Thumbnail Resolution', this.thumbResLabel, THUMB_RESOLUTION_LABELS, (index: number) => {
            this.vm.setThumbResolution(index);
            this.refreshState();
          })

          // ---- Read Group ----
          this.SectionHeader('Read')

          this.InfoRow('Read Cache Size', `${this.vm.getReadCacheSize()} MB`)

          // ---- Download Group ----
          this.SectionHeader('Download')

          this.InfoRow('Multi-thread Download', `${this.vm.getMultiThreadDownload()} threads`)

          this.InfoRow('Preload Image', `${this.vm.getPreloadImage()} pages`)

          this.ToggleRow('Download Original Image', this.downloadOriginImage, (val: boolean) => {
            this.vm.setDownloadOriginImage(val);
            this.downloadOriginImage = val;
            this.refreshState();
          })

          this.InfoRow('Download Location', this.vm.getDownloadLocation() ?? 'Not set')

          // ---- Advanced Group ----
          this.SectionHeader('Advanced')

          this.ActionRow('Clear Memory Cache', 'Free up memory used by image cache')

          // ---- Privacy Group ----
          this.SectionHeader('Privacy')

          this.InfoRow('App Lock', this.vm.hasSecurityLock() ? 'Enabled' : 'Not set')

          this.ToggleRow('Fingerprint Unlock', this.enableFingerprint, (val: boolean) => {
            this.vm.setEnableFingerprint(val);
            this.enableFingerprint = val;
            this.refreshState();
          })

          // ---- About Group ----
          this.SectionHeader('About')

          this.InfoRow('Version', AboutInfo.getVersionString())

          this.InfoRow('Author', AboutInfo.getAuthor())

          this.ActionRow('Check for Updates', 'Check if a new version is available')

          // Bottom spacer
          Row().height(24)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  SectionHeader(title: string) {
    Text(title)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor('#4169E1')
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 6 })
  }

  @Builder
  ToggleRow(title: string, value: boolean, onChange: (val: boolean) => void) {
    Row() {
      Text(title)
        .fontSize(15)
        .fontColor('#1a1a1a')
        .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: value })
        .width(48)
        .height(28)
        .selectedColor('#4169E1')
        .onChange((isOn: boolean) => {
          onChange(isOn);
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(0)
  }

  @Builder
  SelectRow(title: string, currentLabel: string, options: string[], onSelect: (index: number) => void) {
    Row() {
      Column() {
        Text(title)
          .fontSize(15)
          .fontColor('#1a1a1a')
        Text(currentLabel)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('\u203A')
        .fontSize(20)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  InfoRow(title: string, summary: string) {
    Row() {
      Column() {
        Text(title)
          .fontSize(15)
          .fontColor('#1a1a1a')
        Text(summary)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  ActionRow(title: string, summary: string) {
    Row() {
      Column() {
        Text(title)
          .fontSize(15)
          .fontColor('#1a1a1a')
        Text(summary)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('\u203A')
        .fontSize(20)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
  }
}
