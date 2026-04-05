# Assignment - Frontend UI Implementation

This project now uses:

- Blazor Web App frontend
- ASP.NET API backend

## Tech Stack

- ASP.NET Core Blazor Web App (`net10.0`)
- Tailwind-generated stylesheet committed at `src/wwwroot/tailwind.css`

## Run Locally

```bash
dotnet build appd5016-final-project.sln
dotnet run --project src/apps/api-aspnet/SeriesCatalog.WebApi.csproj
dotnet run --project src/apps/frontend-blazor/SeriesCatalog.Frontend.csproj
```

Open:

- Frontend: http://localhost:5204
- API: http://localhost:5130

## API Configuration

Set API base URL in:

- src/apps/frontend-blazor/appsettings.json
- src/apps/frontend-blazor/appsettings.Development.json

