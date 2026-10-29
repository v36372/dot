import { open, supportsFollowCursor } from "glimpseui";
import { createServer } from "node:net";
import { createInterface } from "node:readline";
import { readFileSync, unlinkSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { pidFilePath, pluginRoot } from "./paths.mjs";
import { getCompanionSocketPath, usesNamedPipe } from "./socket-path.mjs";
import { buildSnapshot, DEMO_ROWS } from "./snapshot.mjs";

const SOCK = getCompanionSocketPath();
const ROOT = pluginRoot();
const RUNCAT_FONT_DATA_URL = `data:font/truetype;base64,${readFileSync(join(ROOT, "assets", "cat.ttf")).toString("base64")}`;
const POLL_MS = 1000;
const IDLE_EXIT_MS = 8000;
const DONE_HOLD_MS = 3000;
const MAX_ROWS = 6;

const STATUS_COLOR = {
  working: "#F59E0B",
  blocked: "#FDE68A",
  done: "#4ADE80",
};

const STATUS_LABEL = {
  blocked: "Needs you",
  done: "Done",
};

// Same RunCat window as extensions/cat.ts: U+ECB4..U+ECBD, 5 steps each way.
const RUNCAT_RIGHT = ["\uECB4", "\uECB5", "\uECB6", "\uECB7", "\uECB8"];
const RUNCAT_LEFT = ["\uECB9", "\uECBA", "\uECBB", "\uECBC", "\uECBD"];

function buildHTML() {
  return `<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
@font-face {
  font-family: 'RunCat';
  src: url('${RUNCAT_FONT_DATA_URL}') format('truetype');
}
* { box-sizing: border-box; margin: 0; padding: 0; }
body {
  background: transparent !important;
  font-family: system-ui, -apple-system, sans-serif;
  font-size: 12px;
  font-weight: 600;
  -webkit-font-smoothing: antialiased;
  text-rendering: optimizeLegibility;
  font-optical-sizing: auto;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  height: 100vh;
  user-select: none;
  pointer-events: none;
}
#pill {
  display: flex;
  flex-direction: column;
  width: max-content;
  max-width: 100%;
  background: rgba(18, 18, 22, 0.90);
  -webkit-backdrop-filter: blur(22px) saturate(160%);
  backdrop-filter: blur(22px) saturate(160%);
  border: 1px solid rgba(255,255,255,0.14);
  border-radius: 16px;
  overflow: hidden;
  box-shadow:
    0 12px 36px rgba(0,0,0,0.40),
    inset 0 1px 0 rgba(255,255,255,0.14);
  transition: opacity 0.3s ease-out;
}
.row {
  display: grid;
  grid-template-columns: 40px auto 1fr auto auto;
  align-items: center;
  column-gap: 10px;
  padding: 8px 14px 8px 10px;
  min-height: 36px;
}
.row + .row {
  border-top: 1px solid rgba(255,255,255,0.07);
}
.row.blocked {
  align-items: start;
  background: linear-gradient(90deg, rgba(253, 230, 138, 0.11), rgba(253, 230, 138, 0.03) 52%, transparent);
  box-shadow: inset 2px 0 0 rgba(251, 191, 36, 0.82);
}
.row.blocked .track { margin-top: 8px; }
.row.blocked .chip,
.row.blocked .elapsed { margin-top: 6px; }
.row.done {
  background: linear-gradient(90deg, rgba(74, 222, 128, 0.08), transparent 50%);
}
.track {
  grid-column: 1;
  position: relative;
  width: 40px;
  height: 18px;
  overflow: visible;
}
.cat {
  position: absolute;
  top: 1px;
  left: 0;
  width: 16px;
  height: 16px;
  color: #22C55E;
  font-family: 'RunCat';
  font-size: 15px;
  font-weight: 400;
  line-height: 16px;
  transform: translateX(var(--cat-x, 0px));
  transition: color 0.2s ease;
}
.row.blocked .cat {
  animation: cat-glow 1.15s ease-in-out infinite alternate;
}
@keyframes cat-glow {
  from {
    filter: drop-shadow(0 0 2px #FDE68A) drop-shadow(0 0 6px rgba(251, 191, 36, 0.45));
  }
  to {
    filter: drop-shadow(0 0 3px #FFFBEB) drop-shadow(0 0 9px rgba(251, 191, 36, 0.7));
  }
}
.copy { grid-column: 2; min-width: 0; }
.who {
  display: flex;
  align-items: center;
  white-space: nowrap;
}
.agent {
  color: rgba(255,255,255,0.96);
  font-weight: 600;
  letter-spacing: -0.02em;
}
.dot {
  width: 3px;
  height: 3px;
  border-radius: 50%;
  background: rgba(255,255,255,0.28);
  margin: 0 8px;
  flex-shrink: 0;
}
.workspace {
  color: rgba(255,255,255,0.46);
  font-weight: 500;
}
.chip {
  grid-column: 4;
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.01em;
  padding: 3px 8px;
  border-radius: 7px;
  line-height: 1.2;
  white-space: nowrap;
  border: 1px solid transparent;
}
.chip.working {
  color: #FBBF24;
  background: rgba(245, 158, 11, 0.16);
  border-color: rgba(245, 158, 11, 0.20);
}
.chip.blocked {
  color: #FDE68A;
  background: rgba(253, 230, 138, 0.14);
  border: 1px solid rgba(253, 230, 138, 0.22);
}
.chip.done {
  color: #86EFAC;
  background: rgba(34, 197, 94, 0.16);
}
.elapsed {
  grid-column: 5;
  font-family: ui-monospace, 'SF Mono', monospace;
  font-size: 10px;
  font-variant-numeric: tabular-nums;
  font-weight: 500;
  color: rgba(255,255,255,0.38);
  white-space: nowrap;
  min-width: 2.5em;
  text-align: right;
}
.elapsed.frozen { color: rgba(255,255,255,0.72); font-weight: 600; }
.detail {
  margin-top: 3px;
  color: rgba(255,255,255,0.90);
  font-family: ui-monospace, 'SF Mono', Menlo, monospace;
  font-size: 11.5px;
  font-weight: 500;
  letter-spacing: -0.011em;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 460px;
}
</style>
</head>
<body>
<div id="pill"></div>
<script>
var _rows = {};
var _startTimes = {};
var _frozenElapsed = {};
var _tickTimer = null;
var _catTimer = null;
var _catFrame = 0;
var RIGHT = ${JSON.stringify(RUNCAT_RIGHT)};
var LEFT = ${JSON.stringify(RUNCAT_LEFT)};
var CAT_STEP = 6;
var CAT_MS = 120;
var CAT_LEN = 10;

function esc(s) {
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

function fmtElapsed(ms) {
  var s = Math.floor(ms / 1000);
  if (s < 60) return s + 's';
  var m = Math.floor(s / 60);
  s = s % 60;
  return m + 'm ' + (s < 10 ? '0' : '') + s + 's';
}

function catPose(frame) {
  if (frame < 5) return { glyph: RIGHT[frame], step: frame };
  var i = frame - 5;
  return { glyph: LEFT[4 - i], step: 4 - i };
}

function paintCats() {
  var ids = Object.keys(_rows);
  for (var i = 0; i < ids.length; i++) {
    var r = _rows[ids[i]];
    var el = document.getElementById('cat-' + ids[i]);
    if (!el) continue;
    var pose;
    if (r.status === 'blocked') pose = { glyph: RIGHT[0], step: 0 };
    else if (r.status === 'done') pose = { glyph: RIGHT[0], step: 0 };
    else pose = catPose(_catFrame);
    el.textContent = pose.glyph;
    el.style.setProperty('--cat-x', (pose.step * CAT_STEP) + 'px');
  }
}

function startTick() {
  if (_tickTimer) return;
  _tickTimer = setInterval(function() {
    var ids = Object.keys(_rows);
    if (ids.length === 0) { clearInterval(_tickTimer); _tickTimer = null; return; }
    for (var i = 0; i < ids.length; i++) {
      if (_frozenElapsed[ids[i]]) continue;
      var el = document.getElementById('elapsed-' + ids[i]);
      if (el && _startTimes[ids[i]]) {
        el.textContent = fmtElapsed(Date.now() - _startTimes[ids[i]]);
      }
    }
  }, 1000);
}

function startCatTick() {
  if (_catTimer) return;
  _catTimer = setInterval(function() {
    var ids = Object.keys(_rows);
    if (ids.length === 0) { clearInterval(_catTimer); _catTimer = null; return; }
    _catFrame = (_catFrame + 1) % CAT_LEN;
    paintCats();
  }, CAT_MS);
}

function sync(rows) {
  var next = {};
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i];
    var id = String(row.id);
    if (!_startTimes[id]) _startTimes[id] = Date.now();
    if (row.status === 'done' && _startTimes[id] && !_frozenElapsed[id]) {
      _frozenElapsed[id] = fmtElapsed(Date.now() - _startTimes[id]);
    }
    if (row.status !== 'done') delete _frozenElapsed[id];
    next[id] = row;
  }
  for (var oldId in _rows) {
    if (!next[oldId]) {
      delete _startTimes[oldId];
      delete _frozenElapsed[oldId];
    }
  }
  _rows = next;
  render();
  startTick();
  startCatTick();
}

function render() {
  var pill = document.getElementById('pill');
  var ids = Object.keys(_rows);
  if (ids.length === 0) {
    pill.style.opacity = '0';
    setTimeout(function() { if (Object.keys(_rows).length === 0) pill.innerHTML = ''; }, 350);
    return;
  }
  pill.style.opacity = '1';
  var html = '';
  for (var i = 0; i < ids.length; i++) {
    var r = _rows[ids[i]];
    html += '<div id="r-' + ids[i] + '" class="row ' + r.status + '">';
    html += '<span class="track"><span id="cat-' + ids[i] + '" class="cat" style="color:' + (r.color || '#6B7280') + '"></span></span>';
    html += '<div class="copy">';
    html += '<div class="who"><span class="agent">' + esc(r.agent || 'agent') + '</span><span class="dot"></span><span class="workspace">' + esc(r.workspace || 'workspace') + '</span></div>';
    if (r.detail) {
      html += '<div class="detail">' + esc(r.detail) + '</div>';
    }
    html += '</div>';
    if (r.label) {
      html += '<span class="chip ' + r.status + '">' + esc(r.label) + '</span>';
    }
    var frozen = _frozenElapsed[ids[i]];
    var elapsed = frozen || (_startTimes[ids[i]] ? fmtElapsed(Date.now() - _startTimes[ids[i]]) : '');
    html += '<span id="elapsed-' + ids[i] + '" class="elapsed' + (frozen ? ' frozen' : '') + '">' + elapsed + '</span>';
    html += '</div>';
  }
  pill.innerHTML = html;
  paintCats();
}
</script>
</body>
</html>`;
}

const previousStatus = new Map();
const stickyDone = new Map();
let demoUntil = 0;
let win = null;
let winReady = false;
let pending = [];
let idleTimer = null;
let failCount = 0;
let cleanedUp = false;

function push(js) {
  if (winReady && win) {
    win.send(js);
  } else {
    pending.push(js);
  }
}

function decorate(row) {
  return {
    id: row.id,
    agent: row.agent,
    workspace: row.workspace,
    status: row.status,
    label: STATUS_LABEL[row.status] || "",
    color: STATUS_COLOR[row.status] || "#6B7280",
    detail: row.status === "blocked" ? row.detail || "" : "",
  };
}

function cap(rows) {
  const blocked = rows.filter((row) => row.status === "blocked");
  const rest = rows.filter((row) => row.status !== "blocked");
  if (blocked.length >= MAX_ROWS) {
    return blocked.slice(0, MAX_ROWS);
  }
  return blocked.concat(rest.slice(0, MAX_ROWS - blocked.length));
}

function mergeLive(rows) {
  const now = Date.now();
  const visible = [];
  const liveIds = new Set();

  for (const row of rows) {
    liveIds.add(row.id);
    const prev = previousStatus.get(row.id);
    previousStatus.set(row.id, row.status);
    if (row.status === "working" || row.status === "blocked") {
      stickyDone.delete(row.id);
      visible.push(row);
      continue;
    }
    if (row.status === "done" && (prev === "working" || prev === "blocked")) {
      stickyDone.set(row.id, { row, until: now + DONE_HOLD_MS });
    }
  }

  for (const [id, status] of previousStatus) {
    if (!liveIds.has(id) && status !== "done") {
      previousStatus.delete(id);
    }
  }

  for (const [id, sticky] of stickyDone) {
    if (now > sticky.until) {
      stickyDone.delete(id);
      continue;
    }
    if (!visible.some((row) => row.id === id)) {
      visible.push({ ...sticky.row, status: "done" });
    }
  }

  return cap(visible);
}

function resetIdle(hasRows) {
  if (idleTimer) {
    clearTimeout(idleTimer);
    idleTimer = null;
  }
  if (hasRows || Date.now() < demoUntil) {
    return;
  }
  idleTimer = setTimeout(() => {
    cleanup();
    process.exit(0);
  }, IDLE_EXIT_MS);
}

function renderRows(rows) {
  const decorated = rows.map(decorate);
  push(`sync(${JSON.stringify(decorated)})`);
  resetIdle(decorated.length > 0);
}

function poll() {
  if (Date.now() < demoUntil) {
    return;
  }
  const snapshot = buildSnapshot();
  if (!snapshot.ok) {
    failCount += 1;
    if (failCount >= 6) {
      cleanup();
      process.exit(0);
    }
    return;
  }
  failCount = 0;
  renderRows(mergeLive(snapshot.rows));
}

function handleMessage(msg) {
  if (!msg || typeof msg !== "object") {
    return;
  }
  if (msg.type === "quit") {
    cleanup();
    process.exit(0);
  }
  if (msg.type === "demo") {
    demoUntil = Date.now() + 30000;
    previousStatus.clear();
    stickyDone.clear();
    renderRows(DEMO_ROWS);
    return;
  }
  if (msg.type === "ping" || msg.type === "refresh") {
    if (Date.now() < demoUntil) {
      renderRows(DEMO_ROWS);
      return;
    }
    poll();
  }
}

if (!usesNamedPipe(SOCK)) {
  try {
    unlinkSync(SOCK);
  } catch {
    // nothing stale
  }
}

const server = createServer((socket) => {
  const rl = createInterface({ input: socket, crlfDelay: Infinity });
  rl.on("line", (line) => {
    try {
      handleMessage(JSON.parse(line));
    } catch {
      // ignore malformed
    }
  });
  socket.on("error", () => {});
});

server.on("error", (error) => {
  if (error.code === "EADDRINUSE") {
    process.exit(0);
  }
  process.exit(1);
});

server.listen(SOCK, () => {
  try {
    writeFileSync(pidFilePath(), `${process.pid}\n`);
  } catch {
    // overlay still works without a pid file
  }
});

const followCursor = supportsFollowCursor();
win = open(buildHTML(), {
  width: 760,
  height: 240,
  frameless: true,
  floating: true,
  transparent: true,
  clickThrough: true,
  noDock: true,
  followCursor,
  followMode: "spring",
  cursorAnchor: "top-right",
});

win.on("ready", () => {
  winReady = true;
  for (const js of pending) {
    win.send(js);
  }
  pending = [];
  poll();
});

win.on("closed", () => {
  cleanup();
  process.exit(0);
});
win.on("error", () => {});

setInterval(poll, POLL_MS);

function cleanup() {
  if (cleanedUp) {
    return;
  }
  cleanedUp = true;
  try {
    server.close();
  } catch {
    // already closed
  }
  if (!usesNamedPipe(SOCK)) {
    try {
      unlinkSync(SOCK);
    } catch {
      // missing
    }
  }
  try {
    unlinkSync(pidFilePath());
  } catch {
    // missing
  }
  if (win) {
    try {
      win.close();
    } catch {
      // already closed
    }
  }
}

process.on("SIGTERM", () => {
  cleanup();
  process.exit(0);
});
process.on("SIGINT", () => {
  cleanup();
  process.exit(0);
});
process.on("exit", cleanup);
