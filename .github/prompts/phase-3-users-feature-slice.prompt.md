# Phase 3 Copilot Prompt: Users Feature Slice

You are implementing the users vertical slice in Blazor for a React migration.

## Goal
Deliver parity for users list, details, and delete workflows.

## Tasks
1. Build users API client methods for:
   - get users list
   - get user details
   - delete user
2. Build users UI:
   - users table/list page
   - user details page
   - delete confirmation flow
3. Implement loading, empty, and error states.
4. Preserve current route patterns and navigation behavior.
5. Ensure actions requiring auth use bearer token.
6. Add minimal componentization for reuse and maintainability.

## Constraints
- Match current API contracts and route behavior.
- Keep UI parity functional before visual polish.
- Avoid introducing unrelated architecture changes.

## Deliverables
1. Users feature pages/components.
2. Users API service methods.
3. Verified behavior checklist for users workflows.
4. Brief notes on any parity gaps.

## Output Format
Return:
1. What was implemented
2. Files changed
3. Validation against parity checklist
4. Remaining gaps
