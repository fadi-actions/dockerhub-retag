#!/bin/ash

TMPFILE=$(mktemp)
TMPFILE2=$(mktemp)

e() {
  rm $TMPFILE $TMPFILE2
  exit $1
}

## retrieve token from dockerhub to do operations
echo "retrieving token from https://auth.docker.io/token?service=registry.docker.io&scope=repository:$INPUT_DOCKERHUB_REPO:pull,push"
TOKEN=$(curl -sL -u "$INPUT_DOCKERHUB_USERNAME:$INPUT_DOCKERHUB_PASSWORD" "https://auth.docker.io/token?service=registry.docker.io&scope=repository:$INPUT_DOCKERHUB_REPO:pull,push" | tee $TMPFILE | jq --raw-output .token)
if [ -z "$TOKEN" ]; then
  echo "error recieving token:"
  cat $TMPFILE
  e 1
else
  echo "token recieved"
fi

## retrieve manifest of docker image
echo "retrieving manifest from https://index.docker.io/v2/$INPUT_DOCKERHUB_REPO/manifests/$INPUT_OLD_TAG"
RC=$(curl -sL -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.docker.distribution.manifest.v2+json"  "https://index.docker.io/v2/$INPUT_DOCKERHUB_REPO/manifests/$INPUT_OLD_TAG" -o $TMPFILE -w "%{http_code}")
if [ "$RC" -eq 200 ]; then
  echo "manifest for $INPUT_OLD_TAG retrieved successfully as docker image"
else
  echo "error retrieving manifest for $INPUT_OLD_TAG as docker image. trying oci. "
  cat $TMPFILE
  RC=$(curl -sL -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.oci.image.index.v1+json"  "https://index.docker.io/v2/$INPUT_DOCKERHUB_REPO/manifests/$INPUT_OLD_TAG" -o $TMPFILE -w "%{http_code}")
  if [ "$RC" -eq 200 ]; then
    echo "manifest for $INPUT_OLD_TAG retrieved successfully as oci image"
  else
    echo "error retrieving manifest for $INPUT_OLD_TAG as oci image."
    cat $TMPFILE
    e 2
  fi
fi

## push manifest with new tag to dockerhub
echo "pushing manifest to https://index.docker.io/v2/$INPUT_DOCKERHUB_REPO/manifests/$INPUT_NEW_TAG"
RC=$(curl -sL -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/vnd.docker.distribution.manifest.v2+json"  "https://index.docker.io/v2/$INPUT_DOCKERHUB_REPO/manifests/$INPUT_NEW_TAG" -X PUT -d "@$TMPFILE" -o $TMPFILE2 -w "%{http_code}")
if [ "$RC" -eq 201 ]; then
  echo "new tag $INPUT_NEW_TAG created successfully as docker image"
else
  echo "error creating new tag $INPUT_NEW_TAG as docker image. trying oci"
  cat $TMPFILE2
  RC=$(curl -sL -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/vnd.oci.image.index.v1+json"  "https://index.docker.io/v2/$INPUT_DOCKERHUB_REPO/manifests/$INPUT_NEW_TAG" -X PUT -d "@$TMPFILE" -o $TMPFILE2 -w "%{http_code}")
  if [ "$RC" -eq 201 ]; then
    echo "new tag $INPUT_NEW_TAG created successfully as docker oci"
  else
    echo "error creating new tag $INPUT_NEW_TAG as docker oci"
    cat $TMPFILE2
    e 3
  fi
fi


## cleanup
rm $TMPFILE $TMPFILE2
exit 0
