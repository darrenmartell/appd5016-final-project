# Blazor Migration Orchestrator Prompt (With Phase Gates)

You are the migration orchestrator for converting this frontend from React + Vite to ASP.NET Blazor.

## Mission
Execute migration phases sequentially with strict quality gates. Do not proceed to the next phase until the current phase gate is passed.

## Repository Context
- Existing app: React + Vite frontend with auth, users, series, dashboard, and change-password flows
- Target app: ASP.NET Blazor Web App with SPA-like interactivity
- Existing phase prompts:
  - .github/prompts/phase-0-baseline-and-freeze.prompt.md
  - .github/prompts/phase-1-scaffold-shell-and-routing.prompt.md
  - .github/prompts/phase-2-auth-and-guards.prompt.md
  - .github/prompts/phase-3-users-feature-slice.prompt.md
  - .github/prompts/phase-4-series-feature-slice.prompt.md
  - .github/prompts/phase-5-stabilization-and-cutover.prompt.md

## Global Rules
1. Execute phases in order from Phase 0 to Phase 5.
2. At the start of each phase, restate:
   - scope
   - non-goals
   - expected deliverables
3. At the end of each phase, produce:
   - evidence of completion
   - gate checklist results
   - decision: PASS or FAIL
4. If gate FAILS:
   - list blockers
   - create a short remediation plan
   - implement remediation
   - re-run gate
5. Never skip a gate.
6. Never change backend API contracts unless explicitly approved.
7. Keep changes small, reviewable, and phase-focused.
8. Track all deferred items in a running migration backlog.

## Required Output Contract Per Phase
Return these sections exactly:
1. Phase Summary
2. Work Completed
3. Validation Evidence
4. Gate Checklist
5. Gate Decision (PASS/FAIL)
6. Deferred Items
7. Next Action

---

## Phase Execution Steps

### Phase 0: Baseline and Freeze
Use .github/prompts/phase-0-baseline-and-freeze.prompt.md

#### Gate 0 Criteria
1. Parity checklist exists and covers all critical flows:
   - login, register, logout
   - dashboard access
   - users list/details/delete
   - series list/details/add/edit/delete
   - change password
2. Route and auth matrix documented.
3. API contract summary documented for all used endpoints.
4. Validation rules and edge cases documented.
5. Migration success criteria written and approved.

#### Gate 0 Evidence
- Link or reference to generated baseline docs.
- Short summary of unresolved assumptions.

Proceed only if all criteria are met.

---

### Phase 1: Scaffold Shell and Routing
Use .github/prompts/phase-1-scaffold-shell-and-routing.prompt.md

#### Gate 1 Criteria
1. Blazor app shell compiles and runs.
2. Layout implemented (navbar, sidebar, content area).
3. Target routes exist:
   - /admin/home
   - /admin/users
   - /admin/series
   - /login
   - /register
   - /changepassword
4. Navigation works between all listed routes.
5. Deferred items are documented clearly.

#### Gate 1 Evidence
- Build/run confirmation.
- Route parity table with implemented path status.

Proceed only if all criteria are met.

---

### Phase 2: Auth and Route Guards
Use .github/prompts/phase-2-auth-and-guards.prompt.md

#### Gate 2 Criteria
1. Auth service methods implemented (login, register, change password, logout).
2. JWT storage and retrieval implemented.
3. Auth state provider integrated.
4. Protected routes redirect unauthorized users to login.
5. Navbar reflects auth state correctly.
6. Auth error states surfaced to user.

#### Gate 2 Evidence
- Auth flow test matrix with pass/fail per flow.
- Protected route behavior summary.

Proceed only if all criteria are met.

---

### Phase 3: Users Feature Slice
Use .github/prompts/phase-3-users-feature-slice.prompt.md

#### Gate 3 Criteria
1. Users list screen implemented and wired to API.
2. User details screen implemented and wired to API.
3. User delete flow implemented and wired to API.
4. Loading, empty, and error states present.
5. Auth-required calls include bearer token.
6. Users parity checklist passes.

#### Gate 3 Evidence
- Users workflow validation checklist.
- Notes on any non-blocking parity differences.

Proceed only if all criteria are met.

---

### Phase 4: Series Feature Slice
Use .github/prompts/phase-4-series-feature-slice.prompt.md

#### Gate 4 Criteria
1. Series list/details/add/edit/delete are implemented.
2. Add/Edit form supports:
   - scalar fields
   - tag arrays
   - ratings object
   - dynamic episodes collection
3. Submission payload shape matches baseline contract.
4. Validation and error feedback are functional.
5. Series parity checklist passes.

#### Gate 4 Evidence
- Payload parity comparison for create/update.
- Workflow validation results for series operations.

Proceed only if all criteria are met.

---

### Phase 5: Stabilization and Cutover
Use .github/prompts/phase-5-stabilization-and-cutover.prompt.md

#### Gate 5 Criteria
1. End-to-end parity checklist passes.
2. Protected/public route behavior verified.
3. Responsive behavior validated on key pages.
4. Documentation updated with run/build/env instructions.
5. Cutover checklist completed.
6. Rollback plan documented and tested at least once.

#### Gate 5 Evidence
- Final parity report.
- Cutover readiness report.
- Residual risk register.

Proceed to completion only if all criteria are met.

---

## Gate Failure Template
When a phase fails a gate, use this template:

1. Failed Criteria
2. Root Cause
3. Remediation Steps
4. Re-test Plan
5. New Gate Decision

## Migration Backlog Template
Maintain backlog continuously with:
- ID
- Description
- Phase Introduced
- Severity (High/Medium/Low)
- Owner
- Resolution Target Phase
- Status

## Final Completion Output
At the end of Phase 5 PASS, provide:
1. Migration Completion Summary
2. Phase-by-Phase PASS Record
3. Final Risk Register
4. Cutover and Rollback Instructions
5. Recommended Post-Cutover Monitoring Tasks
