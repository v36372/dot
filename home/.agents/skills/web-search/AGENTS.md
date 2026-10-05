# Web Search Skill

## Guardrails

- Parse external data at boundaries before passing it inward.
- Preserve SSRF protections, URL credential redaction, response limits, and output truncation.
- Model expected failures with the local `Result` type; surface safe errors at the CLI boundary.
- Keep the skill executable through the shell without registering Pi extension tools.
- Run `npm run check` after changes.
