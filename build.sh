#!/usr/bin/env bash
#
# build.sh - Build script for Pokemon Backend (Linux/macOS)
#
# Bundles the Express API server into a single file using esbuild.
# The output (dist/server.js) can run without node_modules on the server.
#
# Usage:
#   ./build.sh [--clean]
#
# Options:
#   --clean    Remove existing build artifacts before building
#   -h, --help Show this help message
#
# Examples:
#   ./build.sh
#   ./build.sh --clean
#

set -euo pipefail

# ─── Defaults ────────────────────────────────────────────────────────────────
CLEAN=false

# ─── Paths ───────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Colors ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# ─── Parse Arguments ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --clean)
            CLEAN=true
            shift
            ;;
        -h|--help)
            sed -n '/^# Usage:/,/^[^#]/p' "$0" | head -n -1 | sed 's/^# \?//'
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ─── Pre-flight Checks ──────────────────────────────────────────────────────
for cmd in node npm; do
    if ! command -v "$cmd" &>/dev/null; then
        log_error "$cmd is not installed. Please install Node.js (v18+) and npm."
        exit 1
    fi
done

log_info "Node.js version: $(node --version)"
log_info "npm version: $(npm --version)"
echo ""

# ─── Build ───────────────────────────────────────────────────────────────────
cd "$SCRIPT_DIR"

if [ "$CLEAN" = true ]; then
    log_info "Cleaning previous build artifacts..."
    rm -rf dist/
fi

log_info "Installing dependencies..."
npm install

log_info "Building backend with esbuild..."
npm run build

if [ -f "dist/server.js" ]; then
    log_success "Backend build complete! Output: ${SCRIPT_DIR}/dist/server.js"
    log_info "Bundle size: $(du -h dist/server.js | cut -f1)"
else
    log_error "Build failed - dist/server.js not created."
    exit 1
fi
