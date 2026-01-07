#!/bin/bash

set -euo pipefail

PATH=/usr/local/bin:$PATH
PATH=/opt/homebrew/bin:$PATH

REGISTRY_URL="localhost:5001"
KEEP_TAGS=3

echo "disabling TLS"
regctl registry set --tls disabled ${REGISTRY_URL}
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
docker exec registry bin/registry garbage-collect /etc/docker/registry/config.yml --delete-untagged
