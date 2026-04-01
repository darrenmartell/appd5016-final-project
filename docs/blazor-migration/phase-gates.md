# Phase Gates

Use this file to record the result of each migration phase.

## Phase 0

- Scope: baseline capture and migration freeze
- Required evidence:
  - current-state baseline updated
  - target architecture updated
  - initial backlog seeded
- Validation evidence:
  - `current-state-baseline.md` records route/auth matrix, API contract summary, validation rules, parity checklist, known inconsistencies, and measurable success criteria.
  - `target-blazor-architecture.md` records that the missing Blazor project must be recreated at `blazor-migration/BlazorMigration.csproj` because the solution already points there.
  - `migration-backlog.md` contains the initial contract, routing, and environment risks discovered during baseline capture.
  - No React production behavior was changed during this phase.
- Gate result: PASS
- Decision date: 2026-04-01
- Remaining open items:
  - BLZ-002
  - BLZ-003
  - BLZ-004
  - BLZ-005
  - BLZ-006
  - BLZ-007

## Phase 1

- Scope: scaffold Blazor shell and route structure
- Required evidence:
  - `blazor-migration/BlazorMigration.csproj` created
  - solution reference valid
  - route skeleton implemented
  - layout/navigation implemented
- Gate result: Not started

## Phase 2

- Scope: auth, auth state, and route guards
- Required evidence:
  - login/register/logout implemented
  - change password implemented or formally blocked with evidence
  - protected-route behavior verified
  - auth error handling verified
- Gate result: Not started

## Phase 3

- Scope: users slice
- Required evidence:
  - users list/details/delete verified
  - loading/empty/error states verified
  - bearer token usage verified for protected actions
- Gate result: Not started

## Phase 4

- Scope: series slice
- Required evidence:
  - list/details/add/update/delete verified
  - payload parity verified
  - validation and submission error handling verified
- Gate result: Not started

## Phase 5

- Scope: stabilization, cutover, rollback
- Required evidence:
  - final parity checklist complete
  - build/run/env docs complete
  - cutover plan complete
  - rollback plan complete
- Gate result: Not started