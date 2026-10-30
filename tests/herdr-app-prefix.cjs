const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const root = path.join(__dirname, "..", "platforms", "herdr-app", "linux");
const keys = JSON.parse(fs.readFileSync(path.join(root, "keys.json"), "utf8"));
assert.equal(keys.global["ctrl-s"], "mod.open:herdr-prefix");
for (const [key, direction] of Object.entries({ h: "left", j: "down", k: "up", l: "right" })) {
  for (const modifier of ["alt", "ctrl"]) {
    assert.equal(keys.global[`${modifier}-${key}`], `pane.go:${direction}`);
  }
}
assert.equal(keys.terminal["ctrl-s"], "mod.open:herdr-prefix");
assert.equal(keys["mod:herdr-prefix"]["ctrl-s"], "herdr-prefix.send-prefix");

const calls = [];
const context = vm.createContext({
  View: class {},
  closeOverlay: (id) => calls.push(["close", id]),
  props: () => ({ overlay: "prefix" }),
  focused: () => ({ terminal: "t1" }),
  hc: (args) => { calls.push(["hc", ...args]); return Promise.resolve({ code: 0 }); },
  run: (command, args) => calls.push(["run", command, JSON.stringify(args)]),
  console,
});
const source = fs.readFileSync(path.join(root, "mods/herdr-prefix/main.js"), "utf8")
  .replace(/^import .*;\n/gm, "")
  .replace("export default class HerdrPrefix", "class HerdrPrefix");
vm.runInContext(source + "\nglobalThis.Subject = HerdrPrefix;", context);
const mod = new context.Subject();
const cx = { stop_propagation() {}, spawn: (fn) => fn() };
function press(key, options = {}) {
  calls.length = 0;
  mod.key({ key, key_char: options.char ?? key, modifiers: { control: false, alt: false, platform: false, shift: false, ...options } }, cx);
  return calls;
}
assert.deepEqual(press("t"), [["close", "prefix"], ["run", "tab.new", "{}"]]);
assert.deepEqual(press("v"), [["close", "prefix"], ["run", "pane.split", '{"direction":"right"}']]);
assert.deepEqual(press("-"), [["close", "prefix"], ["run", "pane.split", '{"direction":"down"}']]);
assert.deepEqual(press("s"), [["close", "prefix"], ["run", "mod.open", '{"name":"picker"}']]);
assert.deepEqual(press("2"), [["close", "prefix"], ["run", "tab.select", '{"index":2}']]);
assert.deepEqual(press("s", { control: true }), [["hc", "keys", "t1", "ctrl+s"], ["close", "prefix"]]);
assert.deepEqual(press("escape"), [["close", "prefix"]]);
console.log("herdr-app prefix checks passed");
