import { spawn } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, unlinkSync, writeFileSync } from "node:fs";
import { connect } from "node:net";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { disabledMarkerPath, pidFilePath, pluginConfigDir, pluginRoot, pluginStateDir } from "./paths.mjs";
import { getCompanionSocketPath } from "./socket-path.mjs";
import { buildSnapshot } from "./snapshot.mjs";

const ROOT = pluginRoot();
const COMPANION = join(dirname(fileURLToPath(import.meta.url)), "companion.mjs");
const SOCK = getCompanionSocketPath();

function send(payload, timeoutMs = 400) {
  return new Promise((resolve) => {
    const socket = connect(SOCK);
    let done = false;
    const finish = (ok) => {
      if (done) {
        return;
      }
      done = true;
      clearTimeout(timer);
      socket.destroy();
      resolve(ok);
    };
    const timer = setTimeout(() => finish(false), timeoutMs);
    socket.on("connect", () => {
      socket.write(`${JSON.stringify(payload)}\n`, () => finish(true));
    });
    socket.on("error", () => finish(false));
  });
}

function pidAlive(pid) {
  if (!pid) {
    return false;
  }
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

function runningPid() {
  try {
    const pid = Number(readFileSync(pidFilePath(), "utf8"));
    return pidAlive(pid) ? pid : 0;
  } catch {
    return 0;
  }
}

function isDisabled() {
  return existsSync(disabledMarkerPath());
}

function setDisabled(disabled) {
  mkdirSync(pluginConfigDir(), { recursive: true });
  if (disabled) {
    writeFileSync(disabledMarkerPath(), "1\n");
    return;
  }
  try {
    unlinkSync(disabledMarkerPath());
  } catch {
    // already enabled
  }
}

async function stopCompanion() {
  const pid = runningPid();
  if (pid) {
    try {
      process.kill(pid, "SIGTERM");
    } catch {
      // gone
    }
  }
  await send({ type: "quit" }, 200);
  try {
    unlinkSync(pidFilePath());
  } catch {
    // missing
  }
}

function spawnCompanion() {
  const child = spawn(process.execPath, [COMPANION], {
    cwd: ROOT,
    detached: true,
    stdio: "ignore",
    windowsHide: process.platform === "win32",
    env: {
      ...process.env,
      HERDR_PLUGIN_ROOT: ROOT,
      HERDR_PLUGIN_CONFIG_DIR: process.env.HERDR_PLUGIN_CONFIG_DIR || pluginConfigDir(),
      HERDR_PLUGIN_STATE_DIR: process.env.HERDR_PLUGIN_STATE_DIR || pluginStateDir(),
      HERDR_BIN_PATH: process.env.HERDR_BIN_PATH,
      HERDR_SOCKET_PATH: process.env.HERDR_SOCKET_PATH,
    },
  });
  child.unref();
}

async function ensureCompanion() {
  if (await send({ type: "ping" })) {
    return true;
  }
  if (runningPid()) {
    for (let i = 0; i < 10; i += 1) {
      await new Promise((r) => setTimeout(r, 80));
      if (await send({ type: "ping" })) {
        return true;
      }
    }
  }
  spawnCompanion();
  for (let i = 0; i < 25; i += 1) {
    await new Promise((r) => setTimeout(r, 100));
    if (await send({ type: "ping" })) {
      return true;
    }
  }
  return false;
}

function hasLiveAgents() {
  const snapshot = buildSnapshot();
  return (snapshot.rows || []).some((row) => row.status === "working" || row.status === "blocked");
}

async function refresh(kind = "refresh") {
  if (isDisabled()) {
    return;
  }
  const force = kind === "demo" || kind === "start";
  if (!force && !runningPid() && !hasLiveAgents()) {
    return;
  }
  const ok = await ensureCompanion();
  if (!ok) {
    console.error("companion: failed to start overlay");
    return;
  }
  if (kind === "demo") {
    await send({ type: "demo" });
    return;
  }
  await send({ type: "refresh" });
}

const command = process.argv[2] || "refresh";

if (command === "stop") {
  setDisabled(true);
  await stopCompanion();
} else if (command === "start") {
  setDisabled(false);
  await refresh("start");
} else if (command === "toggle") {
  if (isDisabled() || !runningPid()) {
    setDisabled(false);
    await refresh("start");
  } else {
    setDisabled(true);
    await stopCompanion();
  }
} else if (command === "demo") {
  setDisabled(false);
  await refresh("demo");
} else {
  await refresh("refresh");
}
