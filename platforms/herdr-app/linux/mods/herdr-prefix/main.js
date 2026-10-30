// Adapted from https://github.com/herdrdev/herdr-layout-examples/tree/main/tmux-prefix
// Licensed under Apache-2.0; see LICENSE.
import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { closeOverlay, focused, hc, nextCommand, props, run, theme } from "herdr";

const BINDINGS = [
  ["s", "Choose space", "mod.open", { name: "picker" }],
  ["c", "New space", "space.new"],
  ["r", "Rename space", "space.rename"],
  ["D", "Close space", "space.close"],
  ["(", "Previous space", "space.prev"],
  ["w", "Next space", "space.next"],
  ["t", "New tab", "tab.new"],
  ["p", "Previous tab", "tab.prev"],
  ["n", "Next tab", "tab.next"],
  ["T", "Rename tab", "tab.rename"],
  ["X", "Close tab", "tab.close"],
  ["v", "Split right", "pane.split", { direction: "right" }],
  ["-", "Split down", "pane.split", { direction: "down" }],
  ["x", "Close pane", "pane.close"],
  ["z", "Zoom pane", "pane.zoom"],
  ["h", "Focus left", "pane.go", { direction: "left" }],
  ["l", "Focus right", "pane.go", { direction: "right" }],
  ["b", "Toggle sidebar", "layout.toggle", { id: "sidebar" }],
  ["S", "Settings", "app.settings"],
  ["?", "Help", "app.help"],
  ...Array.from({ length: 9 }, (_, i) => [String(i + 1), `Tab ${i + 1}`, "tab.select", { index: i + 1 }]),
];

export default class HerdrPrefix extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.handle.focus();
    cx.spawn(async (cx) => {
      for (;;) {
        await nextCommand();
        this.sendPrefix(cx);
      }
    });
  }

  dismiss() {
    closeOverlay(props().overlay);
  }

  sendPrefix(cx) {
    const terminal = focused()?.terminal;
    if (!terminal) return this.dismiss();
    // Start forwarding before closing the view, which cancels its tasks.
    const pending = hc(["keys", terminal, "ctrl+s"]);
    cx.spawn(async () => {
      const result = await pending;
      if (result.code !== 0) console.log(`herdr-prefix: ${result.stderr}`);
    });
    this.dismiss();
  }

  key(e, cx) {
    cx.stop_propagation();
    if (e.key === "escape") return this.dismiss();
    const m = e.modifiers;
    if (m.control && e.key === "s") return this.sendPrefix(cx);
    if (m.control || m.alt || m.platform) return this.dismiss();
    const key = e.key_char ?? (m.shift && e.key.length === 1 ? e.key.toUpperCase() : e.key);
    const binding = BINDINGS.find(([candidate]) => candidate === key);
    this.dismiss();
    if (binding) run(binding[2], binding[3] ?? {});
  }

  render() {
    const t = theme();
    return v_flex().id("herdr-prefix").track_focus(this.handle)
      .on_key_down((e, cx) => this.key(e, cx))
      .p(14).gap(8).bg(t.popover).text_color(t.foreground).text_size(12)
      .child(h_flex().justify_between()
        .child(div().font_semibold().child("Ctrl+S · waiting for a key"))
        .child(div().text_color(t.muted).child("Esc cancel · Ctrl+S send prefix")))
      .child(v_flex().h(320).min_h(0).overflow_y_scrollbar().children(BINDINGS.map(([key, label]) =>
        h_flex().h(20).flex_none().items_center().gap(12)
          .child(div().w(40).text_color(t.accent).child(key))
          .child(div().flex_1().child(label)))))
      .child(div().text_color(t.muted).child("1–9 select tab"));
  }
}
