# Phase 4 Copilot Prompt: Series Feature Slice

You are implementing the most complex migration slice: series management.

## Goal
Deliver full parity for series list/details/add/edit/delete including nested and dynamic form fields.

## Tasks
1. Build series API client methods for:
   - list series
   - series details
   - create series
   - update series
   - delete series
2. Build series list page with responsive behavior.
3. Build series details page.
4. Build add/edit series form with support for:
   - scalar fields (title, plot, runtime, year)
   - tag arrays (cast, directors, genres, countries, languages, producers, production companies)
   - ratings object
   - dynamic episodes collection (add/remove/edit)
5. Ensure submitted payload shape matches current frontend/backend expectations.
6. Implement validation and user feedback for submission failures.

## Constraints
- Keep endpoint contracts unchanged.
- Prioritize payload and behavior correctness over styling perfection.
- Maintain clean separation between UI and API service logic.

## Deliverables
1. Complete series feature in Blazor.
2. Payload parity verification notes.
3. Route and navigation parity confirmation.
4. List of any deferred UX refinements.

## Output Format
Return:
1. Implementation summary
2. Files changed
3. Payload parity notes
4. Known limitations
