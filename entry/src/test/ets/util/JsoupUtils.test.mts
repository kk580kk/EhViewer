import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { JsoupUtils } from '../../../main/ets/util/JsoupUtils.ets';
import type { HDocument, HElement, HElements } from '../../../main/ets/htmlparser/HtmlTypes.ets';

// ---- Minimal mock implementations of HElement / HElements / HDocument ----

function createElements(items: HElement[]): HElements {
  return {
    get(index: number): HElement { return items[index]; },
    size(): number { return items.length; },
    first(): HElement | null { return items.length > 0 ? items[0] : null; },
    last(): HElement | null { return items.length > 0 ? items[items.length - 1] : null; },
    isEmpty(): boolean { return items.length === 0; },
    text(): string { return items.map(e => e.text()).join(' '); },
    attr(_key: string): string { return ''; },
    [Symbol.iterator](): Iterator<HElement> {
      let i = 0;
      return {
        next(): IteratorResult<HElement> {
          if (i < items.length) return { value: items[i++], done: false };
          return { value: undefined as unknown as HElement, done: true };
        },
      };
    },
  };
}

const EMPTY_ELEMENTS = createElements([]);

function createElement(tag: string, classes: string[], children: HElement[] = []): HElement {
  const self: HElement = {
    nodeName(): string { return tag; },
    isElement(): boolean { return true; },
    asElement(): HElement | null { return self; },
    getElementById(_id: string): HElement | null { return null; },
    getElementsByClass(className: string): HElements {
      const matches = children.filter(c => c.hasClass(className));
      return createElements(matches);
    },
    getElementsByTag(tagName: string): HElements {
      const matches = children.filter(c => c.tagName() === tagName);
      return createElements(matches);
    },
    select(_cssQuery: string): HElements { return EMPTY_ELEMENTS; },
    children(): HElements { return createElements(children); },
    child(index: number): HElement { return children[index]; },
    parent(): HElement | null { return null; },
    previousElementSibling(): HElement | null { return null; },
    nextElementSibling(): HElement | null { return null; },
    tagName(): string { return tag; },
    text(): string { return `[${tag}]`; },
    ownText(): string { return `[${tag}]`; },
    html(): string { return `<${tag}>`; },
    attr(_key: string): string { return ''; },
    hasClass(className: string): boolean { return classes.includes(className); },
    hasAttr(_key: string): boolean { return false; },
  };
  return self;
}

function createDocument(children: HElement[]): HDocument {
  return createElement('html', [], children) as HDocument;
}

// ---- Tests ----

describe('JsoupUtils', () => {

  describe('getElementByClassFromDoc', () => {
    it('should return the first element with matching class', () => {
      const child1 = createElement('div', ['foo']);
      const child2 = createElement('div', ['foo']);
      const doc = createDocument([child1, child2]);

      const result = JsoupUtils.getElementByClassFromDoc(doc, 'foo');
      assert.strictEqual(result, child1);
    });

    it('should return null when no element matches', () => {
      const doc = createDocument([createElement('div', ['bar'])]);
      const result = JsoupUtils.getElementByClassFromDoc(doc, 'foo');
      assert.strictEqual(result, null);
    });

    it('should return null for empty document', () => {
      const doc = createDocument([]);
      const result = JsoupUtils.getElementByClassFromDoc(doc, 'foo');
      assert.strictEqual(result, null);
    });
  });

  describe('getElementByClass', () => {
    it('should return the first element with matching class', () => {
      const child1 = createElement('span', ['target']);
      const child2 = createElement('span', ['target']);
      const parent = createElement('div', [], [child1, child2]);

      const result = JsoupUtils.getElementByClass(parent, 'target');
      assert.strictEqual(result, child1);
    });

    it('should return null when no element matches', () => {
      const parent = createElement('div', [], [createElement('span', ['other'])]);
      const result = JsoupUtils.getElementByClass(parent, 'target');
      assert.strictEqual(result, null);
    });
  });

  describe('getElementByTag', () => {
    it('should return the first element with matching tag', () => {
      const a = createElement('a', []);
      const span = createElement('span', []);
      const parent = createElement('div', [], [a, span]);

      const result = JsoupUtils.getElementByTag(parent, 'a');
      assert.strictEqual(result, a);
    });

    it('should return null when no element matches', () => {
      const parent = createElement('div', [], [createElement('span', [])]);
      const result = JsoupUtils.getElementByTag(parent, 'a');
      assert.strictEqual(result, null);
    });

    it('should return null for element with no children', () => {
      const parent = createElement('div', []);
      const result = JsoupUtils.getElementByTag(parent, 'a');
      assert.strictEqual(result, null);
    });
  });
});
