# Copilot Instructions for Moltbot Docker Container

## Project Overview

This is a **Docker packaging repository** (not the Moltbot application itself). It provides automated builds of [Moltbot](https://github.com/moltbot/moltbot) Docker images, published to GitHub Container Registry at `ghcr.io/cermakjn/moltbot`.

## Architecture

```
Repository (this)          Upstream (moltbot/moltbot)
┌─────────────────┐        ┌────────────────────────┐
│ Dockerfile      │──git───│ Moltbot source code    │
│ GH Actions      │ clone  │ Node.js + pnpm + Bun   │
└─────────────────┘        └────────────────────────┘
         │
         ▼
   ghcr.io/cermakjn/moltbot:tag
```

The Dockerfile clones Moltbot source at a specific version, then builds using their toolchain (pnpm + Bun).

## Key Files

- [Dockerfile](../Dockerfile) - Multi-stage build: clone → build → slim production image
- [.github/workflows/build-and-push.yml](workflows/build-and-push.yml) - Tag-triggered CI/CD to GHCR

## Build Process

### Local Development
```bash
# Build latest (main branch)
docker build -t moltbot:latest .

# Build specific version (must match a moltbot release tag)
docker build --build-arg MOLTBOT_VERSION=v2026.1.24 -t moltbot:v2026.1.24 .
```

### Release Workflow
Push a git tag matching a Moltbot release to trigger automated builds:
```bash
git tag v2026.1.24 && git push origin v2026.1.24
```

## Dockerfile Patterns

- **Multi-stage build**: `alpine/git` (clone) → `node:22-bookworm` (build) → `node:22-bookworm-slim` (runtime)
- **Version parameterization**: `ARG MOLTBOT_VERSION=main` controls which upstream version to build
- **Optional packages**: `CLAWDBOT_DOCKER_APT_PACKAGES` ARG for additional system dependencies
- **Non-root execution**: Container runs as `node` user for security

## Upstream Dependencies

Moltbot uses:
- **pnpm** (via corepack) for package management
- **Bun** for build scripts
- Ports **18789** (gateway) and **18790** (secondary)
- Config volumes at `/home/node/.clawdbot` and `/home/node/clawd`

## First Run Setup

Moltbot requires initial configuration. On first container start you'll see:
```
Missing config. Run `clawdbot setup` or set gateway.mode=local (or pass --allow-unconfigured).
```

**Recommended: Run the onboard wizard** (configures gateway with auth):
```bash
docker run -it --rm \
  -v ~/.clawdbot:/home/node/.clawdbot \
  -v ~/clawd:/home/node/clawd \
  moltbot:latest node dist/index.js onboard --no-install-daemon
```
When prompted: Gateway bind → `lan`, Gateway auth → `token`, set your token, Tailscale → Off.

**Quick start** (skips proper gateway config):
```bash
docker run -it --rm -v ~/.clawdbot:/home/node/.clawdbot moltbot:latest node dist/index.js setup
# Then run with --allow-unconfigured flag
```

**Note**: Volume directories must be owned by UID 1000 (`chown -R 1000:1000 ~/.clawdbot`).

## When Making Changes

- Sync tag names with [Moltbot releases](https://github.com/moltbot/moltbot/releases)
- Test builds locally before pushing tags
- Keep slim production image - avoid adding dev dependencies to final stage
