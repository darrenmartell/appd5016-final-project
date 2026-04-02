# Target Blazor Architecture

This document records the intended Blazor project structure and architectural choices for the migration.

## Project Location

- Recreate the missing project at `blazor-migration/BlazorMigration.csproj`.
- Reason: `appd5016-final-project.sln` already references this exact path.

## Starting Point Used

- The migration used a Blazor Web App rather than an older Blazor Server or standalone WebAssembly template.
- The chosen structure supports nested layouts, routeable components, forms, and DI-friendly API services.
- Current Blazor Web App guidance was used during scaffolding and migration planning.

## Initial Rendering Strategy

- Default to the simplest Blazor Web App setup that supports SPA-like interactivity for the migrated pages.
- Avoid adding extra client projects or browser persistence unless the later phases require them for parity.
- Because the current React app does not persist auth across full refreshes, in-memory auth state is acceptable as the initial parity target.
- The app uses the .NET 10 Blazor Web App template with interactive server rendering applied at the router so the shell can support sidebar collapse and search interactions without introducing a separate client project.

## Final Blazor Structure

- `Components/Layout/MainLayout.razor`: public layout with shared navbar
- `Components/Layout/AdminLayout.razor`: admin shell with navbar, collapsible sidebar, and content region
- `Components/Layout/Navbar.razor`: shared top navigation and series search input
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
- `Components/Pages/UserDetails.razor`: `/admin/users/{id}/details`
- `Components/Pages/DeleteUser.razor`: `/admin/users/{id}/delete`
- `Components/Pages/SeriesDetails.razor`: `/admin/series/{id}/details`
- `Components/Pages/AddSeries.razor`: `/admin/series/add`
- `Components/Pages/UpdateSeries.razor`: `/admin/series/{id}/update`
- `Components/Pages/DeleteSeries.razor`: `/admin/series/{id}/delete`
- `Components/Series/SeriesEditor.razor`: reusable series add/update form component
- `Services/Users/*`: users API integration and delete behavior
- `Services/Series/*`: series API integration, search state, and mutation behavior

## Feature Mapping

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

## Architectural Notes

1. `HttpClient` is registered through a named backend client configured from `ApiOptions`.
2. Route protection uses Blazor authorization patterns and redirect-to-login rendering instead of React route wrappers.
3. Forms preserve the documented validation behavior except where the deployed backend required an approved correction.
4. Series form mapping remains explicit because it contains the most payload-shaping logic.

## Completed Deliverables

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