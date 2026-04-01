# Phase 2 Copilot Prompt: Auth and Route Guards

You are executing Phase 2 of this repo's migration from React + Vite to ASP.NET Blazor.

## Scope
Implement auth flows, auth state, and protected route behavior in Blazor with parity to the current React app.

## Prerequisites
1. Read `docs/blazor-migration/current-state-baseline.md`.
2. Read `docs/blazor-migration/target-blazor-architecture.md`.
3. Retrieve current Blazor documentation for `AuthenticationStateProvider`, forms, and `HttpClient` before writing code.

## React Source Of Truth
- `src/context/AuthContext.jsx`
- `src/routes/ProtectedRoute.jsx`
- `src/components/layouts/Navbar.jsx`
- `src/pages/Login.jsx`
- `src/pages/Register.jsx`
- `src/pages/ChangePassword.jsx`

## Tasks
1. Implement auth request/response models and services for login, register, change password, and logout.
2. Implement auth state management in Blazor and wire it into DI.
3. Recreate protected admin routing behavior so unauthenticated access redirects to login.
4. Recreate navbar behavior for authenticated vs unauthenticated states.
5. Attach bearer tokens to authorized requests.
6. Mirror the current contract behavior exactly unless a correction is intentionally made and documented.
7. If you correct any auth inconsistency from the React implementation, record the old behavior, the new behavior, and the reason in:
   - `docs/blazor-migration/current-state-baseline.md`
   - `docs/blazor-migration/migration-backlog.md`
8. Document auth test coverage and edge cases in `docs/blazor-migration/phase-gates.md`.

## Constraints
- Do not change backend endpoints without approval.
- Do not add refresh persistence unless it is explicitly required for parity or approved as a correction.
- Error states must be user-visible, not console-only.

## Gate 2 Checklist
1. Login works.
2. Register works.
3. Logout clears auth state.
4. Change password behavior is implemented and any contract uncertainty is documented.
5. Unauthorized admin navigation redirects to login.
6. Navbar correctly reflects auth state.
7. All auth-related deferments are logged.

## Required Output Contract
Return exactly:
1. Phase Summary
2. Work Completed
3. Validation Evidence
4. Gate Checklist
5. Gate Decision (PASS/FAIL)
6. Deferred Items
7. Next Action
