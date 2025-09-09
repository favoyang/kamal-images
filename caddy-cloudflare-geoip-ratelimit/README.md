# Caddy Docker build with Cloudflare DNS/IPs, GeoIP Filter and Rate Limit modules

[![GitHub Container Registry](https://img.shields.io/badge/GHCR%20-%20favoyang%2Fkamal--images%2Fcaddy--cloudflare--geoip--ratelimit%20-%20%230db7ed?style=flat&logo=docker)](https://ghcr.io/favoyang/kamal-images/caddy-cloudflare-geoip-ratelimit)
[![GitHub build status](https://img.shields.io/github/actions/workflow/status/favoyang/kamal-images/build-caddy-cloudflare-geoip-ratelimit.yml?label=Build)](https://github.com/favoyang/kamal-images/actions/workflows/build-caddy-cloudflare-geoip-ratelimit.yml)

This image is updated automatically by GitHub Actions when changes are made to the Dockerfile using the official [Caddy Docker](https://hub.docker.com/_/caddy) image with added Kamal service label `service="caddy"` and the following modules:

- **Cloudflare DNS**: for Cloudflare DNS-01 ACME validation support | [caddy-dns/cloudflare](https://github.com/caddy-dns/cloudflare)
- **Cloudflare IPs**: to retrieve Cloudflare's current [IP ranges](https://www.cloudflare.com/ips/) | [WeidiDeng/caddy-cloudflare-ip](https://github.com/WeidiDeng/caddy-cloudflare-ip)
- **GeoIP Filter**: to allow or block traffic from specific regions based on [Maxmind GeoLite2 database](https://dev.maxmind.com/geoip/geolite2-free-geolocation-data) | [porech/caddy-maxmind-geolocation](https://github.com/porech/caddy-maxmind-geolocation)
- **Rate Limit**: to control request rates and prevent abuse | [mholt/caddy-ratelimit](https://github.com/mholt/caddy-ratelimit)

## Usage

Docker builds are available at GitHub Container Registry:

- **GitHub Packages**: `docker pull ghcr.io/favoyang/kamal-images/caddy-cloudflare-geoip-ratelimit:latest`

### Tags

The following tags are available for the `ghcr.io/favoyang/kamal-images/caddy-cloudflare-geoip-ratelimit` image:

- `latest`
- `<version>` (eg: `2.10.2`, including: `2.10`, `2`, etc.)
