# API Migration Risk Log (Phase 0)

## Usage

This risk log is maintained through phased migration. Update status and mitigation notes at each gate.

Status values:
- Open
- Monitoring
- Mitigated
- Accepted

## Risks

1. R-001: Route prefix mismatch
- Description: Current ASP.NET scaffold exposes /api/* routes while frontend expects root routes (auth/*, users/*, series/*).
- Impact: Frontend calls fail after cutover.
- Likelihood: High
- Status: Open
- Mitigation: Implement route parity first; optionally add temporary dual-route aliases.

2. R-002: Identifier field mismatch (_id vs id)
- Description: Frontend strongly expects _id in series payload and can consume _id or id for users/auth.
- Impact: Parsing failures, broken edit/delete flows.
- Likelihood: High
- Status: Open
- Mitigation: Preserve _id in response contracts (or emit both id and _id during transition).

3. R-003: JSON naming mismatch (snake_case)
- Description: Series contracts use snake_case fields; default ASP.NET serializers often output camelCase/PascalCase unless configured.
- Impact: Frontend model binding issues.
- Likelihood: High
- Status: Open
- Mitigation: Configure explicit JSON property names or serializers to preserve snake_case contract.

4. R-004: Auth payload compatibility drift
- Description: Frontend auth parsing expects access_token plus user identity fields.
- Impact: Login/register appears successful but user session is not established.
- Likelihood: Medium
- Status: Open
- Mitigation: Keep response payload contract stable; add contract tests.

5. R-005: Missing change-password endpoint parity
- Description: Frontend uses PATCH /auth/{id}/changepassword but source imported API lacks this endpoint.
- Impact: Change password flow fails after API migration unless addressed.
- Likelihood: High
- Status: Open
- Mitigation: Decide in Phase 5 whether to implement endpoint, disable UI path, or document unsupported behavior.

6. R-006: Mongo id format differences
- Description: Source API validates Mongo ObjectId path params; scaffold currently uses string Guid-like ids for series document.
- Impact: Behavior drift in validation and client-side assumptions.
- Likelihood: Medium
- Status: Open
- Mitigation: Standardize id strategy early (ObjectId-compatible preferred for parity) and enforce consistent validation rules.

7. R-007: Validation behavior drift
- Description: Source API uses strict ValidationPipe and class-validator constraints.
- Impact: Requests accepted/rejected differently in migrated API.
- Likelihood: High
- Status: Open
- Mitigation: Mirror constraints via DataAnnotations/custom validators and return consistent 400 problem responses.

8. R-008: Error body shape drift
- Description: Source emits specific 400/500 bodies for mongoose exceptions and framework validation failures.
- Impact: Frontend may show generic failures; debugging parity issues becomes harder.
- Likelihood: Medium
- Status: Open
- Mitigation: Introduce ProblemDetails strategy and mapping layer for critical error shapes.

9. R-009: CORS regression
- Description: Source API includes explicit allowed origins, credentials, headers, methods.
- Impact: Browser requests blocked despite functional endpoints.
- Likelihood: Medium
- Status: Open
- Mitigation: Carry equivalent CORS policy into ASP.NET and validate from frontend origin(s).

10. R-010: Data access technology mismatch
- Description: Current scaffold uses MongoDB.EntityFrameworkCore while source behavior maps naturally to MongoDB document operations.
- Impact: Complex patch/update parity may be harder to achieve; higher implementation risk.
- Likelihood: Medium
- Status: Open
- Mitigation: Evaluate repository implementation path in Phase 1; use MongoDB.Driver if needed for parity.

11. R-011: Security posture conflict with parity
- Description: Source has public GET /users and GET /users/{id}; tightening this during migration changes behavior.
- Impact: Potential frontend or integration breakage.
- Likelihood: Medium
- Status: Open
- Mitigation: Keep parity first, harden security in a post-parity phase with explicit approval.

12. R-012: Insufficient regression tests during migration
- Description: API scaffold currently has no endpoint parity tests.
- Impact: Silent regressions between phases.
- Likelihood: High
- Status: Open
- Mitigation: Add integration and contract tests by Phase 6, plus smoke checks each phase.

## Decisions Needed

1. Keep parity route style at root only, or support root + /api aliases during transition?
2. Response identity strategy: _id only, or both _id and id during migration window?
3. Implement change-password endpoint now or defer with explicit documented limitation?
4. Keep MongoDB.EntityFrameworkCore or switch repository internals to MongoDB.Driver for parity?

## Phase 0 Exit Criteria

1. Contract baseline exists and covers all required routes.
2. Risks are documented with mitigation paths.
3. Open decisions are explicitly listed for approval in upcoming phases.
