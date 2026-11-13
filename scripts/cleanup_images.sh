#!/bin/bash
set -Eeuo pipefail

PATH=/usr/local/bin:$PATH
PATH=/opt/homebrew/bin:$PATH
PATH=/home/linuxbrew/.linuxbrew/bin:$PATH

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

if [ "$DEV" = false ]; then
    set -a
    source "$CONFIG_DIR/.env"
    set +a
fi

if [ "$DEV" = true ]; then
    export REGISTRY_URL="registry.localhost"
    export CONTAINER="registry-dev"
    regctl registry set --tls disabled ${REGISTRY_URL}
else
    export REGISTRY_URL="registry.aarcot.com"
    export CONTAINER="registry"
    echo "${PASSWORD}" | regctl registry login ${REGISTRY_URL} -u "${USERNAME}" --pass-stdin
fi

KEEP_TAGS=3
echo "Keeping newest ${KEEP_TAGS} tags per repository"
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

    TAGS=$(echo "${TAGS}" | jq -r '.tags // [] | .[]')
    echo "Tags:"
    echo "${TAGS}"
    echo

    TAG_TIMESTAMPS=""
    for TAG in ${TAGS}; do
        # use timestamps to avoid inconsistencies in tag names
        if ! CREATED=$(regctl image inspect "${REGISTRY_URL}/${REPO}:${TAG}" \
            --format '{{if .Created}}{{.Created.UnixNano}}{{end}}') ||
            [[ ! "$CREATED" =~ ^-?[0-9]+$ ]]; then
            echo "Skipping repository ${REPO}: cannot read creation time for ${TAG}" >&2
            continue 2
        fi
        TAG_TIMESTAMPS+="${CREATED} ${TAG}"$'\n'
    done

    # newest first, then sort by tag name to break ties
    TO_DELETE=$(printf '%s' "$TAG_TIMESTAMPS" | LC_ALL=C sort -k1,1nr -k2,2 |
        awk -v keep="$KEEP_TAGS" 'NF && NR > keep {print $2}')
    echo "Tags to delete:"
    echo "${TO_DELETE}"

    for TAG in ${TO_DELETE}; do
        echo "Deleting tag - ${TAG}"
        regctl tag delete "${REGISTRY_URL}/${REPO}:${TAG}"
    done
    echo
done

echo "Garbage collecting"
docker exec $CONTAINER bin/registry garbage-collect /etc/docker/registry/config.yml --delete-untagged
echo

# clear in-memory cache
echo "Restarting registry"
docker restart $CONTAINER
echo
