/*
 * Copyright 2015 Hippo Seven
 * Ported to HarmonyOS ArkTS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * Provides human-readable time formatting utilities.
 *
 * Strings are configured via {@link ReadableTime.initialize} so the caller
 * can inject localised resource strings (matching the Android R.string / R.plurals pattern).
 */
export interface ReadableTimeStrings {
  fromTheFuture: string;
  justNow: string;
  yesterday: string;
  /** e.g. "{0} days ago" – {0} is replaced with the count */
  someDaysAgo: string;
  /** Plural forms: (count) => localised string, e.g. "1 minute ago" / "5 minutes ago" */
  someMinutesAgo: (count: number) => string;
  someHoursAgo: (count: number) => string;
}

export class ReadableTime {

  static readonly SECOND_MILLIS = 1000;
  static readonly MINUTE_MILLIS = 60 * ReadableTime.SECOND_MILLIS;
  static readonly HOUR_MILLIS = 60 * ReadableTime.MINUTE_MILLIS;
  static readonly DAY_MILLIS = 24 * ReadableTime.HOUR_MILLIS;
  static readonly WEEK_MILLIS = 7 * ReadableTime.DAY_MILLIS;
  static readonly YEAR_MILLIS = 365 * ReadableTime.DAY_MILLIS;

  private static readonly SIZE = 5;

  private static readonly MULTIPLES: number[] = [
    ReadableTime.YEAR_MILLIS,
    ReadableTime.DAY_MILLIS,
    ReadableTime.HOUR_MILLIS,
    ReadableTime.MINUTE_MILLIS,
    ReadableTime.SECOND_MILLIS,
  ];

  private static readonly UNIT_NAMES: string[] = ['year', 'day', 'hour', 'minute', 'second'];

  private static strings: ReadableTimeStrings | null = null;

  /**
   * Inject localised strings. Must be called once during app startup.
   */
  static initialize(strings: ReadableTimeStrings): void {
    ReadableTime.strings = strings;
  }

  // ---- Formatters ----

  /**
   * Format a timestamp as "yy-MM-dd HH:mm".
   */
  static getPlainTime(time: number): string {
    const d = new Date(time);
    const yy = String(d.getFullYear()).slice(-2);
    const MM = ReadableTime.pad2(d.getMonth() + 1);
    const dd = ReadableTime.pad2(d.getDate());
    const HH = ReadableTime.pad2(d.getHours());
    const mm = ReadableTime.pad2(d.getMinutes());
    return `${yy}-${MM}-${dd} ${HH}:${mm}`;
  }

  /**
   * Return a human-friendly "time ago" string (e.g. "5 minutes ago", "yesterday").
   * Falls back to a date string for anything older than a week.
   * Requires {@link initialize} to have been called.
   */
  static getTimeAgo(time: number): string {
    const s = ReadableTime.strings!;
    const now = Date.now();

    if (time > now + 2 * ReadableTime.MINUTE_MILLIS || time <= 0) {
      return s.fromTheFuture;
    }

    const diff = now - time;
    if (diff < ReadableTime.MINUTE_MILLIS) {
      return s.justNow;
    } else if (diff < 2 * ReadableTime.MINUTE_MILLIS) {
      return s.someMinutesAgo(1);
    } else if (diff < 50 * ReadableTime.MINUTE_MILLIS) {
      return s.someMinutesAgo(Math.floor(diff / ReadableTime.MINUTE_MILLIS));
    } else if (diff < 90 * ReadableTime.MINUTE_MILLIS) {
      return s.someHoursAgo(1);
    } else if (diff < 24 * ReadableTime.HOUR_MILLIS) {
      return s.someHoursAgo(Math.floor(diff / ReadableTime.HOUR_MILLIS));
    } else if (diff < 48 * ReadableTime.HOUR_MILLIS) {
      return s.yesterday;
    } else if (diff < ReadableTime.WEEK_MILLIS) {
      const days = Math.floor(diff / ReadableTime.DAY_MILLIS);
      return s.someDaysAgo.replace('{0}', String(days));
    } else {
      return ReadableTime.formatDate(time, now);
    }
  }

  /**
   * Produce a duration string, e.g. "1 year 2 days 3 hours 4 minutes 5 seconds".
   */
  static getTimeInterval(time: number): string {
    const parts: string[] = [];
    let leftover = time;

    for (let i = 0; i < ReadableTime.SIZE; i++) {
      const multiple = ReadableTime.MULTIPLES[i];
      const quotient = Math.floor(leftover / multiple);
      const remainder = leftover % multiple;
      if (parts.length > 0 || quotient !== 0 || i === ReadableTime.SIZE - 1) {
        parts.push(`${quotient} ${ReadableTime.UNIT_NAMES[i]}${quotient !== 1 ? 's' : ''}`);
      }
      leftover = remainder;
    }

    return parts.join(' ');
  }

  /**
   * Return the single most significant time unit, e.g. "3 hours".
   */
  static getShortTimeInterval(time: number): string {
    for (let i = 0; i < ReadableTime.SIZE; i++) {
      const multiple = ReadableTime.MULTIPLES[i];
      const quotient = Math.floor(time / multiple);
      if (time > multiple * 1.5 || i === ReadableTime.SIZE - 1) {
        return `${quotient} ${ReadableTime.UNIT_NAMES[i]}${quotient !== 1 ? 's' : ''}`;
      }
    }
    return '0 seconds';
  }

  /**
   * Return a filename-safe timestamp, e.g. "2024-01-15-09-30-45-123".
   */
  static getFilenamableTime(time: number): string {
    const d = new Date(time);
    return [
      d.getFullYear(),
      ReadableTime.pad2(d.getMonth() + 1),
      ReadableTime.pad2(d.getDate()),
      ReadableTime.pad2(d.getHours()),
      ReadableTime.pad2(d.getMinutes()),
      ReadableTime.pad2(d.getSeconds()),
      ReadableTime.pad3(d.getMilliseconds()),
    ].join('-');
  }

  // ---- Helpers ----

  private static pad2(n: number): string {
    return n < 10 ? `0${n}` : String(n);
  }

  private static pad3(n: number): string {
    if (n < 10) return `00${n}`;
    if (n < 100) return `0${n}`;
    return String(n);
  }

  /**
   * Format a date, using the year when it differs from the current year.
   * Uses locale-aware formatting, with specific support for Chinese locales.
   */
  private static formatDate(time: number, now: number): string {
    const timeDate = new Date(time);
    const nowDate = new Date(now);
    const sameYear = timeDate.getFullYear() === nowDate.getFullYear();
    const isZh = ReadableTime.isChineseLocale();

    if (isZh) {
      if (sameYear) {
        return `${timeDate.getMonth() + 1}月${timeDate.getDate()}日`;
      }
      return `${timeDate.getFullYear()}年${timeDate.getMonth() + 1}月${timeDate.getDate()}日`;
    }

    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const month = monthNames[timeDate.getMonth()];
    if (sameYear) {
      return `${month} ${timeDate.getDate()}`;
    }
    return `${month} ${timeDate.getDate()}, ${timeDate.getFullYear()}`;
  }

  private static isChineseLocale(): boolean {
    try {
      // In HarmonyOS, use the system locale detection
      const locale = Intl.DateTimeFormat().resolvedOptions().locale;
      return locale.startsWith('zh');
    } catch (_e) {
      return false;
    }
  }
}
