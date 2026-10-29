import { extractBrief, isGenericNeed, isPromptingUser } from "./extract-brief.mjs";
import { listAgents, listWorkspaces, readPane } from "./herdr.mjs";

const VISIBLE_STATUSES = new Set(["working", "blocked", "done"]);

export function agentDisplayName(agent) {
  const named = String(agent?.name || agent?.display_agent || agent?.agent || "agent").trim();
  return named || "agent";
}

export function workspaceDisplayName(agent, workspaces) {
  const match = workspaces.find((workspace) => workspace.workspace_id === agent.workspace_id);
  const label = String(match?.label || agent.workspace_id || "workspace").trim();
  return label || "workspace";
}

function blockedDetail(agent) {
  const labeled = extractBrief({
    agent: agent.agent,
    text: "",
    title: agent.title || agent.terminal_title_stripped || "",
    stateLabels: agent.state_labels || {},
    tokens: agent.tokens || {},
  });
  if (labeled) {
    return labeled;
  }

  const text = readPane(agent.pane_id);
  const brief = extractBrief({
    agent: agent.agent,
    text,
    title: agent.title || agent.terminal_title_stripped || "",
    stateLabels: agent.state_labels || {},
    tokens: agent.tokens || {},
  });
  if (brief && !isGenericNeed(brief)) {
    return brief;
  }
  return brief || "";
}

export function buildSnapshot() {
  const agents = listAgents();
  const workspaces = listWorkspaces();
  if (!agents || !workspaces) {
    return { ok: false, rows: [] };
  }

  const rows = [];
  for (const agent of agents) {
    const status = agent.agent_status;
    if (!VISIBLE_STATUSES.has(status)) {
      continue;
    }
    const row = {
      id: agent.pane_id,
      paneId: agent.pane_id,
      agent: agentDisplayName(agent),
      workspace: workspaceDisplayName(agent, workspaces),
      status,
      detail: "",
      seq: agent.state_change_seq ?? 0,
    };
    if (status === "blocked") {
      row.detail = blockedDetail(agent);
    } else if (status === "working") {
      const text = readPane(agent.pane_id);
      if (isPromptingUser(text)) {
        row.status = "blocked";
        row.detail =
          extractBrief({
            agent: agent.agent,
            text,
            title: agent.title || agent.terminal_title_stripped || "",
            stateLabels: agent.state_labels || {},
            tokens: agent.tokens || {},
          }) || "";
      }
    }
    rows.push(row);
  }

  rows.sort((a, b) => {
    const rank = { blocked: 0, working: 1, done: 2 };
    return (rank[a.status] ?? 9) - (rank[b.status] ?? 9) || (b.seq || 0) - (a.seq || 0);
  });

  return { ok: true, rows };
}

export const DEMO_ROWS = [
  {
    id: "demo-working",
    paneId: "demo-working",
    agent: "pi",
    workspace: "assets",
    status: "working",
    detail: "",
    seq: 2,
  },
  {
    id: "demo-blocked",
    paneId: "demo-blocked",
    agent: "claude",
    workspace: "iam",
    status: "blocked",
    detail: "Approve git push origin main --force",
    seq: 1,
  },
];
