import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  MutableBoolean,
  MutableNumber,
  MutableObject,
} from '../../../main/ets/util/MutableContainers.ets';

describe('MutableBoolean', () => {
  it('should default to false', () => {
    const mb = new MutableBoolean();
    assert.strictEqual(mb.value, false);
  });

  it('should accept initial value true', () => {
    const mb = new MutableBoolean(true);
    assert.strictEqual(mb.value, true);
  });

  it('should accept initial value false', () => {
    const mb = new MutableBoolean(false);
    assert.strictEqual(mb.value, false);
  });

  it('should allow mutation', () => {
    const mb = new MutableBoolean(false);
    mb.value = true;
    assert.strictEqual(mb.value, true);
    mb.value = false;
    assert.strictEqual(mb.value, false);
  });

  it('should be mutable inside a closure', () => {
    const mb = new MutableBoolean(false);
    const items = ['a', 'target', 'b'];
    items.forEach((item) => {
      if (item === 'target') {
        mb.value = true;
      }
    });
    assert.strictEqual(mb.value, true);
  });

  it('should convert to string', () => {
    assert.strictEqual(new MutableBoolean(true).toString(), 'true');
    assert.strictEqual(new MutableBoolean(false).toString(), 'false');
  });
});

describe('MutableNumber', () => {
  it('should default to 0', () => {
    const mn = new MutableNumber();
    assert.strictEqual(mn.value, 0);
  });

  it('should accept initial value', () => {
    const mn = new MutableNumber(42);
    assert.strictEqual(mn.value, 42);
  });

  it('should allow direct mutation', () => {
    const mn = new MutableNumber(10);
    mn.value = 20;
    assert.strictEqual(mn.value, 20);
  });

  it('should increment', () => {
    const mn = new MutableNumber(5);
    const result = mn.increment();
    assert.strictEqual(result, 6);
    assert.strictEqual(mn.value, 6);
  });

  it('should decrement', () => {
    const mn = new MutableNumber(5);
    const result = mn.decrement();
    assert.strictEqual(result, 4);
    assert.strictEqual(mn.value, 4);
  });

  it('should add positive delta', () => {
    const mn = new MutableNumber(10);
    const result = mn.add(5);
    assert.strictEqual(result, 15);
    assert.strictEqual(mn.value, 15);
  });

  it('should add negative delta', () => {
    const mn = new MutableNumber(10);
    const result = mn.add(-3);
    assert.strictEqual(result, 7);
    assert.strictEqual(mn.value, 7);
  });

  it('should work as a counter inside a closure', () => {
    const counter = new MutableNumber(0);
    const items = [1, 2, 3, 4, 5];
    items.forEach(() => {
      counter.increment();
    });
    assert.strictEqual(counter.value, 5);
  });

  it('should handle floating point values', () => {
    const mn = new MutableNumber(3.14);
    mn.add(0.01);
    assert.ok(Math.abs(mn.value - 3.15) < 1e-10);
  });

  it('should convert to string', () => {
    assert.strictEqual(new MutableNumber(42).toString(), '42');
    assert.strictEqual(new MutableNumber(0).toString(), '0');
    assert.strictEqual(new MutableNumber(-1).toString(), '-1');
  });
});

describe('MutableObject', () => {
  it('should hold a string value', () => {
    const mo = new MutableObject<string>('hello');
    assert.strictEqual(mo.value, 'hello');
  });

  it('should hold a number value', () => {
    const mo = new MutableObject<number>(42);
    assert.strictEqual(mo.value, 42);
  });

  it('should hold null', () => {
    const mo = new MutableObject<string | null>(null);
    assert.strictEqual(mo.value, null);
  });

  it('should allow mutation', () => {
    const mo = new MutableObject<string>('before');
    mo.value = 'after';
    assert.strictEqual(mo.value, 'after');
  });

  it('should hold an object reference', () => {
    const obj = { key: 'value' };
    const mo = new MutableObject(obj);
    assert.strictEqual(mo.value, obj);
    assert.strictEqual(mo.value.key, 'value');
  });

  it('should be mutable inside a closure', () => {
    const mo = new MutableObject<string | null>(null);
    const items = ['a', 'target', 'b'];
    items.forEach((item) => {
      if (item === 'target') {
        mo.value = item;
      }
    });
    assert.strictEqual(mo.value, 'target');
  });

  it('should convert to string', () => {
    assert.strictEqual(new MutableObject('test').toString(), 'test');
    assert.strictEqual(new MutableObject(123).toString(), '123');
  });
});
