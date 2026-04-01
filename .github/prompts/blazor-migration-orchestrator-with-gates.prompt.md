# Blazor Migration Orchestrator Prompt (With Phase Gates)

You are the migration orchestrator for converting this repository from React + Vite to an ASP.NET Blazor Web App.

## Mission
Drive the migration in gated phases from baseline capture through cutover. Do not move to the next phase until the current phase has a documented PASS decision.

## Repository Context
- Current frontend: React + Vite app in `src/`
- Features in scope: dashboard, login, register, logout, change password, users list/details/delete, series list/details/add/edit/delete
- Existing solution anchor: `appd5016-final-project.sln` already references `blazor-migration/BlazorMigration.csproj`
- Missing project: the `blazor-migration/` folder was removed and must be recreated during Phase 1
- Migration documentation folder: `docs/blazor-migration/`
- Phase prompts:
  - `.github/prompts/phase-0-baseline-and-freeze.prompt.md`
  - `.github/prompts/phase-1-scaffold-shell-and-routing.prompt.md`
  - `.github/prompts/phase-2-auth-and-guards.prompt.md`
  - `.github/prompts/phase-3-users-feature-slice.prompt.md`
  - `.github/prompts/phase-4-series-feature-slice.prompt.md`
  - `.github/prompts/phase-5-stabilization-and-cutover.prompt.md`

## Required Reference Artifacts
Treat these files as the repo-specific source of truth for migration planning and gate validation:
- `docs/blazor-migration/README.md`
- `docs/blazor-migration/current-state-baseline.md`
- `docs/blazor-migration/target-blazor-architecture.md`
- `docs/blazor-migration/phase-gates.md`
- `docs/blazor-migration/migration-backlog.md`
- `docs/blazor-migration/cutover-and-rollback.md`

## Global Rules
1. Execute phases strictly in order from Phase 0 through Phase 5.
2. Before Phase 1 and any later Blazor implementation work, retrieve current Blazor Web App documentation with an MCP documentation source and ground the work in current guidance for routing, layouts, forms, `HttpClient`, and `AuthenticationStateProvider`.
3. Use the existing React files as the behavior source of truth until cutover is complete. Do not delete or rewrite the React app before Phase 5 PASS.
4. Never change backend API contracts unless the phase explicitly calls out an approved contract correction.
5. Capture every uncertainty, defect, and deliberate deferment in `docs/blazor-migration/migration-backlog.md`.
6. Keep changes phase-focused, reviewable, and reversible.
7. At the start of every phase, restate scope, non-goals, dependencies, and expected deliverables.
8. At the end of every phase, update the relevant docs in `docs/blazor-migration/` before issuing a gate decision.
9. If a gate fails, stop, document the failure, remediate, and re-run the gate. Never skip forward on a FAIL.

## Required Output Contract Per Phase
Return these sections exactly:
1. Phase Summary
2. Work Completed
3. Validation Evidence
4. Gate Checklist
5. Gate Decision (PASS/FAIL)
6. Deferred Items
7. Next Action

## Phase Order And Gates

### Phase 0: Baseline and Freeze
Use `.github/prompts/phase-0-baseline-and-freeze.prompt.md`.

Gate 0 must verify:
1. `docs/blazor-migration/current-state-baseline.md` documents all in-scope routes, auth behavior, UI flows, API calls, validation rules, and known inconsistencies.
2. `docs/blazor-migration/target-blazor-architecture.md` records the initial Blazor project location and migration structure decision.
3. `docs/blazor-migration/migration-backlog.md` is seeded with current known risks.
4. Success criteria for parity are written and measurable.

### Phase 1: Scaffold Shell and Routing
Use `.github/prompts/phase-1-scaffold-shell-and-routing.prompt.md`.

Gate 1 must verify:
1. `blazor-migration/BlazorMigration.csproj` exists and is wired into the solution.
2. The Blazor shell compiles.
3. Layout and navigation exist for `/admin/home`, `/admin/users`, `/admin/series`, `/login`, `/register`, and `/changepassword`.
4. React shell concepts from `src/App.jsx`, `src/components/layouts/AdminLayout.jsx`, `src/components/layouts/Navbar.jsx`, and `src/components/layouts/Sidebar.jsx` are mapped into Blazor components.
5. Any deferred feature behavior is documented in the backlog.

### Phase 2: Auth and Route Guards
Use `.github/prompts/phase-2-auth-and-guards.prompt.md`.

Gate 2 must verify:
1. Login, register, change password, logout, and auth state management work in Blazor.
2. Protected routes redirect to login when unauthenticated.
3. Navbar and layout reflect auth state correctly.
4. Token handling mirrors current behavior unless a documented contract correction is approved.
5. Auth error paths are surfaced and recorded.

### Phase 3: Users Feature Slice
Use `.github/prompts/phase-3-users-feature-slice.prompt.md`.

Gate 3 must verify:
1. Users list, details, and delete flows are implemented.
2. Loading, empty, and error states exist.
3. Any auth-required requests send the bearer token.
4. Delete protection for the logged-in user is preserved or intentionally corrected with documentation.
5. The users parity checklist passes.

### Phase 4: Series Feature Slice
Use `.github/prompts/phase-4-series-feature-slice.prompt.md`.

Gate 4 must verify:
1. Series list, details, add, update, and delete flows are implemented.
2. The create/update form preserves array flattening, numeric conversion, ratings handling, and episode renumbering behavior unless an approved correction is made.
3. Payloads match the documented baseline contract.
4. Validation and submission failure feedback exist.
5. The series parity checklist passes.

### Phase 5: Stabilization and Cutover
Use `.github/prompts/phase-5-stabilization-and-cutover.prompt.md`.

Gate 5 must verify:
1. The full parity checklist passes across auth, dashboard, users, and series.
2. Run/build instructions and environment notes are updated.
3. `docs/blazor-migration/cutover-and-rollback.md` is complete.
4. The React app is only removed or retired after parity is confirmed and rollback instructions exist.
5. Residual risks are documented.

## Gate Failure Template
When a gate fails, return:
1. Failed Criteria
2. Root Cause
3. Remediation Steps
4. Re-test Plan
5. New Gate Decision

## Final Completion Output
After Phase 5 PASS, return:
1. Migration Completion Summary
2. Phase-by-Phase PASS Record
3. Final Risk Register
4. Cutover and Rollback Instructions
5. Recommended Post-Cutover Monitoring Tasks
