#!/bin/bash

IMAGE_NAME="badvpn_builder"
CONTAINER_NAME="badvpn_build_container"
OUTPUT_DIR="$(pwd)/badvpn_bin"

echo "Building Docker image..."
docker build -t $IMAGE_NAME .

mkdir -p "$OUTPUT_DIR"

echo "Running container to build and extract BadVPN binaries..."
docker run --name $CONTAINER_NAME $IMAGE_NAME bash -c "cp -r /output /host-output"
docker cp "$CONTAINER_NAME:/output/." "$OUTPUT_DIR"

echo "Cleaning up..."
docker rm $CONTAINER_NAME
docker rmi $IMAGE_NAME

echo "BadVPN binaries have been extracted to: $OUTPUT_DIR"
