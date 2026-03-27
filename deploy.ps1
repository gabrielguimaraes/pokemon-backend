# =============================================================================
# Pokemon Backend Deploy Script — PowerShell
# Deploys the backend API to a remote server via rsync
# =============================================================================

param(
    [string]$Server = $env:SERVER,
    [string]$SshPort = $(if ($env:SSH_PORT) { $env:SSH_PORT } else { "22" }),
    [string]$PrivateKeyPath = $env:PRIVATE_KEY_PATH,
    [string]$DeployUser = $(if ($env:DEPLOY_USER) { $env:DEPLOY_USER } else { "testrigor" })
)

$ErrorActionPreference = "Stop"

# Local paths
$LocalBackendDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Remote paths
$RemoteBackendPath = "/var/www/pokemon-backend/"

# =============================================================================
# Validation
# =============================================================================

if (-not $Server) {
    Write-Error "ERROR: Server is not set. Use -Server parameter or set SERVER env var."
    exit 1
}

if (-not $PrivateKeyPath) {
    Write-Error "ERROR: PrivateKeyPath is not set. Use -PrivateKeyPath parameter or set PRIVATE_KEY_PATH env var."
    exit 1
}

if (-not (Test-Path $PrivateKeyPath)) {
    Write-Error "ERROR: SSH key not found at $PrivateKeyPath"
    exit 1
}

$SshCmd = "ssh -p $SshPort -i $PrivateKeyPath"

# =============================================================================
# Build Backend
# =============================================================================

Write-Host "=== Building Backend ===" -ForegroundColor Cyan
Set-Location $LocalBackendDir
npm install
npm run build

# =============================================================================
# Deploy Backend
# =============================================================================

Write-Host ""
Write-Host "=== Deploying Backend ===" -ForegroundColor Cyan
rsync -avzhe "$SshCmd" --progress `
  "$LocalBackendDir/dist/server.js" "${DeployUser}@${Server}:${RemoteBackendPath}"

# =============================================================================
# Restart Services
# =============================================================================

Write-Host ""
Write-Host "=== Restarting Backend ===" -ForegroundColor Cyan
& ssh -p $SshPort -i $PrivateKeyPath "${DeployUser}@${Server}" @"
cd /var/www/pokemon-backend
NODE_ENV=production PORT=21051 pm2 restart pokemon-api 2>/dev/null || NODE_ENV=production PORT=21051 pm2 start server.js --name pokemon-api
"@

Write-Host ""
Write-Host "=== Deploy Complete ===" -ForegroundColor Green
Write-Host "Backend: http://${Server}:21051"
