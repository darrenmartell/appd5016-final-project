# Blazor Migration Runbook

This folder now serves as the repo-local migration record for the completed move from the React + Vite frontend to the Blazor Web App.

## Purpose

Use these files as the migration control plane and historical record:

- `current-state-baseline.md`: frozen description of how the React app behaves today
- `target-blazor-architecture.md`: agreed Blazor project shape and technical decisions
- `phase-gates.md`: evidence log and gate checklist outcomes by phase
- `migration-backlog.md`: residual risks, uncertainties, and approved corrections
- `cutover-and-rollback.md`: final release and fallback plan

## Phase Order

1. Phase 0: baseline and freeze
2. Phase 1: scaffold shell and routing
3. Phase 2: auth and guards
4. Phase 3: users slice
5. Phase 4: series slice
6. Phase 5: stabilization and cutover

## Repo-Specific Migration Rules

1. The React app remains in `src/` as the repo-local fallback path after Phase 5 PASS.
2. Recreate the missing Blazor project at `blazor-migration/BlazorMigration.csproj` because `appd5016-final-project.sln` already references that location.
3. Treat the React files as the current behavior source of truth.
4. Record every contract inconsistency or approved behavior correction in `migration-backlog.md`.
5. Use the phase gates and backlog as the source of truth for what was preserved, corrected, or deferred.

## Core React Sources

- Routing: `src/routes/AppRoutes.jsx`, `src/routes/ProtectedRoute.jsx`
- Layout: `src/App.jsx`, `src/components/layouts/AdminLayout.jsx`, `src/components/layouts/Navbar.jsx`, `src/components/layouts/Sidebar.jsx`
- Auth: `src/context/AuthContext.jsx`, `src/pages/Login.jsx`, `src/pages/Register.jsx`, `src/pages/ChangePassword.jsx`
- Users: `src/pages/Users.jsx`, `src/components/users/*`
- Series: `src/pages/Series.jsx`, `src/pages/Dashboard.jsx`, `src/components/series/*`

## Expected Outcome

Phase 5 is now PASS. The Blazor app replaces the React frontend for ongoing work, with documented parity for auth, dashboard, users, and series flows plus a clear repo-local rollback path.