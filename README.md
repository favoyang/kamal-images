# Kamal Images

## Personal Repository

This repository contains custom Docker images for personal use with Kamal deployments.

## Kamal Service Labels

Each image in this repository is designed to work with Kamal and requires appropriate service labels for deployment configuration.

## Images Included

- **[caddy-cloudflare-geoip-ratelimit](./caddy-cloudflare-geoip-ratelimit)**: Custom Caddy server with Cloudflare, GeoIP, and rate limiting capabilities

## Automated Updates

Base images are automatically checked for updates every Sunday and updated when new versions are available. To include new images in automated updates, add them to `.github/config/images.yml`. For local testing, run `./scripts/test-update.sh`.
