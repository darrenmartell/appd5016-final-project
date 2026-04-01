# Phase 0 Copilot Prompt: Baseline and Freeze

You are executing Phase 0 of the React-to-Blazor migration for this repository.

## Scope
Capture the current React behavior and freeze it into migration documentation before any Blazor implementation begins.

## Non-Goals
- Do not scaffold Blazor code in this phase.
- Do not change frontend behavior except for documentation updates.
- Do not normalize backend contracts that appear inconsistent. Document them first.

## Source Files To Inspect
- `src/routes/AppRoutes.jsx`
- `src/routes/ProtectedRoute.jsx`
- `src/context/AuthContext.jsx`
- `src/App.jsx`
- `src/components/layouts/AdminLayout.jsx`
- `src/components/layouts/Navbar.jsx`
- `src/components/layouts/Sidebar.jsx`
- `src/pages/Login.jsx`
- `src/pages/Register.jsx`
- `src/pages/ChangePassword.jsx`
- `src/pages/Dashboard.jsx`
- `src/pages/Users.jsx`
- `src/pages/Series.jsx`
- `src/components/users/*`
- `src/components/series/*`
- `appd5016-final-project.sln`
- `test-api-server/setup.txt`
- `test-api-server/routes.json`

## Required Documentation Updates
Update these files in `docs/blazor-migration/`:
1. `current-state-baseline.md`
2. `target-blazor-architecture.md`
3. `migration-backlog.md`

## Required Findings
1. Document the route map, including redirects from `/` and `/admin` to `/admin/home`.
2. Document which routes are protected and which are public.
3. Record the auth model exactly as implemented today, including the fact that auth state is in React context and is not persisted across refresh.
4. Capture current API usage and payload expectations, including these repo-specific inconsistencies:
   - login expects `access_token` on success
   - register expects `accessToken` on success
   - change password posts `JSON.stringify(newPassword)` instead of an object
   - change password reads `user._id` even though login/register store `user.id`
5. Capture form validation rules and user-visible error messages.
6. Record how series add/edit transforms data before submit:
   - string arrays flattened from field-array items
   - numeric fields converted with `Number(...)`
   - blank ratings converted to `null`
   - episodes renumbered sequentially on submit
7. Record known environment and test-server gaps, including the mismatch between the current UI domain and `test-api-server/routes.json`.
8. Define explicit parity success criteria for the later gates.

## Gate 0 Checklist
1. `current-state-baseline.md` includes parity checklist, route/auth matrix, API contract summary, validation notes, and risks.
2. `target-blazor-architecture.md` records that the missing Blazor project must be recreated at `blazor-migration/BlazorMigration.csproj` because the solution already references that path.
3. `migration-backlog.md` contains initial backlog items for current contract and environment risks.
4. No production React behavior was changed.

## Required Output Contract
Return exactly:
1. Phase Summary
2. Work Completed
3. Validation Evidence
4. Gate Checklist
5. Gate Decision (PASS/FAIL)
6. Deferred Items
7. Next Action
