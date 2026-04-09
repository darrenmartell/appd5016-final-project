#requires -Version 7.0

[CmdletBinding()]
param(
    [string]$ProjectKey = "Series",
    [string]$SonarHostUrl = "http://localhost:9000",
    [string]$SonarToken = $env:SONAR_TOKEN,
    [string]$SolutionPath = "appd5016-final-project.sln"
)

$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK]   $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERR]  $Message" -ForegroundColor Red
}

if ([string]::IsNullOrWhiteSpace($SonarToken)) {
    Write-Error-Custom "Sonar token is required. Pass -SonarToken or set SONAR_TOKEN environment variable."
    exit 1
}

if (-not (Test-Path -Path $SolutionPath)) {
    Write-Error-Custom "Solution file not found: $SolutionPath"
    exit 1
}

$beginSucceeded = $false

try {
    Write-Info "Starting SonarScanner analysis..."
    dotnet sonarscanner begin "/k:$ProjectKey" "/d:sonar.host.url=$SonarHostUrl" "/d:sonar.token=$SonarToken"
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet sonarscanner begin failed with exit code $LASTEXITCODE"
    }
    $beginSucceeded = $true
    Write-Success "SonarScanner begin completed"

    Write-Info "Building solution: $SolutionPath"
    dotnet build $SolutionPath
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet build failed with exit code $LASTEXITCODE"
    }
    Write-Success "Build completed"
}
catch {
    Write-Error-Custom "Scan pipeline failed: $_"
    exit 1
}
finally {
    if ($beginSucceeded) {
        Write-Info "Finalizing SonarScanner analysis..."
        dotnet sonarscanner end "/d:sonar.token=$SonarToken"
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "dotnet sonarscanner end failed with exit code $LASTEXITCODE"
            exit $LASTEXITCODE
        }
        Write-Success "SonarScanner end completed"
    }
}

Write-Success "Sonar scan finished successfully"
