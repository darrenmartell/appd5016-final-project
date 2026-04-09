# Single Container Deployment

This directory contains an alternative single-container deployment for Series Catalog that runs both the API and Frontend in one Docker container.

## Overview

**Single Container Architecture:**
```
┌─────────────────────────────────────┐
│       Docker Container              │
├─────────────────────────────────────┤
│  Supervisor (Process Manager)       │
│  ├── API (port 5130)                │
│  ├── Frontend (port 5131)           │
│  └── Nginx (port 8080)              │
└─────────────────────────────────────┘
         │
    External Port: 8080
```

**Traffic Flow:**
```
Client (http://localhost:8080)
  │
  ├─► Nginx (reverse proxy)
       │
  ├─► /auth/*, /users*, /series* → API (5130)
  ├─► /api/* → API (5130)
  └─► /* → Frontend (5131)
```

## When to Use Single Container

### ✅ Good for:
- **Local development** - Single container easier to manage
- **Simple deployments** - Less infrastructure complexity
- **CI/CD testing** - Faster to build and deploy
- **Resource-constrained environments** - One container vs. two
- **Docker Compose workflows** - All-in-one setup

### ❌ Not ideal for:
- **Production microservices** - Multi-container is more scalable
- **Independent scaling** - Can't scale API separately from frontend
- **High availability** - Single container failure affects both services
- **Different tech stacks** - Both services must use .NET/Nginx

## Files

- **Dockerfile.single** - Multi-stage build for both applications
- **docker-compose.single.yml** - Single container compose configuration
- **nginx.conf** - Nginx reverse proxy configuration
- **supervisord.conf** - Supervisor daemon configuration (manages both services)
- **entrypoint.sh** - Container startup script
- **run-single-container.ps1** - PowerShell script to build and run

## Quick Start

### Option 1: Using PowerShell Script (Recommended)

```powershell
# Build and run with MongoDB Atlas
.\run-single-container.ps1 `
  -MongoDbConnectionString "mongodb+srv://user:pass@cluster.mongodb.net/db"

# Run without rebuilding
.\run-single-container.ps1 `
  -MongoDbConnectionString "mongodb+srv://user:pass@cluster.mongodb.net/db" `
  -NoBuild

# Use custom port and database name
.\run-single-container.ps1 `
  -MongoDbConnectionString "mongodb+srv://user:pass@cluster.mongodb.net/db" `
  -FrontendPort "3000" `
  -MongoDbDatabaseName "my_database"
```

### Option 2: Using Docker Compose Directly

```powershell
# Set environment variables
$env:MONGO_CONNECTION_STRING="mongodb+srv://user:pass@cluster.mongodb.net/db"
$env:MONGO_DATABASE_NAME="series_catalog"
$env:FRONTEND_PORT="8080"

# Build image
docker compose -f deploy/docker/docker-compose.single.yml build

# Run container
docker compose -f deploy/docker/docker-compose.single.yml up

# Run in background
docker compose -f deploy/docker/docker-compose.single.yml up -d
```

### Option 3: Using Docker Directly

```powershell
# Build
docker build -f deploy/docker/Dockerfile.single -t series-catalog:single .

# Run
docker run -p 8080:8080 `
  -e MONGO_CONNECTION_STRING="mongodb+srv://user:pass@cluster.mongodb.net/db" `
  -e MONGO_DATABASE_NAME="series_catalog" `
  series-catalog:single
```

## Access Application

After container starts:
- **Frontend:** http://localhost:8080
- **API (app routes):** http://localhost:8080/auth/*, http://localhost:8080/users, http://localhost:8080/series
- **API Health Check:** http://localhost:8080/health (proxied to `/api/health`)

## Service Communication

Inside the container:
- Frontend calls API at: `http://localhost:8080`
- API listens on: `127.0.0.1:5130`
- Frontend listens on: `127.0.0.1:5131`
- Nginx reverse proxy on: `0.0.0.0:8080`

Nginx routes `/auth/*`, `/users*`, and `/series*` to the API process.

The `Api__BaseUrl` environment variable is set to `http://localhost:8080`.

## Process Management

Uses **Supervisor** to manage three processes:

| Process | Port | Purpose |
|---------|------|---------|
| API | 5130 | ASP.NET Core Web API |
| Frontend | 5131 | Blazor Web App (Interactive Server) |
| Nginx | 8080 | Reverse proxy & load balancer |

All processes are monitored and auto-restarted if they crash.

## Viewing Logs

```bash
# View all supervisor logs
docker exec series-catalog-single supervisorctl status

# View specific service logs
docker exec series-catalog-single tail -f /var/log/supervisor/api.out.log
docker exec series-catalog-single tail -f /var/log/supervisor/frontend.out.log
docker exec series-catalog-single tail -f /var/log/supervisor/nginx.out.log

# Access running container
docker exec -it series-catalog-single /bin/bash
```

## Stopping the Container

```bash
# Using Docker Compose
docker compose -f deploy/docker/docker-compose.single.yml down

# Using Docker
docker stop series-catalog-single
docker rm series-catalog-single
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `MONGO_CONNECTION_STRING` | Yes | - | MongoDB connection string |
| `MONGO_DATABASE_NAME` | No | `series_catalog` | MongoDB database name |
| `FRONTEND_PORT` | No | `8080` | Port to expose |
| `ASPNETCORE_ENVIRONMENT` | No | `Production` | Environment mode |

## Comparison: Single vs. Multi-Container

| Feature | Single Container | Multi-Container |
|---------|------------------|-----------------|
| **Complexity** | Low | Medium |
| **Resource Usage** | Lower | Higher |
| **Startup Time** | Faster | Slower |
| **Independent Scaling** | No | Yes |
| **Development** | Simpler | More flexible |
| **Production Ready** | For simple deployments | Microservices-ready |
| **Ideal For** | Dev/Testing/Simple apps | Enterprise/Microservices |

## Troubleshooting

**Container won't start:**
```powershell
# Check logs
docker compose -f deploy/docker/docker-compose.single.yml logs

# Check if ports are in use
netstat -ano | findstr :8080
```

**MongoDB connection fails:**
- Verify connection string is correct
- Check MongoDB IP whitelist includes container source IP
- Ensure MongoDB user has proper permissions

**Services not responding:**
```powershell
# Check supervisor status
docker exec series-catalog-single supervisorctl status

# Restart a specific service
docker exec series-catalog-single supervisorctl restart api
docker exec series-catalog-single supervisorctl restart frontend
```

**Nginx not routing traffic:**
- Check nginx logs: `/var/log/supervisor/nginx.out.log`
- Verify services are running on expected ports (5130, 5131)
- Test with: `curl http://localhost:8080/health` and `curl http://localhost:8080/api/health`

## Next Steps

After verifying single-container deployment works locally:

1. **Push to ACR:**
   ```powershell
   docker tag series-catalog:single myacr.azurecr.io/series-catalog-single:latest
   docker push myacr.azurecr.io/series-catalog-single:latest
   ```

2. **Deploy to Azure Container Apps:**
   - Update `container-apps.bicep` to use single image
   - Point ACR login to single image
   - Deploy with `deploy-container-apps.ps1`

3. **For production:** Consider multi-container approach for:
   - Independent scaling
   - Better resource isolation
   - Microservices architecture support
