#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/.."
CONFIG_DIR="$BASE_DIR/config"

source "$CONFIG_DIR/.env"
export REGISTRY_URL="registry.${DOMAIN}"
export CONTAINER="registry"

./cleanup_images.sh
