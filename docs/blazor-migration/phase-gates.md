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
- Validation evidence:
  - `dotnet build blazor-migration/BlazorMigration.csproj` succeeded after the Phase 3 users slice implementation.
  - Runtime checks against `http://localhost:5204/admin/users`, `http://localhost:5204/admin/users/test-id/details`, and `http://localhost:5204/admin/users/test-id/delete` all returned `200` and rendered the redirect-to-login content when unauthenticated.
  - The Blazor users slice now includes a real users list page plus routeable details and delete pages backed by `IUsersService`.
  - The users list page handles loading, empty, and API error states directly in the page UI.
  - The details page handles loading, missing-user, and API error states directly in the page UI.
  - The delete page handles loading, missing-user, self-delete-blocked, in-flight delete, and API error states directly in the page UI.
  - Live backend validation against `https://assignment2-restapi-darrenmartell-h.vercel.app` confirmed that `DELETE /users/{id}` returns `401` without a bearer token and succeeds with a valid bearer token for a disposable test user.
  - The delete UI preserves the React parity rule that the currently logged-in user cannot delete their own account from the users screen.
- Gate result: PASS
- Decision date: 2026-04-01
- Remaining open items:
  - BLZ-007
  - BLZ-008
  - BLZ-010

## Phase 4

- Scope: series slice
- Required evidence:
  - list/details/add/update/delete verified
  - payload parity verified
  - validation and submission error handling verified
- Validation evidence:
  - `dotnet build blazor-migration/BlazorMigration.csproj` succeeded after the Phase 4 series slice implementation before the runtime validation pass began.
  - Runtime checks against `http://localhost:5204/admin/home`, `http://localhost:5204/admin/series`, `http://localhost:5204/admin/series/test-id/details`, `http://localhost:5204/admin/series/add`, `http://localhost:5204/admin/series/test-id/update`, and `http://localhost:5204/admin/series/test-id/delete` all returned `200` and rendered the redirect-to-login content when unauthenticated.
  - The Blazor dashboard now reads live series data and applies navbar-driven search filtering with the same broad field search strategy as the React dashboard.
  - The Blazor series slice now includes real list, details, add, update, and delete pages backed by `ISeriesService` and `SeriesEditor`.
  - The form mapping remains explicit through `SeriesFormMapper`, including sequential episode renumbering on submit.
  - Live backend validation against `https://assignment2-restapi-darrenmartell-h.vercel.app` successfully exercised `POST /series`, `PUT /series/:id`, and `DELETE /series/:id` with a disposable authenticated user and a fully populated payload.
  - Live backend validation confirmed that `DELETE /series/:id` returns `401` without a bearer token and succeeds with a valid bearer token.
  - The series pages surface user-visible loading, empty, validation, and API error states.
  - A write-contract correction was required: the deployed backend rejects React-style blank-to-`0` values for `runtime_minutes` and `released_year`, and also rejects missing or null rating values on write. The Blazor form now validates those fields as required for successful create and update requests. This correction is documented in the backlog.
- Gate result: PASS
- Decision date: 2026-04-02
- Remaining open items:
  - BLZ-007
  - BLZ-010
  - BLZ-011

## Phase 5

- Scope: stabilization, cutover, rollback
- Required evidence:
  - final parity checklist complete
  - build/run/env docs complete
  - cutover plan complete
  - rollback plan complete
- Validation evidence:
  - `dotnet build appd5016-final-project.sln` succeeded during the final Phase 5 stabilization pass.
  - Final route-matrix checks against the running Blazor app verified that `/login` and `/register` render publicly, while `/changepassword`, `/admin/home`, `/admin/users`, `/admin/users/test-id/details`, `/admin/users/test-id/delete`, `/admin/series`, `/admin/series/test-id/details`, `/admin/series/add`, `/admin/series/test-id/update`, and `/admin/series/test-id/delete` all return `200` and render redirect-to-login content when unauthenticated.
  - Phase 2 through Phase 4 validation evidence already covers the live backend checks for login/register, users delete, and series create/update/delete.
  - Responsive behavior was verified repo-locally by reviewing the implemented media-query paths in `AdminLayout.razor.css`, `Navbar.razor.css`, `Sidebar.razor.css`, and `wwwroot/app.css`, including stacked admin layout behavior below `840px`, full-width navbar search below `840px`, mobile sidebar behavior below `840px`, and single-column series form behavior below `640px`.
  - Top-level run/build/config documentation was updated in `README.md` to cover both the Blazor app and the retained React fallback.
  - `cutover-and-rollback.md` now contains a repo-local final parity checklist, build/run reference, incremental cutover steps, rollback steps, residual risks, and post-cutover monitoring tasks.
  - The React frontend remains preserved in `src/` as a fallback path, satisfying the repo-local rollback requirement.
- Gate result: PASS
- Decision date: 2026-04-02
- Remaining open items:
  - BLZ-007
  - BLZ-010
  - BLZ-011