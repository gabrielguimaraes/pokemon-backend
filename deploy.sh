#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Pokemon Backend Deploy Script
# Deploys the backend API to a remote server via rsync
# =============================================================================

# Configuration — set these before running or export as environment variables
SSH_PORT="${SSH_PORT:-22}"
PRIVATE_KEY_PATH="${PRIVATE_KEY_PATH:-}"
SERVER="${SERVER:-}"
DEPLOY_USER="${DEPLOY_USER:-testrigor}"

# Local paths
LOCAL_BACKEND_DIR="$(cd "$(dirname "$0")" && pwd)"

# Remote paths
REMOTE_BACKEND_PATH="/var/www/pokemon-backend/"

# =============================================================================
# Validation
# =============================================================================

if [ -z "$SERVER" ]; then
  echo "ERROR: SERVER is not set. Export it or edit this script."
  echo "  export SERVER=your-server-ip"
  exit 1
fi

if [ -z "$PRIVATE_KEY_PATH" ]; then
  echo "ERROR: PRIVATE_KEY_PATH is not set. Export it or edit this script."
  echo "  export PRIVATE_KEY_PATH=/path/to/your/key"
  exit 1
fi

if [ ! -f "$PRIVATE_KEY_PATH" ]; then
  echo "ERROR: SSH key not found at $PRIVATE_KEY_PATH"
  exit 1
fi

SSH_CMD="ssh -p ${SSH_PORT} -i ${PRIVATE_KEY_PATH}"

# =============================================================================
# Build Backend
# =============================================================================

echo "=== Building Backend ==="
cd "$LOCAL_BACKEND_DIR"
npm install
npm run build

# =============================================================================
# Deploy Backend
# =============================================================================

echo ""
echo "=== Deploying Backend ==="
rsync -avzhe "${SSH_CMD}" --progress \
  "${LOCAL_BACKEND_DIR}/dist/server.js" "${DEPLOY_USER}@${SERVER}:${REMOTE_BACKEND_PATH}"

# =============================================================================
# Restart Services
# =============================================================================

echo ""
echo "=== Restarting Backend ==="
${SSH_CMD} "${DEPLOY_USER}@${SERVER}" << 'ENDSSH'
  cd /var/www/pokemon-backend
  NODE_ENV=production PORT=21051 pm2 restart pokemon-api 2>/dev/null || \
  NODE_ENV=production PORT=21051 pm2 start server.js --name pokemon-api
ENDSSH

echo ""
echo "=== Deploy Complete ==="
echo "Backend: http://${SERVER}:21051"
