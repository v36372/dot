---
name: finalize
description: Finalize an implementation by removing unnecessary debug code, temporary diagnostics, dead code, obsolete feature flags, needless fallback paths, and other temporary logic; validate the result; obtain repeated independent reviews from the strongest available high-reasoning code-review subagent until the changes pass; then stage, commit, and push the intended changes to origin by default. Use when the user asks to finish, finalize, clean up, independently review, commit, or push completed work in a Git repository. Treat explicit requests to leave changes uncommitted or skip pushing as overrides of the default terminal actions.
disable-model-invocation: true
---

# Finalize

Turn completed implementation work into a clean, independently reviewed, validated, committed, and pushed change by default. Preserve intentional behavior, explicit user constraints, and unrelated user work throughout the workflow.

## Resolve the requested stopping point

Default to the full workflow: clean, validate, obtain an explicit independent review pass, stage, commit, and push to `origin`. Do not pause for confirmation before the default commit or push when the user has not limited them.

Apply the user's latest explicit constraint as an override:

- Interpret "don't commit and push," "don't commit or push," "leave it uncommitted," and "stop after review" as instructions to complete cleanup, validation, and the review loop, then stop before staging, committing, or pushing.
- Interpret "don't commit" as instructions not to create a commit and not to push unless the user separately and explicitly asks to push existing commits. Stop before staging by this workflow.
- Interpret "don't push" as instructions to perform the default cleanup, validation, review, staging, and local commit, then stop without contacting the remote.
- Interpret "commit but don't push" as instructions to create the reviewed local commit and stop before pushing.
- Honor narrower constraints such as a user-supplied commit message, remote, branch, or requested stopping point without disabling unrelated workflow stages.

Do not silently restore a skipped action later in the workflow. If instructions are genuinely contradictory or require deciding whether to publish pre-existing commits, request clarification before the affected Git action while completing safe earlier stages when possible.

## Establish the change scope

1. Confirm that the working directory is a Git repository and inspect the current branch, `origin`, upstream, worktree status, staged diff, unstaged diff, and relevant untracked files.
2. Identify the changes belonging to the current task from the conversation, task artifacts, and Git diff. Include branch commits relative to the task's base only when they belong to the task.
3. Keep unrelated or pre-existing user changes out of the cleanup, review, staging, and commit. Stop and request clarification when the intended scope cannot be separated safely.
4. Do not use destructive Git operations, discard user changes, rewrite existing commits, force-push, or push tags.

## Clean the implementation

Review every in-scope changed file and enough surrounding code to understand whether each addition is intentional. Remove items that are unnecessary in the finished implementation, including:

- Debug prints, console output, breakpoints, ad hoc logging, tracing, dumps, and diagnostic endpoints.
- Temporary metrics, assertions, probes, verbose error details, test-only hooks, and local-development overrides.
- Dead code, unused imports or variables, commented-out implementations, duplicate branches, and unreachable paths.
- Temporary feature flags, compatibility shims, fallback paths, hard-coded values, TODO scaffolding, and migration logic that the completed feature no longer needs.
- Defensive or speculative complexity introduced during implementation that has no supported use case.

Beyond removing leftovers, actively reduce complexity within the scope of the change. Insofar as the issues being addressed in the diff allow, leave the touched code simpler and less complex than you found it:

- Eliminate unnecessary complexity: collapse needless indirection, layers, and abstractions the change introduced or no longer justifies.
- Avoid bloating data structures, particularly at key API points. Do not let parameter lists, option objects, return shapes, or shared types accumulate fields the finished change does not need; prefer the narrowest interface that serves the supported use cases.
- Encapsulate or eliminate state where it seems possible. Prefer deriving a value over storing it, local over shared state, and hiding state behind the component that owns it over exposing it across API boundaries.

Preserve purposeful observability, supported compatibility behavior, error handling, security checks, accessibility behavior, and documented feature flags. Remove a fallback or compatibility path only when the diff and surrounding contract show that it is temporary or unnecessary; do not equate all fallback behavior with dead code.

Keep the cleanup tightly scoped. Simplification applies to the code the task touches and its immediate contracts; do not perform opportunistic refactors unrelated to the task.

## Validate before review

