const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const path = require("node:path");

// 두 캐러셀의 선택 상태와 접근성 동작을 브라우저 없이 확인합니다.
function makeCarousel(count) {
  const slides = Array.from({ length: count }, (_, i) => ({
    dataset: { caption: `설명 ${i}` },
    attributes: {},
    inert: i > 0,
    setAttribute(key, value) {
      this.attributes[key] = value;
    },
  }));
  const buttons = slides.map(() => ({
    attributes: {},
    handlers: {},
    focused: false,
    setAttribute(key, value) {
      this.attributes[key] = value;
    },
    addEventListener(key, fn) {
      this.handlers[key] = fn;
    },
    focus() {
      this.focused = true;
    },
  }));
  const viewport = {
    handlers: {},
    addEventListener(key, fn) {
      this.handlers[key] = fn;
    },
    setPointerCapture() {},
  };
  const track = { style: {} };
  const caption = {};
  return {
    slides,
    buttons,
    viewport,
    track,
    caption,
    querySelector(selector) {
      return {
        "[data-carousel-viewport]": viewport,
        "[data-carousel-track]": track,
        "[data-carousel-caption]": caption,
      }[selector];
    },
    querySelectorAll(selector) {
      return selector === "[data-slide]" ? buttons : slides;
    },
  };
}

for (const reduce of [false, true]) {
  const carousels = [makeCarousel(4), makeCarousel(3)];
  const classes = new Set();
  const reveal = {
    classList: {
      add(...names) {
        names.forEach((name) => classes.add(name));
      },
    },
  };
  const motion = {
    matches: reduce,
    addEventListener(_, fn) {
      this.change = fn;
    },
  };
  let observer;
  class Observer {
    constructor(callback) {
      this.callback = callback;
      observer = this;
    }
    observe(item) {
      this.item = item;
    }
    unobserve(item) {
      this.unobserved = item;
    }
    disconnect() {
      this.disconnected = true;
    }
  }
  vm.runInNewContext(fs.readFileSync(path.join(__dirname, "../script.js"), "utf8"), {
    document: {
      querySelectorAll: (selector) => (selector === "[data-carousel]" ? carousels : [reveal]),
    },
    matchMedia: () => motion,
    window: { IntersectionObserver: Observer },
    IntersectionObserver: Observer,
  });
  const [state, result] = carousels;
  state.buttons[3].handlers.click();
  result.buttons[1].handlers.click();
  assert.equal(state.caption.textContent, "설명 3");
  assert.equal(result.caption.textContent, "설명 1");
  assert.equal(result.track.style.transform, "translateX(-100%)");
  assert.equal(result.slides[0].inert, true);
  assert.equal(result.slides[1].attributes["aria-hidden"], "false");
  assert.equal(result.buttons[1].attributes["aria-pressed"], "true");
  result.buttons[1].handlers.keydown({ key: "End", preventDefault() {} });
  assert.equal(result.caption.textContent, "설명 2");
  result.buttons[2].handlers.keydown({ key: "ArrowRight", preventDefault() {} });
  assert.equal(result.caption.textContent, "설명 0");
  result.buttons[0].handlers.keydown({ key: "ArrowLeft", preventDefault() {} });
  assert.equal(result.caption.textContent, "설명 2");
  result.buttons[2].handlers.keydown({ key: "Home", preventDefault() {} });
  assert.equal(result.buttons[0].focused, true);
  const down = { isPrimary: true, button: 0, clientX: 200, clientY: 200, pointerId: 1 };
  result.viewport.handlers.pointerdown(down);
  result.viewport.handlers.pointerup({ clientX: 100, clientY: 190 });
  assert.equal(result.caption.textContent, "설명 1");
  result.viewport.handlers.pointerdown(down);
  result.viewport.handlers.pointerup({ clientX: 190, clientY: 100 });
  assert.equal(result.caption.textContent, "설명 1");
  result.viewport.handlers.pointerdown(down);
  result.viewport.handlers.pointercancel();
  result.viewport.handlers.pointerup({ clientX: 100, clientY: 190 });
  assert.equal(result.caption.textContent, "설명 1");
  assert.equal(state.caption.textContent, "설명 3");
  if (!reduce) {
    assert(classes.has("reveal-pending"));
    observer.callback([{ target: reveal, isIntersecting: false }]);
    assert(!classes.has("is-visible"));
    observer.callback([{ target: reveal, isIntersecting: true }]);
    assert(classes.has("is-visible"));
    assert.equal(observer.unobserved, reveal);
    motion.matches = true;
    motion.change();
    assert(observer.disconnected);
  } else {
    assert.equal(classes.size, 0);
  }
}
console.log("PASS: 독립 캐러셀, 키보드, 스와이프, 접근성, 등장 효과");
