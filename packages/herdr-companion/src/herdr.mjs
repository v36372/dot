import { spawnSync } from "node:child_process";

export function herdrBin() {
  return process.env.HERDR_BIN_PATH || "herdr";
}

export function herdrJson(args, timeoutMs = 3000) {
  const result = spawnSync(herdrBin(), args, {
    encoding: "utf8",
    timeout: timeoutMs,
    maxBuffer: 2_000_000,
    env: process.env,
  });
  if (result.status !== 0 || !result.stdout) {
    return null;
  }
  try {
    return JSON.parse(result.stdout);
  } catch {
    return null;
  }
}

export function herdrText(args, timeoutMs = 3000) {
  const result = spawnSync(herdrBin(), args, {
    encoding: "utf8",
    timeout: timeoutMs,
    maxBuffer: 2_000_000,
    env: process.env,
  });
  if (result.status !== 0) {
    return "";
  }
  return result.stdout ?? "";
}

export function listAgents() {
  return herdrJson(["agent", "list"])?.result?.agents ?? null;
}

export function listWorkspaces() {
  return herdrJson(["workspace", "list"])?.result?.workspaces ?? null;
}

export function readPane(paneId) {
  const detection = herdrText(["pane", "read", paneId, "--source", "detection"]).trim();
  if (detection) {
    return detection;
  }
  const visible = herdrText(["pane", "read", paneId, "--source", "visible"]).trim();
  if (visible) {
    return visible;
  }
  return herdrText([
    "pane",
    "read",
    paneId,
    "--source",
    "recent-unwrapped",
    "--lines",
    "50",
  ]).trim();
}
