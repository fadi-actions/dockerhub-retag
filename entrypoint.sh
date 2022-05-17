#!/bin/ash

TMPFILE=$(mktemp)

## retrieve token from dockerhub to do operations
TOKEN=$(curl -sL -u "$INPUT_DOCKERHUB_USERNAME:$INPUT_DOCKERHUB_PASSWORD" "https://auth.docker.io/token?service=registry.docker.io&scope=repository:$INPUT_DOCKERHUB_REPO:pull,push" | jq --raw-output .token)

## retrieve manifest of docker image
curl -sL -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.docker.distribution.manifest.v2+json"  "https://index.docker.io/v2/$INPUT_DOCKERHUB_REPO/manifests/$INPUT_OLD_TAG" > $TMPFILE

## push manifest with new tag to dockerhub
curl -sL -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/vnd.docker.distribution.manifest.v2+json"  "https://registry-1.docker.io/v2/$INPUT_DOCKERHUB_REPO/manifests/$INPUT_NEW_TAG" -X PUT -d "@$TMPFILE"

## cleanup
rm $TMPFILE
