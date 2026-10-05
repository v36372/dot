import { realpathSync } from "node:fs";
import { pathToFileURL } from "node:url";
import { createWebFetchTool } from "./webfetch.ts";
import { createWebSearchTool } from "./websearch.ts";

type Tool = { execute: (id: string, params: unknown) => Promise<{ content: Array<{ type: string; text?: string }> }> };

export async function runCli(
	args: string[],
	tools: { search: Tool; fetch: Tool } = { search: createWebSearchTool(), fetch: createWebFetchTool() },
): Promise<string> {
	const [command, value, option, extra, ...rest] = args;
	if (!value || rest.length || (command !== "search" && command !== "fetch")) {
		throw new Error('Usage: cli.ts search "query" [maxResults] [auto|fast|deep] | fetch "url" [markdown|text|html] [timeoutSeconds]');
	}
	const params = command === "search"
		? { query: value, ...(option === undefined ? {} : { maxResults: Number(option) }), ...(extra === undefined ? {} : { depth: extra }) }
		: { url: value, ...(option === undefined ? {} : { format: option }), ...(extra === undefined ? {} : { timeout: Number(extra) }) };
	const result = await tools[command].execute("cli", params);
	// Image bytes are not useful as shell text; the tool's first content part gives the source URL.
	return result.content.filter((part) => part.type === "text").map((part) => part.text ?? "").join("\n");
}

if (process.argv[1] && import.meta.url === pathToFileURL(realpathSync(process.argv[1])).href) {
	runCli(process.argv.slice(2)).then(
		(output) => process.stdout.write(`${output}\n`),
		(error: unknown) => {
			process.stderr.write(`${error instanceof Error ? error.message : "Web request failed"}\n`);
			process.exitCode = 1;
		},
	);
}
