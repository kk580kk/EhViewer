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
 * Logger — structured logging utility for HarmonyOS.
 *
 * Equivalent to Android's Log + LogCat utility.
 * Provides:
 *  - Log levels: VERBOSE, DEBUG, INFO, WARN, ERROR
 *  - TAG-based filtering
 *  - In-memory log buffer for crash reporting / diagnostics
 *  - Pluggable sink for production (hilog) vs test (console/buffer)
 *
 * Usage:
 *   const log = Logger.tag('EhEngine');
 *   log.d('Fetching gallery list');
 *   log.e('Request failed', error);
 */

// ---- Log levels ----

export const LogLevel = {
  VERBOSE: 0,
  DEBUG: 1,
  INFO: 2,
  WARN: 3,
  ERROR: 4,
  NONE: 5,
} as const;

export type LogLevel = (typeof LogLevel)[keyof typeof LogLevel];

/** String labels for each log level. */
const LEVEL_NAMES: string[] = ['V', 'D', 'I', 'W', 'E', '-'];

// ---- Log entry ----

export interface LogEntry {
  timestamp: number;
  level: LogLevel;
  tag: string;
  message: string;
  error?: Error;
}

// ---- Log sink interface ----

/**
 * A sink receives formatted log entries.
 * Production: forwards to HarmonyOS hilog.
 * Tests: collects entries for assertions.
 */
export interface LogSink {
  write(entry: LogEntry): void;
}

/** Default sink that writes to console. */
class ConsoleSink implements LogSink {
  write(entry: LogEntry): void {
    const time = new Date(entry.timestamp).toISOString();
    const prefix = `${time} ${LEVEL_NAMES[entry.level]}/${entry.tag}`;
    const msg = entry.error
      ? `${entry.message}: ${entry.error.message}`
      : entry.message;

    switch (entry.level) {
      case LogLevel.ERROR:
        console.error(`${prefix}: ${msg}`);
        break;
      case LogLevel.WARN:
        console.warn(`${prefix}: ${msg}`);
        break;
      case LogLevel.INFO:
        console.info(`${prefix}: ${msg}`);
        break;
      case LogLevel.DEBUG:
      case LogLevel.VERBOSE:
      default:
        console.log(`${prefix}: ${msg}`);
        break;
    }
  }
}

// ---- HiLog integration ----

/**
 * Abstraction over HarmonyOS hilog API.
 * Production: import hilog from '@ohos.hilog' and pass it here.
 * Tests: supply a mock implementation.
 */
export interface HiLogApi {
  debug(domain: number, tag: string, format: string, ...args: Object[]): void;
  info(domain: number, tag: string, format: string, ...args: Object[]): void;
  warn(domain: number, tag: string, format: string, ...args: Object[]): void;
  error(domain: number, tag: string, format: string, ...args: Object[]): void;
}

/**
 * Sink that forwards log entries to HarmonyOS hilog system log.
 *
 * Usage (production):
 *   import hilog from '@ohos.hilog';
 *   Logger.addSink(new HiLogSink(hilog, 0x0001));
 */
export class HiLogSink implements LogSink {
  private readonly hilog: HiLogApi;
  private readonly domain: number;

  constructor(hilog: HiLogApi, domain: number = 0x0000) {
    this.hilog = hilog;
    this.domain = domain;
  }

  write(entry: LogEntry): void {
    const msg = entry.error
      ? `${entry.message}: ${entry.error.message}`
      : entry.message;

    switch (entry.level) {
      case LogLevel.VERBOSE:
      case LogLevel.DEBUG:
        this.hilog.debug(this.domain, entry.tag, '%{public}s', msg);
        break;
      case LogLevel.INFO:
        this.hilog.info(this.domain, entry.tag, '%{public}s', msg);
        break;
      case LogLevel.WARN:
        this.hilog.warn(this.domain, entry.tag, '%{public}s', msg);
        break;
      case LogLevel.ERROR:
        this.hilog.error(this.domain, entry.tag, '%{public}s', msg);
        break;
      default:
        break;
    }
  }
}

/** Sink that collects entries in memory (for testing / crash reporting). */
export class BufferSink implements LogSink {
  private entries: LogEntry[] = [];
  private maxEntries: number;

  constructor(maxEntries: number = 500) {
    this.maxEntries = maxEntries;
  }

  write(entry: LogEntry): void {
    if (this.entries.length >= this.maxEntries) {
      this.entries.shift();
    }
    this.entries.push(entry);
  }

  getEntries(): LogEntry[] {
    return [...this.entries];
  }

  clear(): void {
    this.entries = [];
  }

  /**
   * Format all buffered entries as a single string.
   * Useful for saving to a file (crash report / logcat dump).
   */
  dump(): string {
    return this.entries.map(e => {
      const time = new Date(e.timestamp).toISOString();
      const errSuffix = e.error ? `\n  ${e.error.stack ?? e.error.message}` : '';
      return `${time} ${LEVEL_NAMES[e.level]}/${e.tag}: ${e.message}${errSuffix}`;
    }).join('\n');
  }
}

// ---- Logger class ----

export class Logger {
  private static globalLevel: LogLevel = LogLevel.VERBOSE;
  private static sinks: LogSink[] = [new ConsoleSink()];
  private static buffer: BufferSink = new BufferSink();

  private _tag: string;

  private constructor(tag: string) {
    this._tag = tag;
  }

  /** Create a logger with the given TAG. */
  static tag(tag: string): Logger {
    return new Logger(tag);
  }

  // ---- Global configuration ----

  /** Set the minimum log level. Messages below this level are discarded. */
  static setLevel(level: LogLevel): void {
    Logger.globalLevel = level;
  }

  /** Get the current minimum log level. */
  static getLevel(): LogLevel {
    return Logger.globalLevel;
  }

  /** Replace all sinks. Pass an empty array to disable console output. */
  static setSinks(sinks: LogSink[]): void {
    Logger.sinks = [...sinks];
  }

  /** Add a sink (e.g. add buffer sink alongside console). */
  static addSink(sink: LogSink): void {
    Logger.sinks.push(sink);
  }

  /** Get the global buffer sink for crash reporting / diagnostics. */
  static getBuffer(): BufferSink {
    return Logger.buffer;
  }

  /** Reset to default configuration (for testing). */
  static reset(): void {
    Logger.globalLevel = LogLevel.VERBOSE;
    Logger.sinks = [new ConsoleSink()];
    Logger.buffer = new BufferSink();
  }

  // ---- Instance methods ----

  v(message: string, error?: Error): void {
    this.log(LogLevel.VERBOSE, message, error);
  }

  d(message: string, error?: Error): void {
    this.log(LogLevel.DEBUG, message, error);
  }

  i(message: string, error?: Error): void {
    this.log(LogLevel.INFO, message, error);
  }

  w(message: string, error?: Error): void {
    this.log(LogLevel.WARN, message, error);
  }

  e(message: string, error?: Error): void {
    this.log(LogLevel.ERROR, message, error);
  }

  private log(level: LogLevel, message: string, error?: Error): void {
    if (level < Logger.globalLevel) return;

    const entry: LogEntry = {
      timestamp: Date.now(),
      level,
      tag: this._tag,
      message,
      error,
    };

    // Always write to the global buffer
    Logger.buffer.write(entry);

    // Write to all registered sinks
    for (const sink of Logger.sinks) {
      sink.write(entry);
    }
  }
}