1. Inspect the cleaned diff for accidental changes, secrets, generated artifacts, and formatting noise.
2. Run the repository's relevant formatter, lint, type-check, tests, build, and pre-commit checks in proportion to the change's risk. Use the project's documented commands and start with the narrowest relevant checks before broader suites.
3. Fix failures caused by the task. Distinguish pre-existing or environmental failures with evidence; do not claim validation passed when it did not.
4. Ensure the diff is stable before requesting review. Any later code change invalidates the previous review pass.

## Run the independent review loop

Use a fresh code-review subagent for every review round.

1. Select the strongest available code-review subagent and the highest available reasoning setting. When explicit model or reasoning selection is unavailable, use the strongest configured subagent rather than claiming a specific model.
2. Give the reviewer read-only instructions and only the context needed to evaluate the current result: repository path, original task, intended change scope, base reference when relevant, current diff or commit range, and validation results.
3. Preserve review independence. Do not reveal expected answers, suspected defects, previous review conclusions, rejected findings, or the fixes that should be suggested.
4. Ask the reviewer to cover the entire proposed changeset, not only selected files or the latest fixes, and apply the judgment expected in a senior-engineer code review. Within the scope of the requested change, have the reviewer identify concrete defects, regressions, missing tests, and opportunities to consolidate, simplify, or remove logic — including unnecessary complexity, data-structure bloat at key API points, and state that could be encapsulated or eliminated. Have the reviewer inspect relevant surrounding code as needed to assess security or privacy problems, concurrency and data-integrity risks, error handling, maintainability issues, and leftover temporary or unnecessary code, and to judge whether the change leaves the touched code simpler and less complex than it found it, insofar as the issues being addressed allow. Do not invite unrelated redesigns, broad refactors, speculative hardening, or requirements beyond the user's request.
5. Require the reviewer to weigh nuanced issues and edge cases against their user-facing impact, likelihood under supported usage, and the implementation and maintenance cost of addressing them. The reviewer should:
   - Report an issue as an actionable finding when it is reasonably expected, has severe impact, or has a straightforward fix whose value clearly exceeds its incidental complexity.
   - Report a genuinely debatable tradeoff as an explicitly non-blocking observation, explain the tradeoff, and leave the decision to the reviewee.
   - Omit marginal or implausible concerns when addressing them would add complexity disproportionate to their likely impact.
6. Require actionable findings to be ordered by severity and supported with file and line references. Keep non-blocking observations separate from actionable findings. Require the reviewer to return an explicit `PASS` when no actionable findings remain; a `PASS` may include clearly labeled non-blocking observations.
7. Evaluate every actionable finding against the code and requirements. Fix each issue you concur with. For findings you reject, verify the reason from repository evidence rather than dismissing them reflexively. Consider non-blocking observations without treating them as pass blockers or expanding the task by default.
8. Rerun the relevant validation after fixes, then request another independent review of the new artifact. Do not tell the next reviewer what the prior reviewer found.
9. Continue until a fresh reviewer explicitly returns `PASS` with no unresolved actionable findings. Do not impose an arbitrary review-round limit or weaken the pass standard to finish sooner.

Stop before committing if the user excluded commits, a substantive finding cannot be resolved safely, validation cannot complete, a reviewer cannot be launched, or repeated reviews expose a requirement ambiguity that needs the user. Report the concrete blocker and preserve all work.

## Commit and push

Run this section by default, subject to the stopping point resolved above. Proceed only after the cleaned, validated diff has received an explicit review pass.

1. Recheck the complete diff and worktree status. If anything changed after the passing review, validate it and repeat the independent review loop.
2. Stage only the intended task files. Avoid broad staging commands when unrelated changes are present.
3. Review the staged diff and verify that it contains no unrelated files, secrets, temporary artifacts, or unreviewed changes.
4. Create one appropriately scoped commit using a concise message derived from the completed work unless the user supplied a message.
5. If a commit hook changes code or leaves additional task changes, do not push. Validate and review the resulting artifact again, then create or amend only the commit created by this workflow as appropriate.
6. Stop after the local commit when the user excluded pushing. Otherwise, verify that `origin` targets the expected repository and that the current branch is not detached. Push the current branch to `origin`; set its upstream only when needed. Never force-push.
7. If authentication, branch protection, remote configuration, or another external condition prevents the push, leave the successful local commit intact and report the exact failure.

## Report the result

Summarize the cleanup performed, validation commands and outcomes, number of independent review rounds, accepted fixes, any rejected findings with concise reasons, commit hash and message when created, branch, and push result. State which commit or push action was intentionally skipped because of a user override. Clearly disclose any skipped check or unresolved external failure.
