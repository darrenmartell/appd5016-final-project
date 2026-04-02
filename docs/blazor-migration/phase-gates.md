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
- Validation evidence:
  - `dotnet build appd5016-final-project.sln` succeeded after the Phase 1 scaffold was added.
  - `dotnet run --project blazor-migration/BlazorMigration.csproj` started successfully and listened on `http://localhost:5204` during validation.
  - HTTP checks against `/`, `/admin`, `/admin/home`, `/admin/users`, `/admin/series`, `/login`, `/register`, and `/changepassword` all returned `200` during validation.
  - The missing project was recreated at `blazor-migration/BlazorMigration.csproj`, satisfying the existing solution reference.
  - The Blazor shell now includes `MainLayout`, `AdminLayout`, `Navbar`, `Sidebar`, and `SidebarItem` components.
  - Routeable pages now exist for `/admin/home`, `/admin/users`, `/admin/series`, `/login`, `/register`, and `/changepassword`.
  - Redirect pages now preserve the React navigation behavior from `/` to `/admin/home` and from `/admin` to `/admin/home`.
- Gate result: PASS
- Decision date: 2026-04-01
- Remaining open items:
  - BLZ-002
  - BLZ-003
  - BLZ-004
  - BLZ-005
  - BLZ-006
  - BLZ-007
  - BLZ-008

## Phase 2

- Scope: auth, auth state, and route guards
- Required evidence:
  - login/register/logout implemented
  - change password implemented or formally blocked with evidence
  - protected-route behavior verified
  - auth error handling verified
- Validation evidence:
  - `dotnet build appd5016-final-project.sln` succeeded after the Phase 2 auth implementation and route-guard changes.
  - The login page at `/login` rendered the Phase 2 auth form and email field during runtime checks.
  - An unauthenticated request to `/admin/home` rendered the redirect-to-login content during runtime checks.
  - Live backend validation against `https://assignment2-restapi-darrenmartell-h.vercel.app` confirmed that both register and login return `_id` and `access_token`.
  - The auth service accepts both `access_token` and `accessToken` and supports both `id` and `_id` for compatibility, even though the deployed backend returned `_id` and `access_token` consistently.
  - Login and register were successfully exercised against the live backend with a disposable test user.
  - Logout clears the in-memory auth state through `IAuthService.LogoutAsync` and the navbar switches back to unauthenticated links.
  - The change-password route is now formally blocked with a user-visible message because you confirmed there is no backend change-password route yet.
  - Login and register pages surface user-visible error messages for failed responses and connection failures.
  - Live registration and login were successfully exercised against the deployed backend using a disposable test user.
- Gate result: PASS
- Decision date: 2026-04-01
- Remaining open items:
  - BLZ-007
  - BLZ-008
  - BLZ-010

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