FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY src/apps/frontend-blazor/SeriesCatalog.Frontend.csproj src/apps/frontend-blazor/
RUN dotnet restore src/apps/frontend-blazor/SeriesCatalog.Frontend.csproj

COPY src/apps/frontend-blazor/ src/apps/frontend-blazor/
RUN dotnet publish src/apps/frontend-blazor/SeriesCatalog.Frontend.csproj \
    -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

EXPOSE 8080

ENTRYPOINT ["dotnet", "SeriesCatalog.Frontend.dll"]