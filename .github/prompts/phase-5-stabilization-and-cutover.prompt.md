# Phase 5 Copilot Prompt: Stabilization and Cutover

You are executing Phase 5 of this repo's migration from React + Vite to ASP.NET Blazor.

## Scope
Validate parity, harden the migrated experience, and prepare a safe cutover from the React frontend to the Blazor frontend.

## Inputs
- `docs/blazor-migration/current-state-baseline.md`
- `docs/blazor-migration/phase-gates.md`
- `docs/blazor-migration/migration-backlog.md`
- `docs/blazor-migration/cutover-and-rollback.md`

## Tasks
1. Re-run the full parity checklist across auth, dashboard, users, and series.
2. Verify public and protected route behavior end to end.
3. Verify loading, empty, validation, and error states.
4. Verify responsive behavior for the layout, list pages, and the series form.
5. Update all run/build/env documentation for the Blazor app.
6. Complete `docs/blazor-migration/cutover-and-rollback.md`.
7. Retire the React app only after all parity gates pass and rollback instructions exist.
8. Record residual risks and post-cutover monitoring tasks.

## Constraints
- Do not remove the React fallback path before the gate passes.
- Keep cutover steps incremental and reversible.
- If parity fails, stop and document the failure instead of forcing the cutover.

## Gate 5 Checklist
1. Final parity checklist passes.
2. Protected/public routing behavior is verified.
3. Major responsive scenarios are verified.
4. Run/build/env docs are complete.
5. Cutover steps are written.
6. Rollback steps are written.
7. Residual risks are documented.

## Required Output Contract
Return exactly:
1. Phase Summary
2. Work Completed
3. Validation Evidence
4. Gate Checklist
5. Gate Decision (PASS/FAIL)
6. Deferred Items
7. Next Action
