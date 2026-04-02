# Phase 6 Parity Checklist

Date: 2026-04-02

## Automated Integration Coverage

Test project:
- tests/SeriesCatalog.WebApi.IntegrationTests

Covered scenarios:
1. Register response contract includes access_token and _id.
2. Login fails with invalid credentials (401).
3. Users delete requires JWT (401 without token, 200 with token).
4. Series root CRUD path works with JWT and expected response contract fields.
5. Change-password compatibility endpoint updates credentials successfully.
6. Series invalid payload returns validation problem details.

## Manual Parity Checks Completed

1. Root auth routes:
- POST /auth/register: verified 201 with identity and token fields.
- POST /auth/login: verified 200 success and 401 invalid credentials.

2. Root users routes:
- GET /users: verified returns list and 404 when empty.
- GET /users/{id}: verified 200 for existing user.
- DELETE /users/{id}: verified JWT required and deletion behavior.

3. Root series routes:
- GET /series and GET /series/{id}: verified read behavior.
- POST/PUT/PATCH/DELETE /series: verified JWT enforcement and CRUD behavior.
- Invalid id handling: verified 400 on malformed id.

4. Compatibility shim:
- PATCH /auth/{id}/changepassword: verified 401 without token, 400 on invalid password, 200 on success.

5. Legacy compatibility:
- POST /api/series remains functional for scaffold compatibility.

## Open Items

1. Add broader contract tests for every error body variation if strict parity snapshots are required.
2. Consider adding CI workflow execution for this integration test project.

## Exit Assessment

No unresolved critical parity gaps were observed in Phase 6 checks.
