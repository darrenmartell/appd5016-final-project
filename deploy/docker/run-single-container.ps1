#requires -Version 7.0

<#
.SYNOPSIS
    Build and run Series Catalog in a single Docker container

.DESCRIPTION
    Builds and runs both API and Frontend in one container with Nginx reverse proxy.
    Simpler than multi-container setup, good for testing and deployment.

.PARAMETER MongoDbConnectionString
    MongoDB connection string (required)

.PARAMETER MongoDbDatabaseName
    MongoDB database name (default: series_catalog)

.PARAMETER FrontendPort
    Port to expose (default: 8080)

.PARAMETER Build
    If true, builds the image before running

.PARAMETER NoBuild
    If true, skips building the image (uses existing)

.EXAMPLE
    # Build and run with MongoDB
    .\run-single-container.ps1 `
      -MongoDbConnectionString "mongodb+srv://user:pass@cluster.mongodb.net/db" `
      -Build

.EXAMPLE
    # Run without building
    .\run-single-container.ps1 `
      -MongoDbConnectionString "mongodb+srv://user:pass@cluster.mongodb.net/db" `
      -NoBuild
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$MongoDbConnectionString,

    [string]$MongoDbDatabaseName = "series_catalog",

    [string]$FrontendPort = "8080",

    [switch]$Build = $false,

    [switch]$NoBuild = $false
)

$ErrorActionPreference = "Stop"

# Color output helpers
function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
}

$script:DockerComposeCommand = @()

function Invoke-DockerCompose {
    param([string[]]$Arguments)

    if ($script:DockerComposeCommand.Count -eq 2) {
        & $script:DockerComposeCommand[0] $script:DockerComposeCommand[1] @Arguments
        return
    }

    & $script:DockerComposeCommand[0] @Arguments
}

try {
    # ========================================================================
    # VALIDATION
    # ========================================================================
    Write-Section "VALIDATION"

    # Check Docker
    Write-Info "Checking Docker..."
    $dockerVersion = docker --version 2>$null
    if (-not $dockerVersion) {
        Write-Error-Custom "Docker not found. Install from https://www.docker.com"
        exit 1
    }
    Write-Success "Docker found: $dockerVersion"

    # Check Docker running
    Write-Info "Checking if Docker daemon is running..."
    docker ps 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Docker daemon not running. Start Docker Desktop or Docker service"
        exit 1
    }
    Write-Success "Docker daemon is running"

    # Check Docker Compose command (plugin preferred)
    Write-Info "Checking Docker Compose command..."
    docker compose version *> $null
    if ($LASTEXITCODE -eq 0) {
        $script:DockerComposeCommand = @("docker", "compose")
    }
    elseif (Get-Command docker-compose -ErrorAction SilentlyContinue) {
        $script:DockerComposeCommand = @("docker-compose")
    }
    else {
        Write-Error-Custom "Docker Compose not found. Install Docker Compose plugin or docker-compose."
        exit 1
    }
    Write-Success "Docker Compose found: $($script:DockerComposeCommand -join ' ')"

    # ========================================================================
    # BUILD IMAGE
    # ========================================================================
    if (-not $NoBuild -or $Build) {
        Write-Section "BUILDING IMAGE"

        Write-Info "Building single-container image..."
        Write-Info "This may take 5-10 minutes on first build..."

        Invoke-DockerCompose @("-f", "deploy/docker/docker-compose.single.yml", "build")

        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Docker build failed"
            exit 1
        }
        Write-Success "Image built successfully"
    }
    else {
        Write-Section "SKIPPING BUILD"
        Write-Info "Using existing image (use -Build to rebuild)"
    }

    # ========================================================================
    # RUN CONTAINER
    # ========================================================================
    Write-Section "STARTING CONTAINER"

    Write-Info "Starting single container with:"
    Write-Info "  • API on internal port 5130"
    Write-Info "  • Frontend on internal port 5131"
    Write-Info "  • Nginx reverse proxy on port $FrontendPort"
    Write-Info "  • MongoDB: $MongoDbDatabaseName database"
    Write-Info ""

    # Set environment variables
    $env:FRONTEND_PORT = $FrontendPort
    $env:MONGO_CONNECTION_STRING = $MongoDbConnectionString
    $env:MONGO_DATABASE_NAME = $MongoDbDatabaseName

    # Run container
    Invoke-DockerCompose @("-f", "deploy/docker/docker-compose.single.yml", "up")

}
catch {
    Write-Error-Custom "An error occurred: $_"
    exit 1
}
