# Migration Backlog

Track every risk, defect, uncertainty, and approved deferment here.

| ID | Description | Phase Introduced | Severity | Owner | Resolution Target Phase | Status |
| --- | --- | --- | --- | --- | --- | --- |
| BLZ-001 | `appd5016-final-project.sln` references `blazor-migration/BlazorMigration.csproj`, but the project folder is missing. | 0 | High | Migration agent | 1 | Closed |
| BLZ-002 | Login expects `access_token`, while register expects `accessToken`. Confirm whether backend intentionally returns different token property names. | 0 | High | Migration agent | 2 | Open |
| BLZ-003 | Change password route uses `user._id`, but auth context stores `user.id`. Verify whether current flow is broken or relies on a different response shape. | 0 | High | Migration agent | 2 | Open |
| BLZ-004 | Change password sends a raw JSON string instead of an object. Verify the backend contract before normalizing. | 0 | High | Migration agent | 2 | Open |
| BLZ-005 | `/changepassword` is public in routing even though it requires auth context to function. Decide whether to preserve or correct during Phase 2. | 0 | Medium | Migration agent | 2 | Open |
| BLZ-006 | Current `/admin/home`, `/admin/users`, and `/admin/series` routes are publicly reachable. Decide whether parity requires preserving this or correcting it in Blazor. | 0 | Medium | Migration agent | 2 | Open |
| BLZ-007 | `test-api-server/routes.json` and visible sample data do not line up with the current app domain. Revalidate local test strategy before relying on the mock server. | 0 | Medium | Migration agent | 5 | Open |
| BLZ-008 | Phase 1 only scaffolds placeholder pages for login, register, users, series, and change password. Real auth and data wiring are intentionally deferred to Phases 2 through 4. | 1 | Low | Migration agent | 4 | Open |