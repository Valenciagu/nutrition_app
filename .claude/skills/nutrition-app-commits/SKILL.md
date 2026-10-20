---
name: nutrition-app-commits
description: Commit conventions for this nutrition app — how to split work into commits, the subject/body format, scopes, task IDs and attribution. Use whenever creating a git commit in this repo, after the user authorizes it.
---

# Nutrition App — Commit Conventions

Derived from the project's own history (`git log` from FOUND-009 onward). Follow it for every commit; match the existing log, don't invent a new style.

## When to commit

- Only when the user asks or authorizes it. Never push unless asked separately.
- Before committing: `flutter analyze` clean (and `tsc`/`npm run build` in `functions/` if it changed). Say in the body if something could not be verified (e.g. "not yet verified on a real device").
- Don't commit stray files unrelated to the app (scratch scripts, exercises, local experiments) — ask or leave them out.

## How to split

- **One commit per logical change / task ID**, not per session. If the working tree mixes two unrelated changes, split them — even within one file (stage a partial version via `git hash-object -w` + `git update-index --cacheinfo`, since interactive `git add -p` isn't available here). Each commit must compile on its own.
- Generated platform files (launcher icons, native splash, `pubspec.lock`) go in the same commit as the config that produced them.
- **Docs sync**: feature commits normally include their own `TASKS.md` / `documentation/<feature>.md` / `PROJECT_CONTEXT.md` updates. Use a separate `docs:` commit only for documentation-only work (stale-status passes, recording decisions/deferrals, newly raised pending items).

## Subject line

Format: `type(scope): imperative summary (TASK-ID)`

- English, lowercase after the colon, imperative ("add", "stop", "make ... real", "persist"), no trailing period, ~72 chars max.
- **Types** used: `feat`, `fix`, `docs`. (`chore`/`refactor` only if a change genuinely is neither.)
- **Scope** = feature or layer, kebab-case, matching `lib/features/*` or the area touched: `auth`, `onboarding`, `plan`, `profile`, `notifications`, `ai-assistant`, `food-analysis`, `analytics`, `security`, `design`, `functions`, `android`, `ui`. Two areas → `feat(profile, notifications): ...`. `docs` has no scope.
- **Task ID** from `TASKS.md` in parentheses at the end when one exists: `(AUTH-104)`, `(ONBOARD-101)`; a whole epic → `(Epic 18)`.
- `fix` subjects describe the user-visible symptom being removed: `fix(analytics): stop crashing on food_photo_analyzed event`.

Examples from the log:
```
feat(auth): add Google sign-in (AUTH-103a)
feat(onboarding): build B8/B9 with Firebase anonymous auth (ONBOARD-101)
fix(functions): grant public invoker to all callable functions
docs: record Epic 13's deferral as a cost decision, not a blocker
```

## Body

Wrapped at ~72 columns, prose paragraphs (bullets with `- ` when listing several independent pieces). Explain **why** and the non-obvious decisions, not a file-by-file diff recap:

1. The problem / motivation — what was wrong or missing, in user or product terms.
2. What was done and the key design decision (which existing pattern/provider/pipeline it reuses, what was deliberately *not* done and why).
3. Platform or console requirements, deviations from the design canvas confirmed with the user, and anything left pending or manual (e.g. "Requires enabling the X provider in Firebase Console").

Reference code identifiers plainly (`linkWithCredential`, `AppIcons`), canvas screens by ID (A4, B8), and dates as `2026-10-05`. Multiple task IDs in one commit → one short paragraph each, opening with the ID (`ASSET-102: ...`).

## Attribution

End the message with the co-author trailer given by the current session's attribution instructions (e.g. `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`), separated by a blank line. Pass the message via a heredoc (`git commit -F - <<'EOF'`) to keep formatting intact.
