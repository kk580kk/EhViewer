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

import { SettingsService } from '../service/SettingsService';

export class EhUrl {
  static readonly SITE_E: number = 0;
  static readonly SITE_EX: number = 1;

  static readonly DOMAIN_EX: string = 'exhentai.org';
  static readonly DOMAIN_E: string = 'e-hentai.org';
  static readonly DOMAIN_LOFI: string = 'lofi.e-hentai.org';

  static readonly HOST_EX: string = 'https://exhentai.org/';
  static readonly HOST_E: string = 'https://e-hentai.org/';

  static readonly API_SIGN_IN: string = 'https://forums.e-hentai.org/index.php?act=Login&CODE=01';
  static readonly API_E: string = EhUrl.HOST_E + 'api.php';
  static readonly API_EX: string = EhUrl.HOST_EX + 'api.php';

  static readonly URL_POPULAR_E: string = 'https://e-hentai.org/popular';
  static readonly URL_POPULAR_EX: string = 'https://exhentai.org/popular';

  static readonly URL_IMAGE_SEARCH_E: string = 'https://upload.e-hentai.org/image_lookup.php';
  static readonly URL_IMAGE_SEARCH_EX: string = 'https://exhentai.org/upload/image_lookup.php';

  static readonly URL_SIGN_IN: string = 'https://forums.e-hentai.org/index.php?act=Login';
  static readonly URL_REGISTER: string = 'https://forums.e-hentai.org/index.php?act=Reg&CODE=00';
  static readonly URL_FAVORITES_E: string = EhUrl.HOST_E + 'favorites.php';
  static readonly URL_FAVORITES_EX: string = EhUrl.HOST_EX + 'favorites.php';
  static readonly URL_FORUMS: string = 'https://forums.e-hentai.org/';

  static readonly REFERER_EX: string = 'https://exhentai.org';
  static readonly REFERER_E: string = 'https://e-hentai.org';

  static readonly URL_UCONFIG_E: string = EhUrl.HOST_E + 'uconfig.php';
  static readonly URL_UCONFIG_EX: string = EhUrl.HOST_EX + 'uconfig.php';

  static readonly URL_MY_TAGS_E: string = EhUrl.HOST_E + 'mytags';
  static readonly URL_MY_TAGS_EX: string = EhUrl.HOST_EX + 'mytags';

  static readonly URL_WATCHED_E: string = EhUrl.HOST_E + 'watched';
  static readonly URL_WATCHED_EX: string = EhUrl.HOST_EX + 'watched';

  private static readonly URL_PREFIX_THUMB_E: string = 'https://ehgt.org/';

  static getHost(): string {
    return SettingsService.getGallerySite() === EhUrl.SITE_EX ? EhUrl.HOST_EX : EhUrl.HOST_E;
  }

  static getApiUrl(): string {
    return SettingsService.getGallerySite() === EhUrl.SITE_EX ? EhUrl.API_EX : EhUrl.API_E;
  }

  static getReferer(): string {
    return SettingsService.getGallerySite() === EhUrl.SITE_EX ? EhUrl.REFERER_EX : EhUrl.REFERER_E;
  }

  static getOrigin(): string {
    return EhUrl.getReferer();
  }

  static getFavoritesUrl(): string {
    return SettingsService.getGallerySite() === EhUrl.SITE_EX ? EhUrl.URL_FAVORITES_EX : EhUrl.URL_FAVORITES_E;
  }

  static getPopularUrl(): string {
    return SettingsService.getGallerySite() === EhUrl.SITE_EX ? EhUrl.URL_POPULAR_EX : EhUrl.URL_POPULAR_E;
  }

  static getImageSearchUrl(): string {
    return SettingsService.getGallerySite() === EhUrl.SITE_EX ? EhUrl.URL_IMAGE_SEARCH_EX : EhUrl.URL_IMAGE_SEARCH_E;
  }

  static getWatchedUrl(): string {
    return SettingsService.getGallerySite() === EhUrl.SITE_EX ? EhUrl.URL_WATCHED_EX : EhUrl.URL_WATCHED_E;
  }

  static getUConfigUrl(): string {
    return SettingsService.getGallerySite() === EhUrl.SITE_EX ? EhUrl.URL_UCONFIG_EX : EhUrl.URL_UCONFIG_E;
  }

  static getMyTagsUrl(): string {
    return SettingsService.getGallerySite() === EhUrl.SITE_EX ? EhUrl.URL_MY_TAGS_EX : EhUrl.URL_MY_TAGS_E;
  }

  static getGalleryDetailUrl(gid: number, token: string, index: number = 0, allComment: boolean = false): string {
    let url = `${EhUrl.getHost()}g/${gid}/${token}/`;
    const params: string[] = [];
    if (index !== 0) {
      params.push(`p=${index}`);
    }
    if (allComment) {
      params.push('hc=1');
    }
    if (params.length > 0) {
      url += '?' + params.join('&');
    }
    return url;
  }

  static getPageUrl(gid: number, index: number, pToken: string): string {
    return `${EhUrl.getHost()}s/${pToken}/${gid}-${index + 1}`;
  }

  static getAddFavorites(gid: number, token: string): string {
    return `${EhUrl.getHost()}gallerypopups.php?gid=${gid}&t=${token}&act=addfav`;
  }

  static getDownloadArchive(gid: number, token: string, or_: string): string {
    return `${EhUrl.getHost()}archiver.php?gid=${gid}&token=${token}&or=${or_}`;
  }

  static getTagDefinitionUrl(tag: string): string {
    return 'https://ehwiki.org/wiki/' + tag.replace(/ /g, '_');
  }

  static getThumbUrlPrefix(): string {
    return EhUrl.URL_PREFIX_THUMB_E;
  }

  static getFixedPreviewThumbUrl(originUrl: string): string {
    try {
      const url = new URL(originUrl);
      const segments = url.pathname.split('/').filter(s => s.length > 0);
      if (segments.length < 3) return originUrl;

      const lastSegment = segments[segments.length - 1];
      const secondLast = segments[segments.length - 2];
      const thirdLast = segments[segments.length - 3];

      if (lastSegment.startsWith(thirdLast) &&
        lastSegment.startsWith(secondLast, thirdLast.length)) {
        return EhUrl.getThumbUrlPrefix() + thirdLast + '/' + secondLast + '/' + lastSegment;
      }
    } catch (_) {
      // ignore parse errors
    }
    return originUrl;
  }
}
