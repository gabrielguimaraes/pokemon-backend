#
# build.ps1 - Build script for Pokemon Backend (Windows)
#
# Bundles the Express API server into a single file using esbuild.
# The output (dist\server.js) can run without node_modules on the server.
#
# Usage:
#   .\build.ps1 [-Clean]
#
# Examples:
#   .\build.ps1
#   .\build.ps1 -Clean
#

param(
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# ─── Functions ───────────────────────────────────────────────────────────────
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-ErrorMessage {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# ─── Pre-flight Checks ──────────────────────────────────────────────────────
foreach ($cmd in @("node", "npm")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-ErrorMessage "$cmd is not installed. Please install Node.js (v18+) and npm."
        exit 1
    }
}

Write-Info "Node.js version: $(node --version)"
Write-Info "npm version: $(npm --version)"
Write-Host ""

# ─── Build ───────────────────────────────────────────────────────────────────
Push-Location $ScriptDir

try {
    if ($Clean -and (Test-Path "dist")) {
        Write-Info "Cleaning previous build artifacts..."
        Remove-Item -Recurse -Force "dist"
    }

    Write-Info "Installing dependencies..."
    & npm install
    if ($LASTEXITCODE -ne 0) { throw "npm install failed" }

    Write-Info "Building backend with esbuild..."
    & npm run build
    if ($LASTEXITCODE -ne 0) { throw "npm run build failed" }

    if (Test-Path "dist\server.js") {
        $size = (Get-Item "dist\server.js").Length / 1KB
        Write-Success "Backend build complete! Output: $ScriptDir\dist\server.js"
        Write-Info ("Bundle size: {0:N0} KB" -f $size)
    }
    else {
        Write-ErrorMessage "Build failed - dist\server.js not created."
        exit 1
    }
}
finally {
    Pop-Location
}
