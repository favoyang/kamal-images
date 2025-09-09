#!/bin/bash
set -euo pipefail

# Test script to easily test the update-base-image.sh script locally
# This reads from the configuration file and tests each image

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Testing base image update script..."
echo "Project root: $PROJECT_ROOT"
echo ""

# Check if yq is available
if ! command -v yq >/dev/null 2>&1; then
    echo "Installing yq for YAML parsing..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update && sudo apt-get install -y yq
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew >/dev/null 2>&1; then
            brew install yq
        else
            echo "Please install yq manually: brew install yq"
            exit 1
        fi
    else
        echo "Please install yq manually. On Ubuntu/Debian: sudo apt-get install yq"
        exit 1
    fi
fi

# Parse configuration file
CONFIG_FILE="$PROJECT_ROOT/.github/config/images.yml"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

echo "Reading configuration from: $CONFIG_FILE"
echo ""

# Get number of images
IMAGE_COUNT=$(yq -r '.images | length' "$CONFIG_FILE")
echo "Found $IMAGE_COUNT image(s) to test:"
echo ""

# Test each image
for i in $(seq 0 $((IMAGE_COUNT - 1))); do
    NAME=$(yq -r ".images[$i].name" "$CONFIG_FILE")
    BASE_IMAGE=$(yq -r ".images[$i].base_image" "$CONFIG_FILE")
    DOCKERFILE_PATH=$(yq -r ".images[$i].dockerfile_path" "$CONFIG_FILE")
    
    echo "=== Testing Image $((i + 1))/$IMAGE_COUNT: $NAME ==="
    echo "Base Image: $BASE_IMAGE"
    echo "Dockerfile: $DOCKERFILE_PATH"
    echo ""
    
    # Run the update script in dry run mode
    cd "$PROJECT_ROOT"
    DRY_RUN=1 ./scripts/update-base-image.sh "$NAME" "$BASE_IMAGE" "$DOCKERFILE_PATH"
    
    echo ""
    echo "----------------------------------------"
    echo ""
done

echo "All tests completed!"
