FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy project files only first (for better layer caching)
COPY src/apps/api-aspnet/SeriesCatalog.WebApi.csproj src/apps/api-aspnet/
COPY src/infrastructure/data-mongodb/SeriesCatalog.Infrastructure.MongoDb.csproj src/infrastructure/data-mongodb/
RUN dotnet restore src/apps/api-aspnet/SeriesCatalog.WebApi.csproj

# Copy source and build
COPY src/apps/api-aspnet/ src/apps/api-aspnet/
COPY src/infrastructure/data-mongodb/ src/infrastructure/data-mongodb/
RUN dotnet publish src/apps/api-aspnet/SeriesCatalog.WebApi.csproj \
    -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage - smaller image
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

COPY --from=build /app/publish .

# Container Apps auto-injects these, but being explicit is good
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

EXPOSE 8080

ENTRYPOINT ["dotnet", "SeriesCatalog.WebApi.dll"]