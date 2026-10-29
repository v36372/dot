import assert from "node:assert/strict";
import test from "node:test";
import { extractBrief, isPromptingUser } from "./extract-brief.mjs";

test("prefers state_labels.blocked over screen text", () => {
  const brief = extractBrief({
    agent: "pi",
    text: "Working...",
    stateLabels: { blocked: "Switch to the review worktree?" },
  });
  assert.equal(brief, "Switch to the review worktree?");
});

test("ignores generic needs-you labels", () => {
  const brief = extractBrief({
    agent: "pi",
    text: `
────────
Which database should we use?
  PostgreSQL
  SQLite
────────
`,
    stateLabels: { blocked: "needs your input" },
  });
  assert.equal(brief, "Which database should we use?");
});

test("claude bash permission includes the command", () => {
  const brief = extractBrief({
    agent: "claude",
    text: `
 Bash command

 git push origin main --force

 Do you want to proceed?
 ❯ 1. Yes
   2. Yes, and don't ask again for git push
   3. No

 esc to cancel
`,
  });
  assert.equal(brief, "Approve git push origin main --force");
});

test("claude MCP elicitation uses the server line", () => {
  const brief = extractBrief({
    agent: "claude",
    text: `
 MCP server "linear" requests your input
 ❯ Accept
   Decline
 esc to cancel
`,
  });
  assert.match(brief, /linear/i);
});

test("codex allow-command includes the command", () => {
  const brief = extractBrief({
    agent: "codex",
    text: `
 rm -rf build

 allow command?
 press enter to confirm or esc to cancel
`,
  });
  assert.equal(brief, "Approve rm -rf build");
});

test("cursor write-file includes the path", () => {
  const brief = extractBrief({
    agent: "cursor",
    text: `
 src/auth.ts
 write to this file?
 proceed (y)
 reject & propose changes
`,
  });
  assert.equal(brief, "Write src/auth.ts?");
});

test("grok option dialog uses the heading", () => {
  const brief = extractBrief({
    agent: "grok",
    text: `
◆ Allow editing package.json?
┃  1 (○) Yes, proceed
┃  2 (○) No, reject
 Esc:unselect │ Tab:scrollback │ Shift+x:dismiss
`,
  });
  assert.equal(brief, "Allow editing package.json?");
});

test("pi ask_user_question uses the question text", () => {
  const brief = extractBrief({
    agent: "pi",
    text: `
────────────────────────────────────────
 Which approach should we take for auth?
   Rewrite the parser
   Patch in place
   Type your own answer...
────────────────────────────────────────
`,
  });
  assert.equal(brief, "Which approach should we take for auth?");
});

test("pi multiple questions include a count", () => {
  const brief = extractBrief({
    agent: "pi",
    text: `
 Database?
 Postgres
 SQLite
 Region?
 us-east
 eu-west
`,
  });
  assert.equal(brief, "2 questions · Database?");
});

test("antigravity trust prompt", () => {
  const brief = extractBrief({
    agent: "agy",
    text: `
 Do you trust the contents of this project?
 Yes, I trust this folder
 ↑/↓ Navigate · enter Confirm
`,
  });
  assert.match(brief, /trust the contents of this project/i);
});

test("pi ask_user_question dialog is prompting even while herdr says working", () => {
  const text = `
 Evaluating user options

 The user has two choices: they can choose between a strict approach and a context-driven one.

 ask user Scope

 Should identity/IAM coverage retain endpoint posture and person-to-device context?

>   1. Identity/IAM + device context
     Keep users, groups, memberships, permissions, MFA.
    2. Strict identity/IAM only
     Keep users, groups, memberships, permissions, and MFA.
    3. Type your own answer...

 ↑↓ navigate · Enter select · Esc cancel
`;
  assert.equal(isPromptingUser(text), true);
  assert.equal(
    extractBrief({ agent: "pi", text }),
    "Should identity/IAM coverage retain endpoint posture and person-to-device context?",
  );
});

test("ordinary working output is not a prompt", () => {
  assert.equal(
    isPromptingUser(`
 Reading src/snapshot.mjs
 Running npm test
`),
    false,
  );
});

test("falls back to a useful title and skips chrome titles", () => {
  assert.equal(
    extractBrief({ agent: "grok", text: "", title: "⚠ Action Required: allow network" }),
    "allow network",
  );
  assert.equal(extractBrief({ agent: "pi", text: "", title: "π - sm" }), "");
});
