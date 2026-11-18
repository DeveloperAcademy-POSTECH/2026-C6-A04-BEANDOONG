const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const source = fs.readFileSync(path.join(__dirname, "../language.js"), "utf8");
const html = fs.readFileSync(path.join(__dirname, "../index.html"), "utf8");

// 실제 HTML의 한글 문장과 접근성 속성에 빠진 번역이 없는지 확인합니다.
const dictionary = vm.runInNewContext(`${source.slice(0, source.indexOf("const localizedText"))}; englishCopy`);
const markup = html.replace(/<!--[\s\S]*?-->/g, "");
const copies = markup.split(/<[^>]+>/).map((copy) => copy.trim().replace(/\s+/g, " "));
for (const match of markup.matchAll(/(?:aria-label|aria-roledescription|alt|content|data-caption)="([^"]*)"/g)) copies.push(match[1]);
const missing = copies.filter((copy) => /[가-힣]/.test(copy) && copy !== "한국어" && !dictionary[copy]);
assert.deepEqual([...new Set(missing)], []);

// 텍스트 노드만 바꾸므로 기존 인라인 구조와 동작을 유지하며 한국어로 복원됩니다.
for (const storageUnavailable of [false, true]) {
  const nodes = ["\n  스티밍 상태를 ", "눈으로 확인해요", "chic — 소리를 넘어, 나만의 한 잔으로"].map((nodeValue) => ({
    nodeValue, parentElement: { closest() { return false; } },
  }));
  const originals = nodes.map((node) => node.nodeValue);
  const image = {
    attributes: { alt: "Anne 프로필 사진" },
    getAttribute(name) { return this.attributes[name]; },
    setAttribute(name, value) { this.attributes[name] = value; },
  };
  const buttons = ["ko", "en"].map((language) => ({
    dataset: { language }, attributes: {}, handlers: {},
    setAttribute(name, value) { this.attributes[name] = value; },
    addEventListener(name, callback) { this.handlers[name] = callback; },
  }));
  let saved = "en";
  const events = [];
  const document = {
    documentElement: { lang: "ko" },
    createTreeWalker() {
      let index = -1;
      return { nextNode() { this.currentNode = nodes[++index]; return this.currentNode; } };
    },
    querySelectorAll(selector) { return selector === "[data-language]" ? buttons : [image]; },
    dispatchEvent(event) { events.push(event.type); },
  };
  vm.runInNewContext(source, {
    document, NodeFilter: { SHOW_TEXT: 4 }, Event,
    localStorage: {
      getItem() { if (storageUnavailable) throw new Error("Storage denied"); return saved; },
      setItem(_, value) { if (storageUnavailable) throw new Error("Storage denied"); saved = value; },
    },
  });
  assert.equal(document.documentElement.lang, storageUnavailable ? "ko" : "en");
  buttons[1].handlers.click();
  assert.equal(document.documentElement.lang, "en");
  assert.equal(nodes[0].nodeValue, "\n  See your steaming ");
  assert.equal(nodes[1].nodeValue, "at a glance");
  assert.equal(image.attributes.alt, "Portrait of Anne");
  assert.equal(buttons[1].attributes["aria-pressed"], "true");
  buttons[0].handlers.click();
  assert.equal(document.documentElement.lang, "ko");
  assert.deepEqual(nodes.map((node) => node.nodeValue), originals);
  assert.equal(image.attributes.alt, "Anne 프로필 사진");
  assert.equal(buttons[1].attributes["aria-pressed"], "false");
  assert.equal(events.length, 3);
  if (!storageUnavailable) assert.equal(saved, "ko");
}
assert(html.indexOf('src="./language.js"') < html.indexOf('src="./script.js"'));
console.log("PASS: 전체 번역 누락 검사, 한영 복원, 접근성 속성, 언어 저장, 저장소 차단");
