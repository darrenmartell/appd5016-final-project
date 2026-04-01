# Phase 3 Copilot Prompt: Users Feature Slice

You are executing Phase 3 of this repo's migration from React + Vite to ASP.NET Blazor.

## Scope
Deliver the users slice in Blazor with parity for list, details, and delete.

## React Source Of Truth
- `src/pages/Users.jsx`
- `src/components/users/UserTable.jsx`
- `src/components/users/UserDetails.jsx`
- `src/components/users/DeleteUser.jsx`
- `src/routes/AppRoutes.jsx`

## Tasks
1. Implement the users data service around the current `/users` API usage.
2. Recreate the users list page, details page, and delete flow.
3. Preserve the current route patterns:
   - `/admin/users`
   - `/admin/users/{id}/details`
   - `/admin/users/{id}/delete`
4. Preserve the current logged-in-user delete protection, or document and approve a correction if the React behavior is unsafe or inconsistent.
5. Add loading, empty, and error states.
6. Ensure any protected action sends the bearer token.
7. Update the validation evidence in `docs/blazor-migration/phase-gates.md`.
8. Update `docs/blazor-migration/migration-backlog.md` with any remaining parity gaps.

## Constraints
- Do not redesign the feature beyond what is needed for parity.
- Avoid hidden behavior changes to delete authorization or route semantics.
- Keep the implementation reviewable and feature-local.

## Gate 3 Checklist
1. Users list renders from the API.
2. User details renders for the selected user.
3. Delete flow works or clearly blocks in the same cases as the current app.
4. Loading, empty, and error states are present.
5. Protected calls send the bearer token.
6. Users parity notes are documented.

## Required Output Contract
Return exactly:
1. Phase Summary
2. Work Completed
3. Validation Evidence
4. Gate Checklist
5. Gate Decision (PASS/FAIL)
6. Deferred Items
7. Next Action
