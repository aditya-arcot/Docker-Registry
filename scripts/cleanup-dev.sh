#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/.."
CONFIG_DIR="$BASE_DIR/config"

source "$CONFIG_DIR/.env.dev"
export REGISTRY_URL="localhost:${REGISTRY_PORT}"
export CONTAINER="registry-dev"

regctl registry set --tls disabled ${REGISTRY_URL}
"${SCRIPT_DIR}/cleanup_images.sh"
