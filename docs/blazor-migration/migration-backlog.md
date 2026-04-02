# Migration Backlog

Track every risk, defect, uncertainty, and approved deferment here.

| ID | Description | Phase Introduced | Severity | Owner | Resolution Target Phase | Status |
| --- | --- | --- | --- | --- | --- | --- |
| BLZ-001 | `appd5016-final-project.sln` references `blazor-migration/BlazorMigration.csproj`, but the project folder is missing. | 0 | High | Migration agent | 1 | Closed |
| BLZ-002 | Login expects `access_token`, while register expects `accessToken`. Live backend validation showed that both login and register return `access_token`. The Blazor auth service still accepts both token names for compatibility. | 0 | High | Migration agent | 2 | Closed |
| BLZ-003 | Change password route uses `user._id`, but auth context stores `user.id`. Live backend validation showed that auth responses use `_id`. The Blazor auth state now supports both values through `EffectiveId`. | 0 | High | Migration agent | 2 | Closed |
| BLZ-004 | Change password sends a raw JSON string instead of an object. The Blazor migration preserves that raw-string contract for parity. | 0 | High | Migration agent | 2 | Closed |
| BLZ-005 | `/changepassword` is public in routing even though it requires auth context to function. The Blazor migration corrects this by redirecting unauthenticated users to `/login`. | 0 | Medium | Migration agent | 2 | Closed |
| BLZ-006 | Current `/admin/home`, `/admin/users`, and `/admin/series` routes are publicly reachable. The Blazor migration corrects this by redirecting unauthenticated users to `/login`. | 0 | Medium | Migration agent | 2 | Closed |
| BLZ-007 | `test-api-server/routes.json` and visible sample data do not line up with the current app domain. Revalidate local test strategy before relying on the mock server. | 0 | Medium | Migration agent | 5 | Open |
| BLZ-008 | The users placeholder was replaced in Phase 3, but the series slice still remains deferred until Phase 4. | 1 | Low | Migration agent | 4 | Open |
| BLZ-009 | The backend API configured at `http://localhost:3000` was unreachable during initial Phase 2 validation. The app is now pointed at the deployed Vercel backend instead. | 2 | High | Migration agent | 2 | Closed |
| BLZ-010 | Live validation against `https://assignment2-restapi-darrenmartell-h.vercel.app` confirmed register and login, but no working change-password endpoint was found for the tested route and method variants. The frontend now treats change password as a formally blocked flow until the backend route exists. | 2 | High | Migration agent | 5 | Open |