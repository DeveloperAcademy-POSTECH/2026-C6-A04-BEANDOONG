const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

function element(attributes = {}) {
  return {
    attributes,
    handlers: {},
    setAttribute(key, value) { this.attributes[key] = value; },
    getAttribute(key) { return this.attributes[key]; },
    addEventListener(type, handler) { this.handlers[type] = handler; },
  };
}
const cards = Array.from({ length: 3 }, () => {
  const button = element({ "aria-expanded": "false" });
  const panel = element({ "aria-hidden": "true" });
  return Object.assign(element(), {
    button, panel,
    querySelector: (selector) => selector === ".problem-toggle" ? button : panel,
  });
});
vm.runInNewContext(fs.readFileSync(path.join(__dirname, "../script.js"), "utf8"), {
  document: { querySelectorAll: (selector) => selector === ".problem-card" ? cards : [] },
  matchMedia: () => ({ matches: true }),
  window: {},
});
const [first, second] = cards;
first.handlers.pointerenter({ pointerType: "mouse" });
assert.equal(first.button.getAttribute("aria-expanded"), "true");
assert.equal(first.panel.getAttribute("aria-hidden"), "false");
assert.equal(second.button.getAttribute("aria-expanded"), "false");
first.handlers.pointerleave({ pointerType: "mouse" });
assert.equal(first.panel.getAttribute("aria-hidden"), "true");
first.handlers.pointerenter({ pointerType: "touch" });
assert.equal(first.button.getAttribute("aria-expanded"), "false");
// 터치와 Enter/Space로 발생하는 기본 버튼 click은 동일하게 처리합니다.
first.button.handlers.click();
first.handlers.pointerleave({ pointerType: "touch" });
assert.equal(first.button.getAttribute("aria-expanded"), "true");
first.button.handlers.click();
assert.equal(first.panel.getAttribute("aria-hidden"), "true");
first.button.handlers.click();
first.button.handlers.keydown({ key: "Escape" });
assert.equal(first.button.getAttribute("aria-expanded"), "false");
first.button.handlers.click();
first.button.handlers.blur();
assert.equal(first.panel.getAttribute("aria-hidden"), "true");
console.log("PASS: 이야기 카드 호버, 터치 토글, Escape, 포커스 해제, 접근성 상태, 카드 독립성");
