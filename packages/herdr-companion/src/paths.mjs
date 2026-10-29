import { mkdirSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const PLUGIN_ID = "local.companion";

export function pluginRoot() {
  return process.env.HERDR_PLUGIN_ROOT || join(dirname(fileURLToPath(import.meta.url)), "..");
}

export function pluginConfigDir() {
  return (
    process.env.HERDR_PLUGIN_CONFIG_DIR ||
    join(homedir(), ".config", "herdr", "plugins", "config", PLUGIN_ID)
  );
}

export function pluginStateDir() {
  const dir =
    process.env.HERDR_PLUGIN_STATE_DIR ||
    join(process.env.XDG_STATE_HOME || join(homedir(), ".local", "state"), "herdr", "plugins", PLUGIN_ID);
  mkdirSync(dir, { recursive: true });
  return dir;
}

export function disabledMarkerPath() {
  return join(pluginConfigDir(), "disabled");
}

export function pidFilePath() {
  return join(pluginStateDir(), "companion.pid");
}
