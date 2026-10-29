import { join } from "node:path";
import { pluginStateDir } from "./paths.mjs";

export function getCompanionSocketPath() {
  if (process.platform === "win32") {
    return "\\\\.\\pipe\\herdr-companion";
  }
  return join(pluginStateDir(), "companion.sock");
}

export function usesNamedPipe(socketPath) {
  return socketPath.startsWith("\\\\.\\pipe\\");
}
