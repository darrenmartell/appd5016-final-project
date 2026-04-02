# Assignment - Frontend UI Implementation

This project now uses a Blazor Web App frontend only.

## Tech Stack

- ASP.NET Core Blazor Web App (`net10.0`)
- Tailwind-generated stylesheet committed at `src/wwwroot/tailwind.css`

## Run Locally

```bash
dotnet build appd5016-final-project.sln
dotnet run --project src/BlazorMigration.csproj
```

Open: `http://localhost:5204`

## API Configuration

Set API base URL in:

- `src/appsettings.json`
- `src/appsettings.Development.json`
