FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY src/apps/api-aspnet/SeriesCatalog.WebApi.csproj src/apps/api-aspnet/
COPY src/infrastructure/data-mongodb/SeriesCatalog.Infrastructure.MongoDb.csproj src/infrastructure/data-mongodb/
RUN dotnet restore src/apps/api-aspnet/SeriesCatalog.WebApi.csproj

COPY src/apps/api-aspnet/ src/apps/api-aspnet/
COPY src/infrastructure/data-mongodb/ src/infrastructure/data-mongodb/
RUN dotnet publish src/apps/api-aspnet/SeriesCatalog.WebApi.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app

COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "SeriesCatalog.WebApi.dll"]

