#!/bin/bash
set -Eeuo pipefail

PATH=/usr/local/bin:$PATH
PATH=/opt/homebrew/bin:$PATH

if [ -z ${REGISTRY_URL:-} ]; then
    echo "REGISTRY_URL must be set. Use cleanup.sh or cleanup-dev.sh"
    exit 1
fi
echo "REGISTRY_URL: $REGISTRY_URL"

if [ -z ${CONTAINER:-} ]; then
    echo "CONTAINER must be set. Use cleanup.sh or cleanup-dev.sh"
    exit 1
fi
echo "CONTAINER: $CONTAINER"

KEEP_TAGS=3
echo "Keeping last ${KEEP_TAGS} tags per repository"
echo

echo "repos:"
REPOS=$(regctl repo list ${REGISTRY_URL})
echo "${REPOS}"
echo

for REPO in ${REPOS}; do
    echo "repo - ${REPO}"
    TAGS=$(curl -s "${REGISTRY_URL}/v2/${REPO}/tags/list" | jq -r '.tags // [] | sort | .[]')
    TO_DELETE=$(echo "${TAGS}" | ghead -n -${KEEP_TAGS})

    echo "tags to delete:"
    echo "${TO_DELETE}"
    echo

    for TAG in ${TO_DELETE}; do
        echo "tag - ${TAG}"
        echo "deleting tag"
        regctl tag delete ${REGISTRY_URL}/${REPO}:${TAG}

        echo "removing image"
        docker rmi ${REGISTRY_URL}/${REPO}:${TAG} > /dev/null
        echo
    done
done

echo "garbage collecting"
docker exec $CONTAINER bin/registry garbage-collect /etc/docker/registry/config.yml --delete-untagged
