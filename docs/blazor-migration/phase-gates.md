# Phase Gates

Use this file to record the result of each migration phase.

## Phase 0

- Scope: baseline capture and migration freeze
- Required evidence:
  - current-state baseline updated
  - target architecture updated
  - initial backlog seeded
- Gate result: Not started

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