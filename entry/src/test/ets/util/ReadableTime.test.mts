import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { ReadableTime, type TimeUnit } from '../../../main/ets/util/ReadableTime.ets';

/** Simple English plural helper used across all test suites. */
function englishPlural(unit: TimeUnit, count: number): string {
  const plurals: Record<TimeUnit, [string, string]> = {
    year: ['year', 'years'],
    day: ['day', 'days'],
    hour: ['hour', 'hours'],
    minute: ['minute', 'minutes'],
    second: ['second', 'seconds'],
  };
  return count === 1 ? plurals[unit][0] : plurals[unit][1];
}

describe('ReadableTime', () => {

  beforeEach(() => {
    ReadableTime.initialize({
      fromTheFuture: 'from the future',
      justNow: 'just now',
      yesterday: 'yesterday',
      someDaysAgo: '{0} days ago',
      someMinutesAgo: (n: number) => `${n} minute${n !== 1 ? 's' : ''} ago`,
      someHoursAgo: (n: number) => `${n} hour${n !== 1 ? 's' : ''} ago`,
      unitPlural: englishPlural,
    });
  });

  describe('getPlainTime', () => {
    it('should format a known timestamp', () => {
      // 2024-03-15 14:30:00 UTC
      const ts = Date.UTC(2024, 2, 15, 14, 30, 0);
      const result = ReadableTime.getPlainTime(ts);
      // Result depends on timezone; just verify format pattern
      assert.match(result, /^\d{2}-\d{2}-\d{2} \d{2}:\d{2}$/);
    });
  });

  describe('getTimeInterval', () => {
    it('should return 0 seconds for 0', () => {
      assert.strictEqual(ReadableTime.getTimeInterval(0), '0 seconds');
    });

    it('should format seconds', () => {
      assert.strictEqual(ReadableTime.getTimeInterval(5000), '5 seconds');
    });

    it('should format minutes and seconds', () => {
      const result = ReadableTime.getTimeInterval(65_000);
      assert.strictEqual(result, '1 minute 5 seconds');
    });

    it('should format hours', () => {
      const result = ReadableTime.getTimeInterval(3_600_000);
      assert.strictEqual(result, '1 hour 0 minutes 0 seconds');
    });

    it('should format a complex duration', () => {
      const time =
        2 * ReadableTime.YEAR_MILLIS +
        3 * ReadableTime.DAY_MILLIS +
        4 * ReadableTime.HOUR_MILLIS +
        5 * ReadableTime.MINUTE_MILLIS +
        6 * ReadableTime.SECOND_MILLIS;
      const result = ReadableTime.getTimeInterval(time);
      assert.strictEqual(result, '2 years 3 days 4 hours 5 minutes 6 seconds');
    });
  });

  describe('getShortTimeInterval', () => {
    it('should pick the most significant unit', () => {
      const twoHours = 2 * ReadableTime.HOUR_MILLIS;
      assert.strictEqual(ReadableTime.getShortTimeInterval(twoHours), '2 hours');
    });

    it('should return seconds for small values', () => {
      assert.strictEqual(ReadableTime.getShortTimeInterval(500), '0 seconds');
    });
  });

  describe('getFilenamableTime', () => {
    it('should produce a dash-separated timestamp', () => {
      const result = ReadableTime.getFilenamableTime(Date.UTC(2024, 0, 15, 9, 30, 45, 123));
      assert.match(result, /^\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}-\d{3}$/);
    });
  });

  describe('getTimeAgo', () => {
    it('should return "just now" for recent time', () => {
      const recent = Date.now() - 10_000; // 10 seconds ago
      assert.strictEqual(ReadableTime.getTimeAgo(recent), 'just now');
    });

    it('should return minutes ago', () => {
      const fiveMin = Date.now() - 5 * ReadableTime.MINUTE_MILLIS;
      assert.strictEqual(ReadableTime.getTimeAgo(fiveMin), '5 minutes ago');
    });

    it('should return hours ago', () => {
      const threeHours = Date.now() - 3 * ReadableTime.HOUR_MILLIS;
      assert.strictEqual(ReadableTime.getTimeAgo(threeHours), '3 hours ago');
    });

    it('should return "yesterday"', () => {
      const yesterday = Date.now() - 30 * ReadableTime.HOUR_MILLIS;
      assert.strictEqual(ReadableTime.getTimeAgo(yesterday), 'yesterday');
    });

    it('should return days ago', () => {
      const threeDays = Date.now() - 3 * ReadableTime.DAY_MILLIS;
      assert.strictEqual(ReadableTime.getTimeAgo(threeDays), '3 days ago');
    });

    it('should return "from the future" for future time', () => {
      const future = Date.now() + 10 * ReadableTime.MINUTE_MILLIS;
      assert.strictEqual(ReadableTime.getTimeAgo(future), 'from the future');
    });

    it('should return "from the future" for non-positive time', () => {
      assert.strictEqual(ReadableTime.getTimeAgo(0), 'from the future');
      assert.strictEqual(ReadableTime.getTimeAgo(-1), 'from the future');
    });
  });
});
