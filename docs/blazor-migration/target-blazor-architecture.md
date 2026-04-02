# Target Blazor Architecture

This document records the intended Blazor project structure and architectural choices for the migration.

## Project Location

- Recreate the missing project at `blazor-migration/BlazorMigration.csproj`.
- Reason: `appd5016-final-project.sln` already references this exact path.

## Recommended Starting Point

- Scaffold a Blazor Web App rather than an older Blazor Server or standalone WebAssembly template.
- Favor a structure that supports nested layouts, routeable components, forms, and DI-friendly API services.
- Retrieve current Blazor Web App documentation with MCP before scaffolding or changing architectural decisions.

## Initial Rendering Strategy

- Default to the simplest Blazor Web App setup that supports SPA-like interactivity for the migrated pages.
- Avoid adding extra client projects or browser persistence unless the later phases require them for parity.
- Because the current React app does not persist auth across full refreshes, in-memory auth state is acceptable as the initial parity target.
- Phase 1 uses the .NET 10 Blazor Web App template with interactive server rendering applied at the router so the shell can support sidebar collapse and future auth and search interactions without introducing a separate client project.

## Implemented Phase 1 Shell Structure

- `Components/Layout/MainLayout.razor`: public layout with shared navbar
- `Components/Layout/AdminLayout.razor`: admin shell with navbar, collapsible sidebar, and content region
- `Components/Layout/Navbar.razor`: shared top navigation and placeholder search box
- `Components/Layout/Sidebar.razor`: collapsible admin navigation
- `Components/Layout/SidebarItem.razor`: active-link item component
- `Components/Shared/PhasePlaceholder.razor`: placeholder panel used by scaffolded pages
- `Components/Pages/Index.razor`: redirect from `/` to `/admin/home`
- `Components/Pages/AdminRedirect.razor`: redirect from `/admin` to `/admin/home`
- `Components/Pages/Home.razor`: `/admin/home`
- `Components/Pages/Users.razor`: `/admin/users`
- `Components/Pages/Series.razor`: `/admin/series`
- `Components/Pages/Login.razor`: `/login`
- `Components/Pages/Register.razor`: `/register`
- `Components/Pages/ChangePassword.razor`: `/changepassword`

## Proposed Feature Mapping

| Current React Area | Current Source | Target Blazor Area |
| --- | --- | --- |
| App shell | `src/App.jsx`, `src/components/layouts/AdminLayout.jsx` | shared layout and routed admin shell components |
| Navbar | `src/components/layouts/Navbar.jsx` | shared navigation component |
| Sidebar | `src/components/layouts/Sidebar.jsx`, `src/components/layouts/SidebarItem.jsx` | shared sidebar/nav menu components |
| Routing | `src/routes/AppRoutes.jsx` | Blazor routeable pages and redirects |
| Auth state | `src/context/AuthContext.jsx` | DI auth service + `AuthenticationStateProvider` |
| Users slice | `src/pages/Users.jsx`, `src/components/users/*` | users feature components/services |
| Series slice | `src/pages/Series.jsx`, `src/components/series/*` | series feature components/services |
| Dashboard | `src/pages/Dashboard.jsx` | dashboard page using series search/filter state |

## Expected Blazor Concerns

1. `HttpClient` must be registered in a way that works for the chosen Blazor render mode.
2. Route protection should use Blazor authorization patterns instead of React route wrappers.
3. Forms should preserve current validation behavior before any UX improvements.
4. Series form mapping should be implemented explicitly because it contains the most payload-shaping logic.

## Phase Deliverables

### Phase 1

- Working Blazor shell at `blazor-migration/`
- Route skeleton for all current paths
- Shared layout and navigation components

### Phase 2

- Auth services and route protection

### Phase 3

- Users slice

### Phase 4

- Series slice and dashboard parity

### Phase 5

- Stabilization, cutover, and rollback documentation