import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  ViewTransition,
  TransitionConfig,
  TransitionType,
} from '../../../main/ets/util/ViewTransition.ets';

describe('TransitionConfig', () => {
  it('should use defaults', () => {
    const config = new TransitionConfig();
    assert.strictEqual(config.type, TransitionType.FADE);
    assert.strictEqual(config.duration, 300);
    assert.strictEqual(config.curve, 'ease-in-out');
  });

  it('isSlide should return false for FADE', () => {
    assert.strictEqual(new TransitionConfig(TransitionType.FADE).isSlide(), false);
  });

  it('isSlide should return true for SLIDE_LEFT', () => {
    assert.strictEqual(new TransitionConfig(TransitionType.SLIDE_LEFT).isSlide(), true);
  });
});

describe('ViewTransition', () => {
  it('fade should create a fade config', () => {
    const config = ViewTransition.fade(200);
    assert.strictEqual(config.type, TransitionType.FADE);
    assert.strictEqual(config.duration, 200);
  });

  it('slideLeft should create slide-left config', () => {
    const config = ViewTransition.slideLeft();
    assert.strictEqual(config.type, TransitionType.SLIDE_LEFT);
    assert.strictEqual(config.duration, 300);
  });

  it('slideRight should create slide-right config', () => {
    const config = ViewTransition.slideRight(400);
    assert.strictEqual(config.type, TransitionType.SLIDE_RIGHT);
    assert.strictEqual(config.duration, 400);
  });

  it('slideUp should create slide-up config', () => {
    assert.strictEqual(ViewTransition.slideUp().type, TransitionType.SLIDE_UP);
  });

  it('slideDown should create slide-down config', () => {
    assert.strictEqual(ViewTransition.slideDown().type, TransitionType.SLIDE_DOWN);
  });

  describe('reverse', () => {
    it('should reverse SLIDE_LEFT to SLIDE_RIGHT', () => {
      const rev = ViewTransition.reverse(ViewTransition.slideLeft());
      assert.strictEqual(rev.type, TransitionType.SLIDE_RIGHT);
    });

    it('should reverse SLIDE_RIGHT to SLIDE_LEFT', () => {
      const rev = ViewTransition.reverse(ViewTransition.slideRight());
      assert.strictEqual(rev.type, TransitionType.SLIDE_LEFT);
    });

    it('should reverse SLIDE_UP to SLIDE_DOWN', () => {
      const rev = ViewTransition.reverse(ViewTransition.slideUp());
      assert.strictEqual(rev.type, TransitionType.SLIDE_DOWN);
    });

    it('should reverse SLIDE_DOWN to SLIDE_UP', () => {
      const rev = ViewTransition.reverse(ViewTransition.slideDown());
      assert.strictEqual(rev.type, TransitionType.SLIDE_UP);
    });

    it('should keep FADE as FADE', () => {
      const rev = ViewTransition.reverse(ViewTransition.fade());
      assert.strictEqual(rev.type, TransitionType.FADE);
    });

    it('should preserve duration', () => {
      const rev = ViewTransition.reverse(ViewTransition.slideLeft(500));
      assert.strictEqual(rev.duration, 500);
    });
  });
});
