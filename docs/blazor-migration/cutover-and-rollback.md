# Cutover And Rollback

Complete this file in Phase 5.

## Cutover Preconditions

1. Phase 0 through Phase 4 are PASS.
2. Final parity checklist is complete.
3. Build and run instructions for the Blazor app are documented.
4. Residual risks are accepted.

## Planned Cutover Steps

1. Confirm the Blazor app builds in the expected environment.
2. Confirm environment configuration and API base URL settings.
3. Confirm auth, users, series, and dashboard parity.
4. Switch the frontend entry point or deployment artifact from React to Blazor.
5. Smoke test the critical flows after deployment.

## Rollback Triggers

1. Login or register failures in the target environment.
2. Broken protected-route behavior.
3. Users or series data operations failing.
4. A build or hosting issue that blocks the migrated UI.

## Rollback Steps

1. Revert the deployment to the last known-good React frontend.
2. Restore prior frontend hosting configuration if it changed.
3. Confirm API connectivity and auth flows against the restored frontend.
4. Log the failure cause in `migration-backlog.md` and reopen the relevant phase gate.

## Post-Cutover Monitoring

1. Login and register success rate.
2. Route protection behavior.
3. Users delete and series mutation flows.
4. Client-visible form validation and API error handling.