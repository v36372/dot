import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, rmdirSync, symlinkSync, unlinkSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { runCli } from "../cli.ts";

test("CLI runs when invoked through an installed symlink", () => {
	const directory = mkdtempSync(join(tmpdir(), "web-search-cli-"));
	const link = join(directory, "cli.ts");
	try {
		const skillDirectory = fileURLToPath(new URL("../", import.meta.url));
		symlinkSync(join(skillDirectory, "cli.ts"), link);
		const result = spawnSync(process.execPath, ["--import", "tsx", link], { cwd: skillDirectory, encoding: "utf8" });
		assert.equal(result.status, 1);
		assert.match(result.stderr, /^Usage: cli\.ts search/);
	} finally {
		unlinkSync(link);
		rmdirSync(directory);
	}
});

test("CLI routes searches and fetches and prints text instead of image bytes", async () => {
	const calls: Array<{ tool: string; params: unknown }> = [];
	const tools = {
		search: { async execute(_id: string, params: unknown) {
			calls.push({ tool: "search", params });
			return { content: [{ type: "text", text: "URL: https://example.com" }] };
		} },
		fetch: { async execute(_id: string, params: unknown) {
			calls.push({ tool: "fetch", params });
			return { content: [{ type: "text", text: "Fetched image from https://example.com/a.png" }, { type: "image", data: "secret" }] };
		} },
	};
	assert.equal(await runCli(["search", "example", "12", "fast"], tools), "URL: https://example.com");
	assert.equal(await runCli(["fetch", "https://example.com/a.png"], tools), "Fetched image from https://example.com/a.png");
	assert.deepEqual(calls, [
		{ tool: "search", params: { query: "example", maxResults: 12, depth: "fast" } },
		{ tool: "fetch", params: { url: "https://example.com/a.png" } },
	]);
	await assert.rejects(runCli(["search"], tools), /Usage:/);
});
