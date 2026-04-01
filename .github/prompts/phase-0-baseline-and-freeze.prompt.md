# Phase 0 Copilot Prompt: Baseline and Freeze

You are helping migrate a React + Vite frontend to ASP.NET Blazor.

## Goal
Establish a reliable baseline of current behavior before migration work starts.

## Repository Context
- Frontend: React + Vite
- API base URL from environment config
- Core areas: auth, users, series, dashboard, change password

## Tasks
1. Create a parity checklist for all current user flows:
   - login
   - register
   - logout
   - dashboard access
   - users list/details/delete
   - series list/details/add/edit/delete
   - change password
2. Document current route map and protected routes.
3. Capture API contract expectations per endpoint:
   - request payload shape
   - response payload shape
   - auth requirements
   - error handling behavior
4. Identify current validation rules in forms and note edge cases.
5. Define migration success criteria for functional parity.

## Constraints
- Do not change production behavior in this phase.
- Prefer documentation artifacts over code changes.
- Keep findings specific to this repository.

## Deliverables
1. A markdown checklist that can be used during migration validation.
2. A route and auth matrix.
3. An API contract summary table.
4. A list of known risks and assumptions.

## Output Format
Return:
1. Summary
2. Checklist
3. Route/Auth matrix
4. API contract summary
5. Risks and assumptions
