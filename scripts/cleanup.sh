#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/.."
CONFIG_DIR="$BASE_DIR/config"

source "$CONFIG_DIR/.env"
export REGISTRY_URL="registry.${DOMAIN}"
export CONTAINER="registry"

echo "${PASSWORD}" | regctl registry login ${REGISTRY_URL} -u "${USERNAME}" --pass-stdin
./cleanup_images.sh
