## Application

This repository now contains:

- ASP.NET API in src/apps/api-aspnet
- Blazor Web App frontend in src/apps/frontend-blazor

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
dotnet run --project src/apps/frontend-blazor/SeriesCatalog.Frontend.csproj
```

3. Run the API (separate terminal):

```bash
dotnet run --project src/apps/api-aspnet/SeriesCatalog.WebApi.csproj
```

4. Open the local apps:

- Frontend: http://localhost:5204
- API: http://localhost:5130

### Docker Run

From the repository root:

1. Create a local Docker env file (one-time setup):

```powershell
Copy-Item deploy/docker/.env.example deploy/docker/.env
```

2. Start the stack:

```bash
docker compose --env-file deploy/docker/.env -f deploy/docker/docker-compose.yml up --build -d
```

3. Open the containerized apps:

- Frontend: http://localhost:8082
- API: not published to the host (internal Docker network only)

Security note: only the frontend is published on a host port. The API is reachable only by other containers on the Docker network (for example, the frontend at http://api:8080).

4. Stop and remove the stack when done:

```bash
docker compose --env-file deploy/docker/.env -f deploy/docker/docker-compose.yml down
```

### Local Configuration

- Frontend settings: src/apps/frontend-blazor/appsettings.json and src/apps/frontend-blazor/appsettings.Development.json
- API settings: src/apps/api-aspnet/appsettings.json and src/apps/api-aspnet/appsettings.Development.json
- Default frontend API base URL points to http://localhost:5130

## Migration Docs

- Migration prompts live in `.github/prompts/`
- API migration planning and gate documentation live in docs/api-migration

