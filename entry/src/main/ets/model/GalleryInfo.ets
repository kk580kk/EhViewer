/*
 * Copyright 2016 Hippo Seven
 * Ported to HarmonyOS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

export class GalleryInfo {
  static readonly S_LANG_JA: string = 'JA';
  static readonly S_LANG_EN: string = 'EN';
  static readonly S_LANG_ZH: string = 'ZH';
  static readonly S_LANG_NL: string = 'NL';
  static readonly S_LANG_FR: string = 'FR';
  static readonly S_LANG_DE: string = 'DE';
  static readonly S_LANG_HU: string = 'HU';
  static readonly S_LANG_IT: string = 'IT';
  static readonly S_LANG_KO: string = 'KO';
  static readonly S_LANG_PL: string = 'PL';
  static readonly S_LANG_PT: string = 'PT';
  static readonly S_LANG_RU: string = 'RU';
  static readonly S_LANG_ES: string = 'ES';
  static readonly S_LANG_TH: string = 'TH';
  static readonly S_LANG_VI: string = 'VI';

  static readonly S_LANGS: string[] = [
    GalleryInfo.S_LANG_EN, GalleryInfo.S_LANG_ZH, GalleryInfo.S_LANG_ES,
    GalleryInfo.S_LANG_KO, GalleryInfo.S_LANG_RU, GalleryInfo.S_LANG_FR,
    GalleryInfo.S_LANG_PT, GalleryInfo.S_LANG_TH, GalleryInfo.S_LANG_DE,
    GalleryInfo.S_LANG_IT, GalleryInfo.S_LANG_VI, GalleryInfo.S_LANG_PL,
    GalleryInfo.S_LANG_HU, GalleryInfo.S_LANG_NL,
  ];

  static readonly S_LANG_PATTERNS: RegExp[] = [
    /[(\\[]eng(?:lish)?[)\\]]|英訳/i,
    /[(\uFF08\\[]ch(?:inese)?[)\uFF09\\]]|[汉漢]化|中[国國][语語]|中文|中国翻訳/i,
    /[(\\[]spanish[)\\]]|[(\\[]Español[)\\]]|スペイン翻訳/i,
    /[(\\[]korean?[)\\]]|韓国翻訳/i,
    /[(\\[]rus(?:sian)?[)\\]]|ロシア翻訳/i,
    /[(\\[]fr(?:ench)?[)\\]]|フランス翻訳/i,
    /[(\\[]portuguese|ポルトガル翻訳/i,
    /[(\\[]thai(?: ภาษาไทย)?[)\\]]|แปลไทย|タイ翻訳/i,
    /[(\\[]german[)\\]]|ドイツ翻訳/i,
    /[(\\[]italiano?[)\\]]|イタリア翻訳/i,
    /[(\\[]vietnamese(?: Tiếng Việt)?[)\\]]|ベトナム翻訳/i,
    /[(\\[]polish[)\\]]|ポーランド翻訳/i,
    /[(\\[]hun(?:garian)?[)\\]]|ハンガリー翻訳/i,
    /[(\\[]dutch[)\\]]|オランダ翻訳/i,
  ];

  static readonly S_LANG_TAGS: string[] = [
    'language:english', 'language:chinese', 'language:spanish',
    'language:korean', 'language:russian', 'language:french',
    'language:portuguese', 'language:thai', 'language:german',
    'language:italian', 'language:vietnamese', 'language:polish',
    'language:hungarian', 'language:dutch',
  ];

  gid: number = 0;
  token: string = '';
  title: string = '';
  titleJpn: string = '';
  thumb: string = '';
  category: number = 0;
  posted: string = '';
  uploader: string = '';
  rating: number = 0;
  rated: boolean = false;
  simpleTags: string[] | null = null;
  pages: number = 0;
  thumbWidth: number = 0;
  thumbHeight: number = 0;
  spanSize: number = 0;
  spanIndex: number = 0;
  spanGroupIndex: number = 0;
  simpleLanguage: string | null = null;
  favoriteSlot: number = -2;
  favoriteName: string = '';

  /** Copy all fields from another GalleryInfo instance. */
  copyFrom(info: GalleryInfo): void {
    this.gid = info.gid;
    this.token = info.token;
    this.title = info.title;
    this.titleJpn = info.titleJpn;
    this.thumb = info.thumb;
    this.category = info.category;
    this.posted = info.posted;
    this.uploader = info.uploader;
    this.rating = info.rating;
    this.rated = info.rated;
    this.simpleTags = info.simpleTags ? [...info.simpleTags] : null;
    this.pages = info.pages;
    this.thumbWidth = info.thumbWidth;
    this.thumbHeight = info.thumbHeight;
    this.spanSize = info.spanSize;
    this.spanIndex = info.spanIndex;
    this.spanGroupIndex = info.spanGroupIndex;
    this.simpleLanguage = info.simpleLanguage;
    this.favoriteSlot = info.favoriteSlot;
    this.favoriteName = info.favoriteName;
  }

  /** Check equality by gid and token. */
  equals(other: GalleryInfo | null): boolean {
    if (other === null) return false;
    return this.gid === other.gid && this.token === other.token;
  }

  /** Serialize to a plain JSON-compatible object (replaces Android Parcelable). */
  toJSON(): Record<string, Object | null> {
    return {
      gid: this.gid,
      token: this.token,
      title: this.title,
      titleJpn: this.titleJpn,
      thumb: this.thumb,
      category: this.category,
      posted: this.posted,
      uploader: this.uploader,
      rating: this.rating,
      rated: this.rated,
      simpleTags: this.simpleTags,
      pages: this.pages,
      thumbWidth: this.thumbWidth,
      thumbHeight: this.thumbHeight,
      spanSize: this.spanSize,
      spanIndex: this.spanIndex,
      spanGroupIndex: this.spanGroupIndex,
      simpleLanguage: this.simpleLanguage,
      favoriteSlot: this.favoriteSlot,
      favoriteName: this.favoriteName,
    };
  }

  /** Deserialize from a plain object (replaces Android Parcelable.Creator). */
  static fromJSON(json: Record<string, Object | null>): GalleryInfo {
    const info = new GalleryInfo();
    info.gid = json['gid'] as number ?? 0;
    info.token = json['token'] as string ?? '';
    info.title = json['title'] as string ?? '';
    info.titleJpn = json['titleJpn'] as string ?? '';
    info.thumb = json['thumb'] as string ?? '';
    info.category = json['category'] as number ?? 0;
    info.posted = json['posted'] as string ?? '';
    info.uploader = json['uploader'] as string ?? '';
    info.rating = json['rating'] as number ?? 0;
    info.rated = json['rated'] as boolean ?? false;
    info.simpleTags = json['simpleTags'] as string[] | null ?? null;
    info.pages = json['pages'] as number ?? 0;
    info.thumbWidth = json['thumbWidth'] as number ?? 0;
    info.thumbHeight = json['thumbHeight'] as number ?? 0;
    info.spanSize = json['spanSize'] as number ?? 0;
    info.spanIndex = json['spanIndex'] as number ?? 0;
    info.spanGroupIndex = json['spanGroupIndex'] as number ?? 0;
    info.simpleLanguage = json['simpleLanguage'] as string | null ?? null;
    info.favoriteSlot = json['favoriteSlot'] as number ?? -2;
    info.favoriteName = json['favoriteName'] as string ?? '';
    return info;
  }

  generateSLang(): void {
    if (this.simpleTags !== null) {
      this.generateSLangFromTags();
    }
    if (this.simpleLanguage === null && this.title) {
      this.generateSLangFromTitle();
    }
  }

  private generateSLangFromTags(): void {
    if (!this.simpleTags) return;
    for (const tag of this.simpleTags) {
      for (let i = 0; i < GalleryInfo.S_LANGS.length; i++) {
        if (GalleryInfo.S_LANG_TAGS[i] === tag) {
          this.simpleLanguage = GalleryInfo.S_LANGS[i];
          return;
        }
      }
    }
  }

  private generateSLangFromTitle(): void {
    for (let i = 0; i < GalleryInfo.S_LANGS.length; i++) {
      if (GalleryInfo.S_LANG_PATTERNS[i].test(this.title)) {
        this.simpleLanguage = GalleryInfo.S_LANGS[i];
        return;
      }
    }
    this.simpleLanguage = null;
  }
}
