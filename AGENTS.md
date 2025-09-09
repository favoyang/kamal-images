# AGENTS.md

## Adding new images

When adding a new Docker image to this project:

- Create directory: `mkdir [image-name]`
- Create `[image-name]/Dockerfile` with `LABEL service="[service-name]"`
- Add entry to `.github/config/images.yml`
- Create `.github/workflows/build-[image-name].yml`
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

## Key requirements

- Always add `LABEL service="[service-name]"` to Dockerfile
- Copy existing workflow structure exactly
- Default to `linux/amd64` architecture
- Test with `./scripts/test-update.sh` before committing
