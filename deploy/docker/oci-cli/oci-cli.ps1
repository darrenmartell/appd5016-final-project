[CmdletBinding()]
param(
    [ValidateSet("start", "stop", "shell", "run", "setup", "status")]
    [string]$Action = "shell",
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$OciArgs,
    [Alias("?")]
    [switch]$Help
)

$ErrorActionPreference = "Stop"

if ($Help -or $args -contains "-?" -or $args -contains "/?") {
@"
Persistent OCI CLI container helper.

Usage:
    pwsh deploy/docker/oci-cli/oci-cli.ps1 <action> [oci-args...]

Actions:
    start   - Build (if needed) and start the persistent container
    stop    - Stop the container (preserves state for next start)
    shell   - Open an interactive shell inside the running container
    run     - Run a single OCI CLI command (pass args after 'run')
    setup   - Run 'oci setup config' interactively inside the container
    status  - Show container status

Examples:
    pwsh deploy/docker/oci-cli/oci-cli.ps1 start
    pwsh deploy/docker/oci-cli/oci-cli.ps1 run oci os ns get
    pwsh deploy/docker/oci-cli/oci-cli.ps1 run oci iam region list
    pwsh deploy/docker/oci-cli/oci-cli.ps1 run kubectl get nodes
    pwsh deploy/docker/oci-cli/oci-cli.ps1 setup
    pwsh deploy/docker/oci-cli/oci-cli.ps1 shell
    pwsh deploy/docker/oci-cli/oci-cli.ps1 stop
    pwsh deploy/docker/oci-cli/oci-cli.ps1 status

Notes:
    - ~/.oci and ~/.kube from your host are mounted into the container.
    - Run 'setup' first if you haven't configured OCI CLI yet.
    - The container stays running between commands (restart: unless-stopped).
"@ | Write-Host
    return
}

$composeFile = Join-Path $PSScriptRoot "docker-compose.oci-cli.yml"
$containerName = "oci-cli"

function Ensure-Running {
    $state = docker inspect -f '{{.State.Running}}' $containerName 2>$null
    if ($state -ne "true") {
        Write-Host "Starting OCI CLI container..."
        docker compose -f $composeFile up -d --build
    }
}

switch ($Action) {
    "start" {
        Write-Host "Building and starting OCI CLI container..."
        docker compose -f $composeFile up -d --build
        Write-Host "OCI CLI container is running. Use 'run', 'shell', or 'setup' actions."
    }
    "stop" {
        Write-Host "Stopping OCI CLI container..."
        docker compose -f $composeFile stop
        Write-Host "Container stopped. Use 'start' to resume."
    }
    "shell" {
        Ensure-Running
        docker exec -it $containerName bash
    }
    "run" {
        Ensure-Running
        if ($OciArgs.Count -eq 0) {
            throw "No command provided. Example: pwsh oci-cli.ps1 run oci os ns get"
        }
        docker exec $containerName $OciArgs
    }
    "setup" {
        Ensure-Running
        Write-Host "Running OCI CLI setup interactively..."
        docker exec -it $containerName oci setup config
    }
    "status" {
        $state = docker inspect -f '{{.State.Status}}' $containerName 2>$null
        if ($state) {
            Write-Host "Container '$containerName' status: $state"
        }
        else {
            Write-Host "Container '$containerName' does not exist. Run 'start' first."
        }
    }
}
