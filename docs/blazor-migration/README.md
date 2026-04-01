# Blazor Migration Runbook

This folder contains the repo-specific documentation required to migrate the current React + Vite frontend to a Blazor Web App in gated phases.

## Purpose

Use these files as the migration control plane:

- `current-state-baseline.md`: frozen description of how the React app behaves today
- `target-blazor-architecture.md`: agreed Blazor project shape and technical decisions
- `phase-gates.md`: evidence log and gate checklist outcomes by phase
- `migration-backlog.md`: risks, uncertainties, and deferred work
- `cutover-and-rollback.md`: final release and fallback plan

## Phase Order

1. Phase 0: baseline and freeze
2. Phase 1: scaffold shell and routing
3. Phase 2: auth and guards
4. Phase 3: users slice
5. Phase 4: series slice
6. Phase 5: stabilization and cutover

## Repo-Specific Migration Rules

1. Preserve the React app in `src/` until Phase 5 PASS.
2. Recreate the missing Blazor project at `blazor-migration/BlazorMigration.csproj` because `appd5016-final-project.sln` already references that location.
3. Treat the React files as the current behavior source of truth.
4. Record every contract inconsistency or approved behavior correction in `migration-backlog.md`.
5. Before Phase 1 or later code work, retrieve current Blazor Web App guidance with an MCP documentation source.

## Core React Sources

- Routing: `src/routes/AppRoutes.jsx`, `src/routes/ProtectedRoute.jsx`
- Layout: `src/App.jsx`, `src/components/layouts/AdminLayout.jsx`, `src/components/layouts/Navbar.jsx`, `src/components/layouts/Sidebar.jsx`
- Auth: `src/context/AuthContext.jsx`, `src/pages/Login.jsx`, `src/pages/Register.jsx`, `src/pages/ChangePassword.jsx`
- Users: `src/pages/Users.jsx`, `src/components/users/*`
- Series: `src/pages/Series.jsx`, `src/pages/Dashboard.jsx`, `src/components/series/*`

## Expected Outcome

By the end of Phase 5, the Blazor app should replace the React frontend with documented parity for auth, dashboard, users, and series flows, plus a clear rollback path.