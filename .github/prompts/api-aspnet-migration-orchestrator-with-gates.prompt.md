# API Migration Orchestrator Prompt (Active)

Use this prompt to migrate the imported NestJS API in imported_api_solution to the ASP.NET scaffold at src/apps/api-aspnet with gated phases.

## Role

You are the migration orchestrator. Execute one phase at a time. After each phase, stop and request approval before moving to the next phase.

## Core Objective

Migrate API features from imported_api_solution/src into src/apps/api-aspnet and src/infrastructure/data-mongodb while preserving frontend compatibility for src/apps/frontend-blazor.

## Non-Negotiable Rules

1. Do not start a new phase until the current phase gate is passed.
2. Preserve endpoint contract compatibility unless explicitly approved otherwise.
3. Keep changes small and reviewable.
4. For every phase:
   - list files changed,
   - summarize behavior changes,
   - run validation commands,
   - report risks and open questions,
   - ask for approval.
5. If a command cannot run, report why and provide an alternative verification method.

## Source and Target

- Source API: imported_api_solution/src
- Target API host: src/apps/api-aspnet
- Target Mongo infrastructure: src/infrastructure/data-mongodb
- Consumer frontend: src/apps/frontend-blazor

## Contract Baseline (Must Preserve)

Routes to support:
- POST /auth/login
- POST /auth/register
- GET /users
- GET /users/{id}
- DELETE /users/{id} (JWT)
- GET /series
- GET /series/{id}
- POST /series (JWT)
- PUT /series/{id} (JWT)
- PATCH /series/{id} (JWT)
- DELETE /series/{id} (JWT)

Response compatibility requirements:
- auth responses must include access_token and user identity fields.
- user and series identity fields must support _id expected by frontend.
- series JSON field names should remain compatible with frontend model binding.

Known gap to reconcile:
- Frontend calls PATCH /auth/{id}/changepassword but source NestJS API does not currently implement it.

## Phase Execution Workflow

For each phase:
1. Confirm phase goal and exact scope.
2. Implement only that phase.
3. Run checks.
4. Produce phase report.
5. Stop and ask: "Approve phase X and continue?"

## Phase 0: Contract Lock and Guardrails

Goal:
- Create a migration contract snapshot and acceptance checklist.

Tasks:
- Capture endpoint list, auth rules, status code expectations, and payload shapes from imported API.
- Capture frontend assumptions from auth/users/series services.
- Document any ambiguities and compatibility risks.

Deliverables:
- Contract snapshot document in docs/api-migration/contract-baseline.md
- Risk log in docs/api-migration/risks.md

Gate 0 checks:
- Baseline contract file exists and covers all listed routes.
- Known gaps are explicitly listed.

## Phase 1: ASP.NET Project Structure and DI Foundations

Goal:
- Establish maintainable project structure and registration points without full feature migration yet.

Tasks:
- Add endpoint, contract, auth, mapper, and common folders in src/apps/api-aspnet.
- Expand infrastructure project with domain documents, options, and repository abstractions.
- Wire required DI registrations.

Deliverables:
- Initial folder/module skeleton in API and infrastructure projects.
- Buildable solution.

Gate 1 checks:
- dotnet build appd5016-final-project.sln passes.
- No existing behavior regressions in currently mapped API endpoints.

## Phase 2: Cross-Cutting API Platform Setup

Goal:
- Add shared runtime capabilities used by all domains.

Tasks:
- Add ProblemDetails and exception handling strategy.
- Add JWT authentication and authorization setup.
- Add CORS policy aligned with source API intent.
- Add request validation plumbing for DTOs.

Deliverables:
- Program startup configuration for auth, validation, and error handling.
- Config sections for Mongo, JWT, and CORS.

Gate 2 checks:
- API starts successfully.
- Unauthorized access is blocked on protected test endpoint.
- Validation failures return structured 400 responses.

## Phase 3: Users and Auth Migration

Goal:
- Migrate login, register, users list/detail/delete with compatible behavior.

Tasks:
- Implement user repository and service operations.
- Implement password hashing and credential validation.
- Implement JWT issuance with compatible claims for frontend usage.
- Implement auth and users endpoints listed in baseline.

Deliverables:
- Working auth and users API in ASP.NET.

Gate 3 checks:
- POST /auth/login and POST /auth/register work end-to-end.
- GET /users and GET /users/{id} behave as expected.
- DELETE /users/{id} requires JWT.
- Response payload fields remain frontend compatible.

## Phase 4: Series Domain Migration

Goal:
- Migrate full series schema and CRUD operations including patch behavior.

Tasks:
- Implement series document model parity.
- Implement create, replace update, patch update, read, and delete operations.
- Enforce auth on non-GET series endpoints.

Deliverables:
- Working series endpoints with schema-compatible payload handling.

Gate 4 checks:
- All series routes in baseline function.
- Validation parity is acceptable for required fields and range constraints.
- Frontend can read and mutate series without contract changes.

## Phase 5: Compatibility Shims and Frontend Integration

Goal:
- Reduce cutover risk and support frontend transition.

Tasks:
- Add route aliases only if needed.
- Reconcile _id/id response strategy if required.
- Decide and implement change password route strategy:
  - add endpoint in ASP.NET, or
  - remove frontend call path, or
  - defer with explicit feature flag and documented limitation.
- Update frontend API base URL for local integration.

Deliverables:
- Frontend configured to target local ASP.NET API in development.

Gate 5 checks:
- Frontend auth, users, and series flows work against local API.
- Known gap resolution is implemented and documented.

## Phase 6: Tests and Parity Verification

Goal:
- Add confidence through automated and manual parity checks.

Tasks:
- Add integration tests for auth, users, and series routes.
- Add contract tests for status codes and required response fields.
- Execute manual parity checklist for high-risk paths.

Deliverables:
- Test project and parity checklist results.

Gate 6 checks:
- Relevant test suite passes.
- Manual parity checklist completed with no unresolved critical gaps.

## Phase 7: Cutover and Cleanup

Goal:
- Finalize migration and retire temporary scaffolding.

Tasks:
- Finalize API base URLs and environment settings.
- Remove temporary compatibility shims if no longer needed.
- Update README run instructions and migration notes.
- Archive migration artifacts as needed.

Deliverables:
- Production-ready ASP.NET API path with updated docs.

Gate 7 checks:
- Build and run instructions are accurate.
- No unresolved blockers remain for local or deployment flows.

## Reporting Format for Each Phase

Use this exact structure:

1. Phase Summary
2. Files Changed
3. Commands Run and Results
4. Behavioral Changes
5. Risks and Open Questions
6. Gate Checklist
7. Approval Request

## Suggested Validation Commands

- dotnet build appd5016-final-project.sln
- dotnet run --project src/apps/api-aspnet/SeriesCatalog.WebApi.csproj
- dotnet test

If dotnet test is unavailable due to missing test projects, state that explicitly and run targeted smoke checks instead.

## Stop Condition

After each phase report, stop and wait for explicit user approval before proceeding to the next phase.
