# AGENTS.md

## Adding new images

When adding a new Docker image to this project:

- Create directory: `mkdir [image-name]`
- Create `[image-name]/Dockerfile` with `LABEL service="[service-name]"`
- Add entry to `.github/config/images.yml`
- Create `.github/workflows/build-[image-name].yml` (simple wrapper that calls reusable workflow)
- Create `[image-name]/README.md` following existing pattern
- Update main `README.md` to include new image in "Images Included" section
- Test with `./scripts/test-update.sh`

## Registry support

- Docker Hub: Use image name only (e.g., `nginx`)
- GitHub Container Registry: Use full path (e.g., `ghcr.io/owner/repo/package`)

## Version parsing

- Docker Hub: `grep -oP '[image]:\K[0-9]+\.[0-9]+\.[0-9]+' $DOCKER_NAME/Dockerfile`
- GitHub Container Registry: `grep -oP 'ghcr\.io/[owner]/[repo]/[package]:\K[0-9]+\.[0-9]+\.[0-9]+' $DOCKER_NAME/Dockerfile`

## README template

Follow this exact structure for `[image-name]/README.md`:

```markdown
# [Image Name] with Kamal service label

[![GitHub Container Registry](https://img.shields.io/badge/GHCR%20-%20favoyang%2Fkamal--images%2F[image-name]%20-%20%230db7ed?style=flat&logo=docker)](https://ghcr.io/favoyang/kamal-images/[image-name])
[![GitHub build status](https://img.shields.io/github/actions/workflow/status/favoyang/kamal-images/build-[image-name].yml?label=Build)](https://github.com/favoyang/kamal-images/actions/workflows/build-[image-name].yml)

This image is updated automatically by GitHub Actions when changes are made to the Dockerfile using the official [Base Image](link-to-base) image with added Kamal service label `service="[service-name]"`.

## Usage

Docker builds are available at GitHub Container Registry:

- **GitHub Packages**: `docker pull ghcr.io/favoyang/kamal-images/[image-name]:latest`

### Tags

The following tags are available for the `ghcr.io/favoyang/kamal-images/[image-name]` image:

- `latest`
- `<version>` (eg: `1.0.0`, including: `1.0`, `1`, etc.)
```

## Workflow template

Create `.github/workflows/build-[image-name].yml` using this template:

```yaml
# Workflow to build and push [Image Name] Docker image to GitHub Container Registry
name: Build [image-name]

# Controls when the action will run
on:
  workflow_dispatch:  # allows to run the workflow manually from the Actions tab
  push:
    branches: main
    paths:
      - [image-name]/Dockerfile

# Permissions needed for this workflow
permissions:
  contents: read
  packages: write

jobs:
  build:
    uses: ./.github/workflows/build-image.yml
    with:
      docker_name: [image-name]
      docker_description: "[Description of the Docker image]"
      version_regex: '[appropriate-regex-pattern]'
      platforms: linux/amd64
```

## Key requirements

- Always add `LABEL service="[service-name]"` to Dockerfile
- Use the reusable workflow template above for new build workflows
- Choose appropriate `version_regex` pattern based on base image registry
- Default to `linux/amd64` architecture
- Test with `./scripts/test-update.sh` before committing
