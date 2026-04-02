## Application

This repository now contains a single frontend implementation: the Blazor Web App in `src/`.

The app currently provides:

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
dotnet run --project src/BlazorMigration.csproj
```

3. Open the local app at `http://localhost:5204`

### Local Configuration

- The Blazor app uses `src/appsettings.json`
- Development launch settings live in `src/Properties/launchSettings.json`
- The current API base URL is `https://assignment2-restapi-darrenmartell-h.vercel.app`

## Migration Docs

- Migration prompts live in `.github/prompts/`
- Migration planning and gate documentation live in `docs/blazor-migration/`
- The repo-local cutover and rollback plan lives in `docs/blazor-migration/cutover-and-rollback.md`
