# Phase 2 Copilot Prompt: Auth and Route Guards

You are implementing Phase 2 of a React-to-Blazor migration.

## Goal
Implement authentication and route protection equivalent to the current app behavior.

## Tasks
1. Create auth models and services for:
   - login
   - register
   - change password
   - logout
2. Implement JWT handling:
   - store and retrieve token
   - attach bearer token to authorized API calls
   - clear token and user state on logout
3. Implement a custom AuthenticationStateProvider (or equivalent) and wire it into DI.
4. Protect admin routes and redirect unauthorized users to login.
5. Recreate navbar auth behavior:
   - show login/register when unauthenticated
   - show user menu and logout when authenticated
6. Add basic error display patterns for auth failures.

## Constraints
- Match existing endpoint contracts.
- Avoid introducing backend API changes.
- Keep implementation testable and modular.

## Deliverables
1. Auth service and state provider implementation.
2. Guarded routes with redirect behavior.
3. Updated nav behavior based on auth state.
4. Validation notes and known auth edge cases.

## Output Format
Return:
1. Auth architecture summary
2. Files changed
3. Route protection behavior
4. Open issues and follow-ups
