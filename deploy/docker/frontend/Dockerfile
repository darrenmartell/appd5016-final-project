FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY src/apps/frontend-blazor/BlazorMigration.csproj src/apps/frontend-blazor/
RUN dotnet restore src/apps/frontend-blazor/BlazorMigration.csproj

COPY src/apps/frontend-blazor/ src/apps/frontend-blazor/
RUN dotnet publish src/apps/frontend-blazor/BlazorMigration.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app

COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "BlazorMigration.dll"]
