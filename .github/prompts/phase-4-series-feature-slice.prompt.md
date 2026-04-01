# Phase 4 Copilot Prompt: Series Feature Slice

You are executing Phase 4 of this repo's migration from React + Vite to ASP.NET Blazor.

## Scope
Deliver the full series slice in Blazor, including the list, details, add, update, and delete flows.

## React Source Of Truth
- `src/components/series/SeriesTable.jsx`
- `src/components/series/SeriesDetails.jsx`
- `src/components/series/SeriesForm.jsx`
- `src/components/series/DeleteSeries.jsx`
- `src/pages/Series.jsx`
- `src/pages/Dashboard.jsx`
- `src/components/layouts/AdminLayout.jsx`

## Tasks
1. Implement the series data service around the current `/series` API usage.
2. Recreate list and details behavior, including the dashboard dependency on series data.
3. Recreate add and update forms with parity for:
   - core scalar fields
   - tag-array style inputs
   - ratings object fields
   - dynamic episode rows
4. Recreate delete behavior.
5. Preserve current submit transformations unless a correction is explicitly documented:
   - flatten `{ value }` arrays to `string[]`
   - convert numeric fields with `Number(...)`
   - convert blank ratings to `null`
   - renumber episodes sequentially on submit
6. Preserve route patterns:
   - `/admin/series`
   - `/admin/series/{id}/details`
   - `/admin/series/add`
   - `/admin/series/{id}/update`
   - `/admin/series/{id}/delete`
7. Implement validation and user-visible failure states.
8. Update payload parity notes and workflow evidence in `docs/blazor-migration/phase-gates.md`.
9. Update `docs/blazor-migration/migration-backlog.md` with any remaining parity or UX deferments.

## Constraints
- Do not change endpoint shapes casually.
- Prioritize behavior and payload parity over visual polish.
- Keep the series form mapping explicit and testable.

## Gate 4 Checklist
1. Series list renders.
2. Series details renders.
3. Add works.
4. Update works.
5. Delete works.
6. Form payloads match the documented baseline.
7. Validation and submission error feedback exist.
8. Known limitations are documented.

## Required Output Contract
Return exactly:
1. Phase Summary
2. Work Completed
3. Validation Evidence
4. Gate Checklist
5. Gate Decision (PASS/FAIL)
6. Deferred Items
7. Next Action
