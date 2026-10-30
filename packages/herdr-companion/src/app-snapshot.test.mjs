import { test } from "node:test";
import assert from "node:assert/strict";
import { snapshotFromSpaces } from "./app-snapshot.mjs";

test("maps app agents, including subagents and remote addresses", () => {
  const calls = [];
  const result = snapshotFromSpaces([{ name: "project", machine: "remote", tabs: [{ terminals: [
    { terminal: "remote/t1", app: "pi", status: "working", sub_agents: [{ terminal: "remote/t2", app: "codex", status: "blocked" }] },
    { terminal: "remote/t3", status: "idle" },
  ] }] }], (address, machine) => { calls.push([address, machine]); return ""; });
  assert.deepEqual(result.rows.map(({ id, status }) => [id, status]), [["remote:remote/t2", "blocked"], ["remote:remote/t1", "working"]]);
  assert.equal(calls.length, 2);
});
