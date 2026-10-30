const MAX_BRIEF = 120;

const GENERIC_NEED = /^(needs you|needs your input|action required|blocked|waiting|waiting for (you|input|approval|permission)|needs approval)$/i;

const GENERIC_QUESTION =
  /^(do you want to proceed\??|do you want to continue\??|allow (this|command)\??|run this command\??|write to this file\??|waiting for approval\??|waiting for permission\??|approve this (action|command)\??)$/i;

const SEPARATOR = /^[─━═\-_]{3,}$/;

const OPTION_LINE =
  /^\s*(?:[❯▶→◆●○]\s*)?(?:\d+[.)]\s+|\([yn]\)\s*|[a-z]\s+\([●○]\)\s+|┃\s+)/i;

const YES_NO_OPTION =
  /^\s*(?:[❯▶→◆]\s*)?(?:\d+[.)]\s+)?(?:yes|no)\b/i;

const CHROME = [
  SEPARATOR,
  OPTION_LINE,
  YES_NO_OPTION,
  /don't ask again/i,
  /^type your (own )?answer/i,
  /esc to (cancel|close|skip|unselect)/i,
  /enter to (confirm|select|submit|continue|set as default)/i,
  /(?:tab\/arrow|arrow keys|arrows|↑\/↓|↑↓) to navigate/i,
  /tab to amend/i,
  /ctrl\+[a-z0-9]/i,
  /^\? for shortcuts/i,
  /press enter to confirm or esc to cancel/i,
  /shift\+x:dismiss/i,
  /tab:scrollback/i,
  /ctrl\+o:yolo/i,
  /ctrl\+c:cancel/i,
  /ctrl\+\.:shortcuts/i,
  /^skip \(esc or n\)/i,
  /^keep \(n\)/i,
  /^proceed \(y\)/i,
  /^run \(once\) \(y\)/i,
  /^\s*\[y\/n\]\s*$/i,
  /^\s*yes \(y\)\s*$/i,
  /^[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏◐◓◑◒]\s/u,
  /^── .+ ─+$/,
  /esc to interrupt/i,
  /^\s*\/btw\b/i,
  /^\s*✓ submit\s*$/i,
];

export function oneLine(value, max = MAX_BRIEF) {
  const text = String(value ?? "")
    .replace(/\s+/g, " ")
    .trim();
  if (!text) {
    return "";
  }
  if (text.length <= max) {
    return text;
  }
  return `${text.slice(0, max - 1)}…`;
}

export function isGenericNeed(text) {
  return GENERIC_NEED.test(oneLine(text, 80));
}

const PROMPT_TAIL = 45;

// Pi's herdr hook keeps status at "working" while ask_user_question is up
// (screen detection is skipped). Detect the live prompt chrome instead.
export function isPromptingUser(text) {
  const lines = normalizeLines(text);
  if (lines.length === 0) {
    return false;
  }
  const tail = lines.slice(-PROMPT_TAIL).join("\n");
  if (/type your own answer/i.test(tail)) {
    return true;
  }
  if (/enter select/i.test(tail) && /esc cancel/i.test(tail)) {
    return true;
  }
  if (/↑↓\s*navigate/i.test(tail) && /^\s*>?\s*\d+[.)]/m.test(tail)) {
    return true;
  }
  if (/do you want to proceed\?/i.test(tail)) {
    return true;
  }
  if (/waiting for (permission|approval)/i.test(tail)) {
    return true;
  }
  if (/allow command\?/i.test(tail) || /write to this file\?/i.test(tail)) {
    return true;
  }
  if (/mcp server .+ requests your input/i.test(tail)) {
    return true;
  }
  if (/do you trust the contents of this (project|folder|directory)\?/i.test(tail)) {
    return true;
  }
  return false;
}

function isChrome(line) {
  const text = line.trim();
  if (!text) {
    return true;
  }
  return CHROME.some((re) => re.test(text));
}

function isOption(line) {
  const text = line.trim();
  return OPTION_LINE.test(text) || YES_NO_OPTION.test(text) || /don't ask again/i.test(text);
}

function isSeparator(line) {
  return SEPARATOR.test(line.trim());
}

