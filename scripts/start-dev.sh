#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/.."
CONFIG_DIR="$BASE_DIR/config"

docker compose --env-file "$CONFIG_DIR/.env.dev" -f "$BASE_DIR/docker-compose.dev.yml" up -d
