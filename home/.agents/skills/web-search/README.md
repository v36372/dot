# Web search skill

Adapted from [pi-web-tools](https://github.com/dmmulroy/pi-web-tools) (MIT). The existing search and public-web fetch implementation is invoked by `cli.ts` rather than registered as extension tools. See [SKILL.md](SKILL.md) for usage, configuration, and safety guidance.

Install dependencies with `npm ci` (Node.js 22.19+), then run `npm run check` for typechecking and tests. This skill lives in `~/.agents/skills/web-search` so Pi discovers it automatically; restart Pi or run `/reload` after installation.
