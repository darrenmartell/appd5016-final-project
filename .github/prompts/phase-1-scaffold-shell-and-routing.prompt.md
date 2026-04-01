# Phase 1 Copilot Prompt: Scaffold Shell and Routing

You are executing Phase 1 of this repo's migration from React + Vite to ASP.NET Blazor.

## Scope
Recreate the app shell and route structure in Blazor without yet completing the auth flows or the feature API integrations.

## Prerequisites
1. Read `docs/blazor-migration/current-state-baseline.md`.
2. Read `docs/blazor-migration/target-blazor-architecture.md`.
3. Retrieve current Blazor Web App documentation with an MCP documentation source before scaffolding.

## Source Files To Translate
- `src/App.jsx`
- `src/components/layouts/AdminLayout.jsx`
- `src/components/layouts/Navbar.jsx`
- `src/components/layouts/Sidebar.jsx`
- `src/components/layouts/SidebarItem.jsx`
- `src/routes/AppRoutes.jsx`
- `src/pages/Dashboard.jsx`
- `src/pages/Users.jsx`
- `src/pages/Series.jsx`
- `appd5016-final-project.sln`

## Tasks
1. Recreate the missing project at `blazor-migration/BlazorMigration.csproj` so the existing solution reference becomes valid again.
2. Scaffold a Blazor Web App suitable for SPA-like interactivity.
3. Create the shared shell that maps the current React layout concepts into Blazor components:
   - top navbar
   - collapsible sidebar
   - main content area
   - nested admin layout
4. Implement routeable pages for:
   - `/admin/home`
   - `/admin/users`
   - `/admin/series`
   - `/login`
   - `/register`
   - `/changepassword`
5. Preserve the redirect behavior from `/` and `/admin` to `/admin/home`.
6. Add placeholder content where later phase logic is intentionally deferred.
7. Update `docs/blazor-migration/target-blazor-architecture.md` with the final folder and component layout you chose.
8. Update `docs/blazor-migration/migration-backlog.md` with any deferred auth or feature behavior.

## Constraints
- Do not implement real CRUD behavior in this phase.
- Do not implement final auth persistence in this phase.
- Do not delete or disable the React app yet.
- Keep routing names aligned with the current app unless a documented correction is approved.

## Gate 1 Checklist
1. `blazor-migration/BlazorMigration.csproj` exists and the solution reference is valid.
2. The Blazor project builds.
3. Layout components exist for navbar, sidebar, and admin content shell.
4. All required routes exist and navigation works.
5. Deferred logic is explicitly tracked in the migration backlog.

## Required Output Contract
Return exactly:
1. Phase Summary
2. Work Completed
3. Validation Evidence
4. Gate Checklist
5. Gate Decision (PASS/FAIL)
6. Deferred Items
7. Next Action
