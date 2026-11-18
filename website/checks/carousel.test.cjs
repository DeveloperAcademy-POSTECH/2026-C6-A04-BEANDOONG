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
  const caption = { attributes: {}, setAttribute(key, value) { this.attributes[key] = value; } };
  const toggle = {
    handlers: {},
    addEventListener(key, fn) { this.handlers[key] = fn; },
  };
  return {
    slides,
    buttons,
    viewport,
    track,
    caption,
    toggle,
    handlers: {},
    addEventListener(key, fn) { this.handlers[key] = fn; },
    contains(target) { return buttons.includes(target) || target === toggle; },
    querySelector(selector) {
      return {
        "[data-carousel-viewport]": viewport,
        "[data-carousel-track]": track,
        "[data-carousel-caption]": caption,
        "[data-carousel-toggle]": toggle,
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
      toggle(name, active) { if (active) classes.add(name); else classes.delete(name); },
    },
  };
  const motion = {
    matches: reduce,
    listeners: [],
    addEventListener(_, fn) {
      this.listeners.push(fn);
    },
    change() { this.listeners.forEach((fn) => fn()); },
  };
  const timers = new Map();
  let nextTimer = 0;
  let language = "ko";
  const document = {
    hidden: false,
    handlers: {},
    addEventListener(type, fn) { (this.handlers[type] ||= []).push(fn); },
    dispatch(type) { this.handlers[type].forEach((fn) => fn()); },
    querySelectorAll: (selector) => (selector === "[data-carousel]" ? carousels : selector === "[data-reveal]" ? [reveal] : []),
  };
  let observer;
  class Observer {
    constructor(callback) {
      this.callback = callback;
      observer = this;
    }
    observe(item) {
      this.item = item;
      this.disconnected = false;
    }
    unobserve(item) {
      this.unobserved = item;
    }
    disconnect() {
      this.disconnected = true;
    }
  }
  vm.runInNewContext(fs.readFileSync(path.join(__dirname, "../script.js"), "utf8"), {
    document,
    translate: (copy) => language === "en" ? copy.replace("설명", "Caption") : copy,
    setInterval(callback, delay) {
      assert.equal(delay, 5000);
      timers.set(++nextTimer, callback);
      return nextTimer;
    },
    clearInterval(id) { timers.delete(id); },
    matchMedia: () => motion,
    window: { IntersectionObserver: Observer },
    IntersectionObserver: Observer,
  });
  const [state, result] = carousels;
  assert.equal(timers.size, reduce ? 0 : 2);
  assert.equal(state.caption.attributes["aria-live"], reduce ? "polite" : "off");
  if (!reduce) {
    // 자동 전환과 마지막 화면 이후 순환을 확인합니다.
    const tick = [...timers.values()][0];
    tick();
    assert.equal(state.caption.textContent, "설명 1");
    tick(); tick(); tick();
    assert.equal(state.caption.textContent, "설명 0");
    state.handlers.pointerenter({ pointerType: "mouse" });
    assert.equal(timers.size, 1);
    state.handlers.pointerleave({ pointerType: "mouse" });
    assert.equal(timers.size, 2);
    state.handlers.focusin();
    assert.equal(timers.size, 1);
    state.handlers.focusout({ relatedTarget: state.buttons[0] });
    assert.equal(timers.size, 1);
    state.handlers.focusout({ relatedTarget: null });
    assert.equal(timers.size, 2);
    state.toggle.handlers.click();
    assert.equal(timers.size, 1);
    document.hidden = true;
    document.dispatch("visibilitychange");
    assert.equal(timers.size, 0);
    document.hidden = false;
    document.dispatch("visibilitychange");
    assert.equal(timers.size, 1);
    state.toggle.handlers.click();
    assert.equal(timers.size, 2);
  }
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
  // 언어를 전환해도 현재 슬라이드가 유지되고 이후 자동 전환에도 적용됩니다.
  language = "en";
  document.dispatch("site-language-change");
  assert.equal(state.caption.textContent, "Caption 3");
  assert.equal(result.caption.textContent, "Caption 1");
  if (!reduce) {
    [...timers.values()][0]();
    assert.equal(state.caption.textContent, "Caption 0");
  }
  language = "ko";
  document.dispatch("site-language-change");
  if (!reduce) {
    assert(classes.has("reveal-pending"));
    observer.callback([{ target: reveal, isIntersecting: false }]);
    assert(!classes.has("is-visible"));
    observer.callback([{ target: reveal, isIntersecting: true }]);
    assert(classes.has("is-visible"));
    observer.callback([{ target: reveal, isIntersecting: false }]);
    assert(!classes.has("is-visible"));
    observer.callback([{ target: reveal, isIntersecting: true }]);
    assert(classes.has("is-visible"));
    assert.equal(observer.unobserved, undefined);
    motion.matches = true;
    motion.change();
    assert(observer.disconnected);
    assert.equal(timers.size, 0);
  } else {
    assert(classes.has("is-visible"));
    motion.matches = false;
    motion.change();
    assert.equal(observer.item, reveal);
    observer.callback([{ target: reveal, isIntersecting: false }]);
    assert(!classes.has("is-visible"));
    observer.callback([{ target: reveal, isIntersecting: true }]);
    assert(classes.has("is-visible"));
  }
}
console.log("PASS: 자동 재생·정지, 키보드·스와이프, 언어 전환, 반복 등장, 동작 줄이기");
