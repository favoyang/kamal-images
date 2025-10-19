#!/bin/bash
set -euo pipefail

# Script to check and update Docker base image versions
# Usage: ./scripts/update-base-image.sh <image_name> <base_image> <dockerfile_path>

# Function to print output
log_info() {
    echo "[INFO] $1"
}

log_success() {
    echo "[SUCCESS] $1"
}

log_warning() {
    echo "[WARNING] $1"
}

log_error() {
    echo "[ERROR] $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <image_name> <base_image> <dockerfile_path>"
    echo ""
    echo "Arguments:"
    echo "  image_name      Name of the image (e.g., caddy-cloudflare-geoip-ratelimit)"
    echo "  base_image      Base Docker image (e.g., caddy)"
    echo "  dockerfile_path Path to the Dockerfile (e.g., caddy-cloudflare-geoip-ratelimit/Dockerfile)"
    echo ""
    echo "Example:"
    echo "  $0 caddy-cloudflare-geoip-ratelimit caddy caddy-cloudflare-geoip-ratelimit/Dockerfile"
    echo ""
    echo "Environment variables:"
    echo "  DRY_RUN=1       Only check versions, don't update files"
    echo "  DEBUG=1         Enable debug output"
}

# Function to check if required tools are available
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    if ! command -v grep >/dev/null 2>&1; then
        missing_deps+=("grep")
    fi
    
    if ! command -v sed >/dev/null 2>&1; then
        missing_deps+=("sed")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_info "Please install the missing dependencies and try again"
        exit 1
    fi
}

# Function to get current version from Dockerfile
get_current_version() {
    local dockerfile_path="$1"
    local base_image="$2"
    
    if [ ! -f "$dockerfile_path" ]; then
        log_error "Dockerfile not found: $dockerfile_path"
        return 1
    fi
    
    local current_version
    current_version=$(grep -Eo "${base_image}:[0-9]+\.[0-9]+\.[0-9]+" "$dockerfile_path" | head -1 | cut -d ':' -f2)
    
    if [ -z "$current_version" ]; then
        log_error "Could not extract current version from $dockerfile_path"
        log_info "Looking for pattern: ${base_image}:X.Y.Z"
        return 1
    fi
    
    echo "$current_version"
}

