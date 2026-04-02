## Current Frontend State

The repo now contains two frontend implementations:

- The migrated Blazor Web App in `blazor-migration/`
- The original React + Vite frontend in `src/`, retained as a repo-local fallback during cutover planning

The active migration record and gate evidence live under `docs/blazor-migration/`.

## Blazor App

The Blazor app is the Phase 5 migration target and currently provides:

- Auth routes: `/login`, `/register`, `/changepassword`
- Protected admin routes: `/admin/home`, `/admin/users`, `/admin/series`
- Users list/details/delete
- Series dashboard, list, details, add, update, and delete

### Local Run

1. Restore and build the solution:

```bash
dotnet build appd5016-final-project.sln
```

2. Run the Blazor app:

```bash
dotnet run --project blazor-migration/BlazorMigration.csproj
```

3. Open the local app at `http://localhost:5204`

### Local Configuration

- The Blazor app uses `blazor-migration/appsettings.json`
- Development launch settings live in `blazor-migration/Properties/launchSettings.json`
- The current API base URL is `https://assignment2-restapi-darrenmartell-h.vercel.app`

## React Fallback

The original React frontend remains in the repo for rollback and comparison during migration closeout.

### Local Run

1. Install dependencies:

```bash
pnpm install
```

2. Start the React dev server:

```bash
pnpm run dev
```

## Migration Docs

- Migration prompts live in `.github/prompts/`
- Migration planning and gate documentation live in `docs/blazor-migration/`
- The repo-local cutover and rollback plan lives in `docs/blazor-migration/cutover-and-rollback.md`
