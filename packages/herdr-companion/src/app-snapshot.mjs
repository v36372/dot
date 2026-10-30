import { spawnSync } from "node:child_process";
import { extractBrief, isPromptingUser } from "./extract-brief.mjs";

export function snapshotFromSpaces(spaces, readTerminal) {
  const rows = [];
  function visit(terminal, workspace, machine) {
    const address = terminal.terminal;
    const status = terminal.status;
    if (address && ["working", "blocked", "done"].includes(status)) {
      const text = status === "done" ? "" : readTerminal(address, machine);
      const blocked = status === "blocked" || (status === "working" && isPromptingUser(text));
      rows.push({
        id: `${machine || "local"}:${address}`,
        agent: terminal.name || terminal.app || "agent",
        workspace,
        status: blocked ? "blocked" : status,
        detail: blocked ? extractBrief({ agent: terminal.app, text, title: "", stateLabels: {}, tokens: {} }) || "" : "",
        seq: 0,
      });
    }
    for (const child of terminal.sub_agents || []) visit(child, workspace, machine);
  }
  for (const space of spaces) for (const tab of space.tabs || []) {
    for (const terminal of tab.terminals || []) visit(terminal, space.name, space.machine);
  }
  const rank = { blocked: 0, working: 1, done: 2 };
  rows.sort((a, b) => rank[a.status] - rank[b.status]);
  return { ok: true, rows };
}

// The app CLI is polled once per second; switch to app events if it exposes them.
export function buildAppSnapshot() {
  const result = spawnSync("herdr-app", ["ls"], { encoding: "utf8", timeout: 3000, maxBuffer: 2_000_000 });
  if (result.status !== 0) return { ok: false, rows: [] };
  try {
    const { spaces } = JSON.parse(result.stdout);
    if (!Array.isArray(spaces)) return { ok: false, rows: [] };
    return snapshotFromSpaces(spaces, (address, machine) => {
      const target = machine && !address.includes("/") ? `${machine}/${address}` : address;
      const read = spawnSync("hc", ["read", target, "--lines", "50"], { encoding: "utf8", timeout: 3000, maxBuffer: 2_000_000 });
      return read.status === 0 ? read.stdout : "";
    });
  } catch {
    return { ok: false, rows: [] };
  }
}