# Function to get latest version from various registries
get_latest_version() {
    local base_image="$1"
    
    # Check if it's a GitHub Container Registry image
    if [[ "$base_image" == ghcr.io/* ]]; then
        get_latest_version_ghcr "$base_image"
    else
        get_latest_version_dockerhub "$base_image"
    fi
}

# Function to get latest version from Docker Hub
get_latest_version_dockerhub() {
    local base_image="$1"
    local api_url="https://registry.hub.docker.com/v2/repositories/library/${base_image}/tags/?page_size=100"
    
    log_info "Fetching latest version for $base_image from Docker Hub..." >&2
    
    local latest_version
    latest_version=$(curl -s "$api_url" | \
        jq -r '.results[] | select(.name | test("^[0-9]+\\.[0-9]+\\.[0-9]+$")) | .name' | \
        sort -V | tail -1)
    
    if [ -z "$latest_version" ]; then
        log_error "Could not fetch latest version for $base_image" >&2
        return 1
    fi
    
    echo "$latest_version"
}

# Function to get latest version from GitHub Container Registry
get_latest_version_ghcr() {
    local base_image="$1"
    
    log_info "Fetching latest version for $base_image from GitHub Container Registry..." >&2
    
    # Extract owner and repo from ghcr.io/owner/repo/package format
    # For ghcr.io/owner/repo/package, we want owner/repo
    local ghcr_path="${base_image#ghcr.io/}"
    local owner="${ghcr_path%%/*}"
    local remaining="${ghcr_path#*/}"
    local repo="${remaining%%/*}"
    
    # For GitHub Container Registry, we'll use the GitHub API to get releases
    local api_url="https://api.github.com/repos/${owner}/${repo}/releases/latest"
    
    local latest_version
    latest_version=$(curl -s "$api_url" | \
        jq -r '.tag_name // empty' | \
        sed 's/^v//')  # Remove 'v' prefix if present
    
    if [ -z "$latest_version" ]; then
        log_warning "Could not fetch latest version from GitHub releases for $base_image" >&2
        log_info "This might be expected for images that don't use GitHub releases for versioning" >&2
        return 1
    fi
    
    echo "$latest_version"
}

# Function to update Dockerfile
update_dockerfile() {
    local dockerfile_path="$1"
    local base_image="$2"
    local current_version="$3"
    local latest_version="$4"
    
    log_info "Updating $dockerfile_path from $current_version to $latest_version"
    
    if [ "${DRY_RUN:-0}" = "1" ]; then
        log_warning "DRY_RUN mode: Would update $dockerfile_path"
        log_info "Would replace: ${base_image}:${current_version} -> ${base_image}:${latest_version}"
        return 0
    fi
    
    # Create backup
    cp "$dockerfile_path" "${dockerfile_path}.bak"
    log_info "Created backup: ${dockerfile_path}.bak"
    
    # Replace all occurrences of the current version with the latest version
    # Use | as delimiter to avoid conflicts with forward slashes in base image names
    sed -i "s|${base_image}:${current_version}|${base_image}:${latest_version}|g" "$dockerfile_path"
    
    # Verify the update was successful
    local updated_version
    updated_version=$(get_current_version "$dockerfile_path" "$base_image")
    
    if [ "$updated_version" = "$latest_version" ]; then
        log_success "Successfully updated Dockerfile to version $latest_version"
        rm "${dockerfile_path}.bak"  # Remove backup if successful
        return 0
    else
        log_error "Failed to update Dockerfile. Restoring backup..."
        mv "${dockerfile_path}.bak" "$dockerfile_path"
        return 1
    fi
}

# Function to show diff if in debug mode
show_diff() {
    local dockerfile_path="$1"
    
    if [ "${DEBUG:-0}" = "1" ] && [ -f "${dockerfile_path}.bak" ]; then
        log_info "Changes made to $dockerfile_path:"
        diff "${dockerfile_path}.bak" "$dockerfile_path" || true
    fi
}

# Main function
main() {
    # Check arguments
    if [ $# -ne 3 ]; then
        log_error "Invalid number of arguments"
        show_usage
        exit 1
    fi
    
    local image_name="$1"
    local base_image="$2"
    local dockerfile_path="$3"
    
    log_info "Starting base image update check for $image_name"
    log_info "Base image: $base_image"
    log_info "Dockerfile: $dockerfile_path"
    
    # Check dependencies
    check_dependencies
    
    # Get current version
    log_info "Getting current version from Dockerfile..."
    local current_version
    if ! current_version=$(get_current_version "$dockerfile_path" "$base_image"); then
        exit 1
    fi
    log_info "Current version: $current_version"
    
    # Get latest version
    local latest_version
    if ! latest_version=$(get_latest_version "$base_image"); then
        exit 1
    fi
    log_info "Latest version: $latest_version"
    
    # Compare versions
    if [ "$current_version" = "$latest_version" ]; then
        log_success "Version is up to date: $current_version"
        echo "UP_TO_DATE=true"
        exit 0
    fi
    
    log_warning "Version update available: $current_version -> $latest_version"
    echo "UP_TO_DATE=false"
    echo "CURRENT_VERSION=$current_version"
    echo "LATEST_VERSION=$latest_version"
    
    # Update Dockerfile
    if update_dockerfile "$dockerfile_path" "$base_image" "$current_version" "$latest_version"; then
        show_diff "$dockerfile_path"
        echo "UPDATE_SUCCESS=true"
        log_success "Base image update completed successfully!"
    else
        echo "UPDATE_SUCCESS=false"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
