# Phase 1 Copilot Prompt: Scaffold Shell and Routing

You are implementing Phase 1 of a migration from React + Vite to ASP.NET Blazor.

## Goal
Set up a Blazor app shell with route structure equivalent to the current frontend.

## Tasks
1. Scaffold an ASP.NET Blazor Web App project for SPA-like interactivity.
2. Create shared layout components for:
   - top navbar
   - collapsible sidebar
   - main content area
3. Implement route pages for:
   - /admin/home
   - /admin/users
   - /admin/series
   - /login
   - /register
   - /changepassword
4. Preserve current navigation intent and section hierarchy.
5. Add placeholder content for each page where feature logic is not yet implemented.

## Constraints
- Keep this phase focused on shell and routing only.
- Do not implement full CRUD or auth persistence yet.
- Keep naming consistent and migration-friendly.

## Deliverables
1. Working Blazor app shell.
2. Route map matching existing app intent.
3. Basic navigation components with active-link states.
4. Short implementation notes listing what is intentionally deferred.

## Output Format
Return:
1. Files created/updated
2. Route parity notes
3. Deferred items for next phase