export function normalizeLines(text) {
  const lines = String(text ?? "")
    .replace(/\r\n/g, "\n")
    .replace(/\u00a0/g, " ")
    .split("\n")
    .map((line) => line.replace(/\x1b\[[0-9;]*[A-Za-z]/g, "").trim());
  const out = [];
  for (const line of lines) {
    if (!line || line === out[out.length - 1]) {
      continue;
    }
    out.push(line);
  }
  return out;
}

function lastContentBefore(lines, index) {
  for (let i = index - 1; i >= 0; i -= 1) {
    const line = lines[i];
    if (!isChrome(line) && !isOption(line) && !isSeparator(line)) {
      return line;
    }
  }
  return "";
}

function firstQuestion(lines) {
  for (const line of lines) {
    if (line.includes("?") && !isChrome(line) && !isOption(line)) {
      return line.replace(/^[◆●○▶❯→]\s*/, "").trim();
    }
  }
  return "";
}

function looksLikeCommand(line) {
  const text = line.trim();
  if (!text || text.length > 200) {
    return false;
  }
  if (text.includes("?")) {
    return false;
  }
  if (/^(bash command|bash\(|command|allow|approve|permission)\b/i.test(text)) {
    return false;
  }
  return (
    /^(git|npm|pnpm|yarn|bun|cargo|go|python|python3|pip|uv|make|just|docker|kubectl|rg|fd|ls|cd|rm|mv|cp|cat|curl|ssh|heroku|gh)\b/.test(
      text,
    ) ||
    /^[a-z0-9._/-]+\s+-{1,2}[a-z]/.test(text) ||
    /^[./]/.test(text)
  );
}

function looksLikePath(line) {
  return /^(?:~|\.|\/|[A-Za-z]:\\|[A-Za-z0-9._-]+\/)[\w./\\-]+$/.test(line.trim());
}

function optionIndex(lines) {
  return lines.findIndex((line) => isOption(line));
}

function attachSubject(question, subject) {
  const q = oneLine(question, 80);
  const s = oneLine(subject, 80);
  if (!q) {
    return s;
  }
  if (!s || q.toLowerCase().includes(s.toLowerCase())) {
    return q.endsWith("?") || q.length > 24 ? q : q;
  }
  if (GENERIC_QUESTION.test(q.replace(/[.]+$/, ""))) {
    if (looksLikeCommand(s) || looksLikePath(s)) {
      return oneLine(`Approve ${s}`);
    }
    return oneLine(`${q.replace(/\?$/, "")}: ${s}`);
  }
  return q;
}

function fromLabels(stateLabels, tokens) {
  const candidates = [
    stateLabels?.blocked,
    tokens?.brief,
    tokens?.question,
    tokens?.summary,
    tokens?.request,
    tokens?.message,
  ];
  for (const value of candidates) {
    const text = oneLine(value);
    if (text && !isGenericNeed(text)) {
      return text;
    }
  }
  return "";
}

function titleBrief(title) {
  const text = oneLine(title);
  if (!text || isGenericNeed(text)) {
    return "";
  }
  if (/action required/i.test(text)) {
    const rest = text.replace(/^[⚠\s]*action required[:\s-]*/i, "").trim();
    if (rest && !isGenericNeed(rest) && rest.toLowerCase() !== "action required") {
      return oneLine(rest);
    }
    return "";
  }
  // Terminal titles like "π - sm" are not requests.
  if (/^(π|pi|claude|codex|grok|cursor|omp)\b/i.test(text) && !text.includes("?")) {
    return "";
  }
  if (text.includes("?") || /approv|allow|permission|trust|confirm/i.test(text)) {
    return text;
  }
  return "";
}

function claudeBrief(lines) {
  const mcp = lines.find((line) => /mcp server .+ requests your input/i.test(line));
  if (mcp) {
    return oneLine(mcp.replace(/^\s*/, ""));
  }
  const workflow = lines.find((line) => /run a dynamic workflow\?/i.test(line));
  if (workflow) {
    return oneLine(workflow);
  }
  const proceed = lines.findIndex((line) => /do you want to proceed\?/i.test(line));
  if (proceed >= 0) {
    const subject = lastContentBefore(lines, proceed);
    if (subject && !/^(bash command|bash\()/i.test(subject)) {
      return attachSubject("Do you want to proceed?", subject);
    }
    const bash = lines.find((line) => /^bash command$/i.test(line) || /^bash\(/i.test(line));
    if (bash) {
      return "Approve bash command";
    }
    return "Approve this action";
  }
  const allow = lines.find((line) => /do you want to allow this connection\?/i.test(line));
  if (allow) {
    return oneLine(allow);
  }
  const waiting = lines.find((line) => /waiting for permission/i.test(line));
  if (waiting) {
    const subject = lastContentBefore(lines, lines.indexOf(waiting));
    return attachSubject("Waiting for permission", subject);
  }
  return "";
}

function codexBrief(lines) {
  const allow = lines.findIndex((line) => /allow command\?/i.test(line));
  if (allow >= 0) {
    const subject = lastContentBefore(lines, allow) || lines[allow + 1];
    if (subject && !isChrome(subject) && !isOption(subject)) {
      return attachSubject("Allow command?", subject);
    }
    return "Allow command?";
  }
  const trust = lines.find((line) => /trust (the contents of )?this (directory|folder)\?/i.test(line));
  if (trust) {
    return oneLine(trust);
  }
  const update = lines.find((line) => /update available/i.test(line));
  if (update) {
    return "Codex update available";
  }
  return "";
}

function cursorBrief(lines) {
  const write = lines.findIndex((line) => /write to this file\?/i.test(line));
  if (write >= 0) {
    const subject =
      lastContentBefore(lines, write) ||
      lines.slice(write + 1).find((line) => looksLikePath(line) || /\.\w{1,8}$/.test(line));
    if (subject) {
      return oneLine(`Write ${subject}?`);
    }
    return "Write to this file?";
  }
  const run = lines.findIndex((line) => /run this command\?/i.test(line) || /waiting for approval/i.test(line));
  if (run >= 0) {
    const subject = lastContentBefore(lines, run) || lines.slice(run + 1).find((line) => looksLikeCommand(line));
    if (subject) {
      return attachSubject("Run this command?", subject);
    }
    return "Approve this command";
  }
  return "";
}

function grokBrief(lines) {
  const heading = lines.find((line) => /^[◆●]\s+\S/.test(line) || /^allow /i.test(line));
  if (heading) {
    return oneLine(heading.replace(/^[◆●]\s*/, ""));
  }
  return "";
}

function agyBrief(lines) {
  const trust = lines.find((line) => /do you trust the contents of this project\?/i.test(line));
  if (trust) {
    return oneLine(trust);
  }
  const perm = lines.find((line) => /requesting permission for:/i.test(line));
  if (perm) {
    const idx = lines.indexOf(perm);
    const subject = lines[idx + 1] || lastContentBefore(lines, idx);
    return attachSubject("Permission requested", subject);
  }
  return "";
}

function piBrief(lines) {
  // ask_user_question: question body sits between horizontal rules.
  const questions = lines.filter(
    (line) =>
      line.includes("?") &&
      !isChrome(line) &&
      !isOption(line) &&
      !/shortcuts/i.test(line),
  );
  if (questions.length === 1) {
    return oneLine(questions[0]);
  }
  if (questions.length > 1) {
    return oneLine(`${questions.length} questions · ${questions[0]}`);
  }
  return "";
}

function genericBrief(lines) {
  const opts = optionIndex(lines);
  if (opts > 0) {
    const subject = lastContentBefore(lines, opts);
    const question = firstQuestion(lines.slice(0, opts + 1)) || subject;
    if (question) {
      if (GENERIC_QUESTION.test(question) && subject && subject !== question) {
        return attachSubject(question, subject);
      }
      return oneLine(question);
    }
  }

  const question = firstQuestion(lines);
  if (question) {
    const idx = lines.findIndex((line) => line.includes("?") && oneLine(line).includes(question.slice(0, 24)));
    const subject = idx > 0 ? lastContentBefore(lines, idx) : "";
    return attachSubject(question, subject);
  }

  const approve = lines.find((line) => /approv|allow |permission|trust this/i.test(line) && !isChrome(line));
  if (approve) {
    return oneLine(approve);
  }

  return "";
}

export function extractBrief({
  agent = "",
  text = "",
  title = "",
  stateLabels = {},
  tokens = {},
} = {}) {
  const labeled = fromLabels(stateLabels, tokens);
  if (labeled) {
    return labeled;
  }

  const lines = normalizeLines(text);
  const kind = String(agent || "").toLowerCase();

  const specific =
    (kind.includes("claude") && claudeBrief(lines)) ||
    (kind.includes("codex") && codexBrief(lines)) ||
    (kind.includes("cursor") && cursorBrief(lines)) ||
    (kind.includes("grok") && grokBrief(lines)) ||
    ((kind.includes("agy") || kind.includes("antigravity")) && agyBrief(lines)) ||
    ((kind === "pi" || kind === "omp") && piBrief(lines)) ||
    "";

  if (specific) {
    return specific;
  }

  const generic = genericBrief(lines);
  if (generic) {
    return generic;
  }

  return titleBrief(title);
}
