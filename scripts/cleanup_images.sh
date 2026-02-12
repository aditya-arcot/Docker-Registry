#!/bin/bash
set -Eeuo pipefail

PATH=/usr/local/bin:$PATH
PATH=/opt/homebrew/bin:$PATH

DEV=false

while getopts "d" opt; do
    case "$opt" in
    d) DEV=true ;;
    \?) exit 1 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/.."
CONFIG_DIR="$BASE_DIR/config"

ENV_FILE=".env"
if [ "$DEV" = true ]; then
    ENV_FILE=".env.dev"
fi

set -a
source "$CONFIG_DIR/$ENV_FILE"
set +a

if [ "$DEV" = true ]; then
    export REGISTRY_URL="localhost:${REGISTRY_PORT}"
    export CONTAINER="registry-dev"
    regctl registry set --tls disabled ${REGISTRY_URL}
else
    export REGISTRY_URL="registry.${DOMAIN}"
    export CONTAINER="registry"
    echo "${PASSWORD}" | regctl registry login ${REGISTRY_URL} -u "${USERNAME}" --pass-stdin
fi

KEEP_TAGS=3
echo "Keeping last ${KEEP_TAGS} tags per repository"
echo

echo "Repos:"
REPOS=$(regctl repo list ${REGISTRY_URL})
echo "${REPOS}"
echo

for REPO in ${REPOS}; do
    echo "Repo - ${REPO}"
    if [[ "$REPO" == cache/* ]]; then
        echo "Skipping cache repository"
        echo
        continue
    fi

    if [ "$DEV" = true ]; then
        TAGS=$(curl -s "http://${REGISTRY_URL}/v2/${REPO}/tags/list")
    else
        TAGS=$(curl -u "${USERNAME}:${PASSWORD}" -s "https://${REGISTRY_URL}/v2/${REPO}/tags/list")
    fi

    TAGS=$(echo "${TAGS}" | jq -r '.tags // [] | sort | .[]')
    echo "Tags:"
    echo "${TAGS}"
    echo

    TO_DELETE=$(echo "${TAGS}" | ghead -n -${KEEP_TAGS})
    echo "Tags to delete:"
    echo "${TO_DELETE}"

    for TAG in ${TO_DELETE}; do
        echo "Deleting tag - ${TAG}"
        regctl tag delete ${REGISTRY_URL}/${REPO}:${TAG}
    done
    echo
done

echo "Garbage collecting"
docker exec $CONTAINER bin/registry garbage-collect /etc/docker/registry/config.yml --delete-untagged
echo

echo "Pruning docker system"
docker system prune -a --volumes -f
