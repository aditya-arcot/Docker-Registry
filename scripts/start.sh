#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/.."
CONFIG_DIR="$BASE_DIR/config"

docker network create traefik-public || true
docker compose --env-file "$CONFIG_DIR/.env" -f "$BASE_DIR/docker-compose.yml" up -d
