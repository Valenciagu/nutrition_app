---
name: nutrition-app-workflow
description: Task-based development process for this nutrition app — how to plan, document, and track work in TASKS.md, documentation/, and PROJECT_CONTEXT.md. Use before starting any new task, feature, or epic, and after finishing one.
---

# Nutrition App — Development Workflow

This project is built incrementally, one task at a time, per `Instrucciones.md` (master spec) and explicit user process requirements. Follow this workflow for every unit of work, no exceptions.

## Source of truth files (project root)

- `Instrucciones.md` — master product/technical/security spec. Re-read relevant sections before any non-trivial decision.
- `desing.md` — pointer to the visual design (Claude Design canvas). UI must match it; do not invent design.
- `TASKS.md` — the epic/task backlog and status board. Single source of truth for "what's next."
- `PROJECT_CONTEXT.md` — consolidated, always-current description of what the app currently contains (features, architecture decisions, screens, entities). Read this first when resuming work in a new session.
- `documentation/<feature>.md` — one file per feature describing what was built, why, and how it works.

## Before starting a task

1. Read `TASKS.md` and `PROJECT_CONTEXT.md` to know current state.
2. Pick (or confirm with the user) the next task. Do not silently jump ahead to unrelated features.
3. State the task using this format before implementing:
   - **Objective** — what this task accomplishes.
   - **Existing code to reuse** — components/services already in the project (check `core/` and existing features first).
   - **Files to create / modify** — only what's genuinely required.
   - **Architecture impact** — if any.
   - **Security considerations** — if any (see the `nutrition-app-security` skill).
4. Implement only that task. If another task turns out to be a hard dependency, say so explicitly rather than silently expanding scope.

## While implementing

- Reuse first, extend second, create new only when justified (see `nutrition-app-architecture` skill).
- Never hardcode user-facing strings — see the localization rule in `nutrition-app-architecture`.
- Match the existing visual design system — see `nutrition-app-design`.
- **Skip writing automated tests for now** — the user explicitly deferred all testing to a later, dedicated pass to conserve tokens. Do not add `test/` files per feature unless the user asks earlier. Do note in the feature's documentation what should eventually be tested.

## After finishing a task

1. Update `TASKS.md`: mark the task done, add any newly-discovered follow-up tasks.
2. If the task completes a meaningful feature (or a significant slice of one), create/update `documentation/<feature>.md` describing:
   - What the feature does (product-level).
   - Key files and their responsibilities.
   - Architecture/state-management notes specific to this feature.
   - Reused components vs. new ones (and why new ones were justified, if any).
   - Known gaps / what's deferred (e.g., tests, edge cases).
3. Update `PROJECT_CONTEXT.md` to reflect the new state of the whole app (not just the new feature in isolation) — this file should always let a fresh session understand "what exists today" without re-reading every file.
4. Report a concise summary of what changed and suggest the next logical task — but do not implement it automatically. Stop and wait unless the user has asked to proceed through a batch of tasks.

## Do not

- Do not build multiple unrelated features in one pass.
- Do not generate large amounts of boilerplate "just in case."
- Do not skip updating `TASKS.md` / `PROJECT_CONTEXT.md` — stale context files defeat their purpose.
