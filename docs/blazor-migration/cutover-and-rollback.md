# Cutover And Rollback

This file records the repo-local cutover from the retained React frontend in `src/` to the migrated Blazor frontend in `blazor-migration/`.

## Cutover Preconditions

1. Phase 0 through Phase 4 are PASS.
2. Final parity checklist is complete.
3. Build and run instructions for the Blazor app are documented.
4. Residual risks are accepted.
5. The React frontend remains available in-repo as a fallback path.

## Final Parity Checklist

| Area | Verification | Result |
| --- | --- | --- |
| Login | Public route renders and Phase 2 live backend validation passed | PASS |
| Register | Public route renders and Phase 2 live backend validation passed | PASS |
| Change password | Protected route behavior verified; backend gap remains formally blocked | PASS with accepted backend gap |
| Dashboard | Protected route behavior verified; series search and cards restored in Blazor | PASS |
| Users | List/details/delete implemented and validated in Phase 3 | PASS |
| Series | List/details/add/update/delete implemented and validated in Phase 4 | PASS |
| Protected routing | Final Phase 5 route matrix verified admin routes redirect to login content when unauthenticated | PASS |
| Build/run docs | Top-level README and migration docs updated for Blazor local run/config | PASS |
| Rollback path | React frontend preserved in `src/` with local run instructions | PASS |

## Run And Build Reference

### Blazor

1. Build the full solution:

```bash
dotnet build appd5016-final-project.sln
```

2. Run the Blazor app:

```bash
dotnet run --project blazor-migration/BlazorMigration.csproj
```

3. Default local URL:

```text
http://localhost:5204
```

4. Config source:

```text
blazor-migration/appsettings.json
blazor-migration/appsettings.Development.json
blazor-migration/Properties/launchSettings.json
```

### React Fallback

1. Install dependencies:

```bash
pnpm install
```

2. Run the React frontend:

```bash
pnpm run dev
```

## Planned Cutover Steps

1. Confirm `dotnet build appd5016-final-project.sln` succeeds from a clean checkout.
2. Confirm the Blazor app starts locally with `dotnet run --project blazor-migration/BlazorMigration.csproj`.
3. Confirm the configured API base URL in `blazor-migration/appsettings*.json` points to the intended backend.
4. Confirm the final route matrix still matches the migration gate expectations:
	- `/login` and `/register` are public
	- `/changepassword`, `/admin/home`, `/admin/users`, and `/admin/series` redirect unauthenticated users to login
5. Treat `blazor-migration/` as the repo’s primary frontend implementation for ongoing work.
6. Keep the React app in `src/` untouched until post-cutover monitoring is complete.
7. Smoke test the critical flows against the Blazor app:
	- login
	- register
	- users delete
	- series add/update/delete
	- dashboard search

## Rollback Triggers

1. Login or register failures in the target environment.
2. Broken protected-route behavior.
3. Users or series data operations failing.
4. A build or hosting issue that blocks the migrated UI.
5. Repeated validation failures tied to the documented backend gaps in `migration-backlog.md`.

## Rollback Steps

1. Stop using `blazor-migration/` as the active frontend implementation for the failing release candidate.
2. Resume local development and validation against the React frontend in `src/` using `pnpm run dev`.
3. Compare the failing Blazor behavior against the preserved React source-of-truth flow.
4. Log the failure cause in `migration-backlog.md`.
5. Reopen the relevant phase gate in `phase-gates.md` if the failure invalidates an accepted PASS decision.
6. Keep all Blazor code in place for targeted fixes instead of deleting it during rollback.

## Post-Cutover Monitoring

1. Login and register success rate.
2. Route protection behavior.
3. Users delete and series mutation flows.
4. Client-visible form validation and API error handling.
5. Series create and update validation behavior for the stricter deployed backend contract.

## Residual Risks

1. BLZ-007: the mock API folder is still not a trusted parity harness.
2. BLZ-010: no backend change-password route exists yet.
3. BLZ-011: the deployed series write contract is stricter than the original React submit transform and required a documented correction in Blazor.