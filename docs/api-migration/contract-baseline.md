# API Migration Contract Baseline (Phase 0)

## Scope

This document defines the source API behavior that must be preserved when migrating from NestJS in imported_api_solution/src to ASP.NET in src/apps/api-aspnet.

Primary source files:
- imported_api_solution/src/main.ts
- imported_api_solution/src/mongoose-exception-filter.ts
- imported_api_solution/src/auth/auth.controller.ts
- imported_api_solution/src/auth/auth.service.ts
- imported_api_solution/src/auth/local.strategy.ts
- imported_api_solution/src/users/users.controller.ts
- imported_api_solution/src/users/users.service.ts
- imported_api_solution/src/series/series.controller.ts
- imported_api_solution/src/series/series.service.ts
- imported_api_solution/src/users/dto/*.ts
- imported_api_solution/src/series/dto/*.ts

Frontend compatibility sources:
- src/apps/frontend-blazor/Services/Auth/AuthService.cs
- src/apps/frontend-blazor/Services/Users/UsersService.cs
- src/apps/frontend-blazor/Services/Series/SeriesService.cs
- src/apps/frontend-blazor/Models/Series/SeriesRecord.cs
- src/apps/frontend-blazor/Models/Series/SeriesUpsertRequest.cs
- src/apps/frontend-blazor/Models/Auth/AuthenticatedUser.cs

## Global Behavior Baseline

1. CORS enabled with specific origins, methods, headers, and credentials.
2. Global validation behavior (ValidationPipe):
   - whitelist=true
   - forbidNonWhitelisted=true
   - forbidUnknownValues=true
   - transform=true
3. Global mongoose exception filter:
   - Mongoose validation errors -> HTTP 400 with { statusCode, message }
   - Other mongoose errors -> HTTP 500 with { statusCode, message }
4. API binds at root routes (no /api prefix in imported source).

## Security and Auth Baseline

1. JWT bearer token is required for protected routes.
2. Protected routes:
   - DELETE /users/{id}
   - POST /series
   - PUT /series/{id}
   - PATCH /series/{id}
   - DELETE /series/{id}
3. Auth token payload includes:
   - sub (email)
   - _id
   - firstName
   - lastName
4. Invalid login credentials return Unauthorized behavior.

## Endpoint Contract Matrix

### Auth Endpoints

1. POST /auth/login
- Auth: public
- Request body: LoginDto { email, password }
- Success: 201 with LoginResponseDto
  - message
  - access_token
  - _id
  - email
  - firstName
  - lastName
- Error expectations:
  - 400 on validation failures
  - 401 on invalid credentials

2. POST /auth/register
- Auth: public
- Request body: CreateUserDto { email, firstName, lastName, password }
- Success: 201 with LoginResponseDto
  - message
  - access_token
  - _id
  - email
  - firstName
  - lastName
- Error expectations:
  - 400 on validation failures
  - 409 when user already exists

### Users Endpoints

1. GET /users
- Auth: public (source behavior)
- Success: 200 with UserResponseDto[]
  - _id, email, firstName, lastName
- Error expectations:
  - 404 when no users found (source service behavior)

2. GET /users/{id}
- Auth: public (source behavior)
- Path rules: id must satisfy IsMongoId validation
- Success: 200 with UserResponseDto
- Error expectations:
  - 400 when id format is invalid
  - 404 when user is not found

3. DELETE /users/{id}
- Auth: JWT required
- Path rules: id must satisfy IsMongoId validation
- Success: 200 with deleted UserResponseDto
- Error expectations:
  - 400 when id format is invalid
  - 401 when token missing/invalid
  - 404 when user is not found

### Series Endpoints

1. GET /series
- Auth: public
- Success: 200 with Series[]
- Empty set behavior: returns 200 with []

2. GET /series/{id}
- Auth: public
- Path rules: id must satisfy IsMongoId validation
- Success: 200 with Series object
- Error expectations:
  - 400 when id format is invalid
  - 404 when series item is not found

3. POST /series
- Auth: JWT required
- Request body: CreateSeriesDto (full shape)
- Success: 201 with created Series object
- Error expectations:
  - 400 on validation failures
  - 401 when token missing/invalid

4. PUT /series/{id}
- Auth: JWT required
- Request body: UpdateSeriesDto (full replace)
- Success: 200 with updated Series object
- Error expectations:
  - 400 on validation failures
  - 400 when id format is invalid
  - 401 when token missing/invalid
  - 404 when series item is not found

5. PATCH /series/{id}
- Auth: JWT required
- Request body: PatchSeriesDto (partial)
- Success: 200 with updated Series object
- Error expectations:
  - 400 on validation failures
  - 400 when id format is invalid
  - 401 when token missing/invalid
  - 404 when series item is not found

6. DELETE /series/{id}
- Auth: JWT required
- Path rules: id must satisfy IsMongoId validation
- Success: 200 with deleted Series object
- Error expectations:
  - 400 when id format is invalid
  - 401 when token missing/invalid
  - 404 when series item is not found

## DTO and Validation Baseline

### User DTO rules

1. email: required, valid email format
2. firstName: required
3. lastName: required
4. password:
- required
- length 8..128
- must contain uppercase, lowercase, digit, and special character

### Series DTO rules (selected constraints)

1. title: required, length 1..50
2. plot_summary: required, length 1..500
3. runtime_minutes: positive, max 999
4. released_year: positive int, max 9999
5. cast/directors/genres/countries/languages/producers/production_companies:
- string arrays
- each item length 1..50
- unique items
6. ratings:
- imdb: number > 0 and <= 10
- rotten_tomatoes: int > 0 and <= 100
- metacritic: int > 0 and <= 100
- user_average: number > 0 and <= 10
7. episodes:
- episode_number: number > 0
- episode_title: length 1..50
- runtime_minutes: number > 0

## Frontend Compatibility Assumptions

1. Frontend calls API using root routes (auth/*, users/*, series/*), not /api/*.
2. Frontend expects auth response token in access_token (or accessToken fallback).
3. Frontend expects identity fields in _id and/or id.
4. Frontend model binding for series expects snake_case JSON names and _id:
- plot_summary
- runtime_minutes
- released_year
- production_companies
- _id
5. Frontend uses JWT bearer token for protected operations.

## Known Gaps and Ambiguities

1. Gap: frontend calls PATCH /auth/{id}/changepassword, but source imported API does not provide this endpoint.
2. Ambiguity: imported API default success status on POST is framework default (expected 201); migration should preserve effective client behavior.
3. Ambiguity: /users is public in imported API; this may be acceptable for migration parity but may conflict with desired production security posture.

## Phase 0 Acceptance Checklist

1. All required routes are listed in this baseline.
2. Auth and protection rules are identified per route.
3. Request and response compatibility requirements are documented.
4. Validation and global behavior constraints are documented.
5. Known gaps and ambiguities are documented.
