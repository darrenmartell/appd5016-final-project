# Current State Baseline

This document freezes the current React behavior that the Blazor migration must either preserve or explicitly correct with documentation.

## Route And Auth Matrix

| Route | Current React Owner | Access | Notes |
| --- | --- | --- | --- |
| `/` | `src/routes/AppRoutes.jsx` | Public redirect | Redirects to `/admin/home` |
| `/admin` | `src/routes/AppRoutes.jsx` | Public redirect | Redirects to `/admin/home` |
| `/admin/home` | `src/pages/Dashboard.jsx` | Public in current routing | Dashboard lives inside admin shell but is not behind `ProtectedRoute` |
| `/admin/users` | `src/pages/Users.jsx` + `src/components/users/UserTable.jsx` | Public in current routing | Lists users from `/users` |
| `/admin/users/:id/details` | `src/components/users/UserDetails.jsx` | Public in current routing | Reads from cached users collection |
| `/admin/users/:id/delete` | `src/components/users/DeleteUser.jsx` | Protected | Wrapped in `ProtectedRoute` |
| `/admin/series` | `src/pages/Series.jsx` + `src/components/series/SeriesTable.jsx` | Public in current routing | Lists series from `/series` |
| `/admin/series/:id/details` | `src/components/series/SeriesDetails.jsx` | Public in current routing | Reads from cached series collection |
| `/admin/series/add` | `src/components/series/SeriesForm.jsx` | Protected | Create flow |
| `/admin/series/:id/update` | `src/components/series/SeriesForm.jsx` | Protected | Edit flow |
| `/admin/series/:id/delete` | `src/components/series/DeleteSeries.jsx` | Protected | Delete flow |
| `/login` | `src/pages/Login.jsx` | Public | Uses React Query mutation |
| `/register` | `src/pages/Register.jsx` | Public | Uses React Query mutation |
| `/changepassword` | `src/pages/ChangePassword.jsx` | Public in current routing | Page itself is not behind `ProtectedRoute`, but call requires auth context |

## Shell And Data Ownership

- `src/components/layouts/AdminLayout.jsx` owns the shell layout and fetches `/series` into outlet context.
- `src/pages/Users.jsx` fetches `/users` into outlet context.
- `src/pages/Series.jsx` only forwards outlet context.
- `src/pages/Dashboard.jsx` depends on the shell-wide series context and client-side search text from the navbar.
- `src/components/layouts/Navbar.jsx` shows login/register when unauthenticated and shows a dropdown with logout when authenticated.

## Auth Model Today

- Auth state is stored only in React context in `src/context/AuthContext.jsx`.
- `isAuthenticated` is `!!token`.
- No token persistence exists across full page refreshes.
- Logout clears token and user in memory only.
- `ProtectedRoute` redirects unauthenticated users to `/login`.

## API Contract Summary

### Configuration

- API base URL comes from `src/config.js`.
- Current default fallback is `http://localhost:3000`.

### Auth Endpoints

| Flow | Method | Path | Request Body | Success Expectations | Failure Handling |
| --- | --- | --- | --- | --- | --- |
| Login | `POST` | `/auth/login` | `{ email, password }` | Response is expected to include `email`, `_id`, and `access_token` | Sets root form error message |
| Register | `POST` | `/auth/register` | `{ firstName, lastName, email, password }` | Response is expected to include `email`, `_id`, and `accessToken` | Sets root form error message and clears user |
| Change Password | `PATCH` | `/auth/${user._id}/changepassword` | Raw JSON string for `newPassword` | Success navigates to `/admin/users` | Sets root form error message |

### Users Endpoints

| Flow | Method | Path | Auth Header | Notes |
| --- | --- | --- | --- | --- |
| List users | `GET` | `/users` | No | Loaded in `src/pages/Users.jsx` |
| User details | none additional | cached collection | No | Selected from the already-loaded users list |
| Delete user | `DELETE` | `/users/:id` | Yes | Prevents deleting the logged-in user in the UI |

### Series Endpoints

| Flow | Method | Path | Auth Header | Notes |
| --- | --- | --- | --- | --- |
| List series | `GET` | `/series` | No | Loaded in `src/components/layouts/AdminLayout.jsx` |
| Series details | none additional | cached collection | No | Selected from the already-loaded series list |
| Create series | `POST` | `/series` | Yes | Payload transformed before submit |
| Update series | `PUT` | `/series/:id` | Yes | Payload transformed before submit |
| Delete series | `DELETE` | `/series/:id` | Yes | Success invalidates `seriesCache` |

## Validation Rules And Form Behavior

### Login

- Email must match HTML5 email format.
- Password must match the regex requiring:
  - at least 8 characters
  - uppercase
  - lowercase
  - number
  - special character
- Root error message: `Error logging in. Please check your credentials and try again.`

### Register

- `firstName` is required.
- `lastName` is required.
- `email` must match HTML5 email format.
- `password` must match the same regex as login.
- `confirmPassword` must match `password`.
- Root error message: `Error registering. Please check your credentials and try again.`

### Change Password

- `password`, `newPassword`, and `confirmPassword` all use the same password regex.
- `confirmPassword` must match `newPassword`.
- Root error message: `Error changing password. Please check your credentials and try again.`

### Series Form

- `title` is the only required field enforced in the UI.
- Tag inputs store temporary values as `{ value }` items and flatten to `string[]` on submit.
- `runtime_minutes` and `released_year` are converted to numbers.
- Ratings fields convert blank strings to `null`; non-blank values are converted to numbers.
- Episodes are submitted as objects with:
  - `episode_number` set from array order using `i + 1`
  - `episode_title`
  - `runtime_minutes` converted to a number

## Known Risks And Inconsistencies

1. Login expects `access_token` while register expects `accessToken`.
2. Change password reads `user._id`, but login/register store `user.id`. This is likely a defect or unverified contract assumption.
3. The change-password request body is a raw JSON string, not an object, and must be verified before normalization.
4. The `/changepassword` route is public in routing even though the page requires auth context to function.
5. The dashboard, users list, and series list are publicly reachable in the current route tree even though they live under `/admin`.
6. `test-api-server/routes.json` and the visible sample data do not match the app's current domain model, so mock-server usage must be revalidated.
7. The Blazor project referenced by the solution is currently missing.

## Migration Success Criteria

Phase gates should measure the migration against these expectations:

1. Route parity is preserved or any corrections are explicitly documented and approved.
2. Auth flows behave the same or are corrected intentionally with a recorded reason.
3. Users and series payloads match the documented current behavior unless a contract correction is approved.
4. The migrated app has user-visible loading, empty, validation, and error states for the main flows.
5. Cutover only happens after the parity checklist passes and rollback steps exist.