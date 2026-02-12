/*
 * Copyright 2016 Hippo Seven
 * Ported to HarmonyOS ArkTS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 */

/**
 * InetValidator — validates IPv4/IPv6 addresses, hostnames, and port numbers.
 *
 * Used by proxy configuration and Hosts settings.
 */

const IPV4_REGEX = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/;

/**
 * Check whether the given string is a valid IPv4 address.
 *
 * Rules:
 *  - Must be four dot-separated decimal numbers
 *  - Each number must be 0–255
 *  - No leading zeros (e.g. "01.02.03.04" is invalid)
 */
export function isValidInet4Address(address: string | null): boolean {
  if (address === null || address.length === 0) return false;

  const match = IPV4_REGEX.exec(address);
  if (!match) return false;

  for (let i = 1; i <= 4; i++) {
    const segment = match[i];
    if (segment.length === 0) return false;
    const num = parseInt(segment, 10);
    if (isNaN(num) || num > 255) return false;
    // Reject leading zeros
    if (segment.length > 1 && segment.startsWith('0')) return false;
  }

  return true;
}

/**
 * Check whether the given string is a valid IPv6 address.
 *
 * Supports:
 *  - Full notation: 2001:0db8:0000:0000:0000:0000:0000:0001
 *  - Compressed notation: 2001:db8::1, ::1, ::
 *  - Embedded IPv4 suffix: ::ffff:192.168.1.1
 */
export function isValidInet6Address(address: string | null): boolean {
  if (address === null || address.length === 0) return false;

  const tokens = address.split(':');
  let first = 0;
  let last = tokens.length - 1;

  // Handle leading ::
  if (tokens[0].length === 0) {
    if (last - first > 0 && tokens[1].length === 0) {
      first++;
    } else {
      return false;
    }
  }

  // Handle trailing ::
  if (tokens[last].length === 0) {
    if (last - first > 0 && tokens[last - 1].length === 0) {
      last--;
    } else {
      return false;
    }
  }

  if (last - first + 1 > 8) return false;

  let hasRange = false;
  let groupCount = 0;

  for (let i = first; i <= last; i++) {
    if (tokens[i].length === 0) {
      if (hasRange) return false; // Only one :: allowed
      hasRange = true;
      continue;
    }

    // Embedded IPv4 (must be the last token)
    if (tokens[i].indexOf('.') >= 0) {
      if (i !== last) return false;
      if (!isValidInet4Address(tokens[i])) return false;
      groupCount += 2; // IPv4 = 4 bytes = 2 groups
      continue;
    }

    if (tokens[i].length > 4) return false;

    // All characters must be valid hex digits
    for (let k = 0; k < tokens[i].length; k++) {
      const c = tokens[i].charAt(k);
      if ('0123456789abcdefABCDEF'.indexOf(c) < 0) return false;
    }

    const value = parseInt(tokens[i], 16);
    if (isNaN(value) || value > 0xFFFF || value < 0) return false;

    groupCount++;
  }

  if (groupCount < 8 && !hasRange) return false;
  if (groupCount > 8) return false;

  return true;
}

/**
 * Check whether the given string is a valid IP address (IPv4 or IPv6).
 */
export function isValidInetAddress(address: string | null): boolean {
  return isValidInet4Address(address) || isValidInet6Address(address);
}

/**
 * Check whether the given string is a valid hostname (domain name).
 *
 * Rules:
 *  - Total length <= 253
 *  - Each label 1–63 characters
 *  - Allowed characters: a-z, 0-9, '-', '.'
 *  - Must not start or end with '.'
 *  - No consecutive dots
 */
export function isValidHost(host: string | null): boolean {
  if (host === null || host.length === 0) return false;
  if (host.length > 253) return false;

  let labelLength = 0;
  for (let i = 0; i < host.length; i++) {
    const ch = host.charAt(i);

    if (ch === '.') {
      if (labelLength < 1 || labelLength > 63) return false;
      labelLength = 0;
    } else {
      labelLength++;
    }

    if ((ch < 'a' || ch > 'z') && (ch < '0' || ch > '9') && ch !== '-' && ch !== '.') {
      return false;
    }
  }

  return labelLength >= 1 && labelLength <= 63;
}

/**
 * Check whether the given number is a valid port (0–65535).
 */
export function isValidInetPort(port: number): boolean {
  return Number.isInteger(port) && port >= 0 && port <= 65535;
}
