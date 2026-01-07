#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/.."
CONFIG_DIR="$BASE_DIR/config"
ENV_FILE="$CONFIG_DIR/.env"

export $(grep -v '^#' "$ENV_FILE" | xargs)
envsubst < "$CONFIG_DIR/config.yml.template" > "$CONFIG_DIR/config.yml"

docker network create traefik-public || true
docker compose --env-file "$ENV_FILE" -f "$BASE_DIR/docker-compose.yml" up -d
