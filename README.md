# Moltbot Docker Container

Docker container builds for [Moltbot](https://github.com/moltbot/moltbot) - a personal AI assistant.

## Overview

This repository provides automated Docker container builds for Moltbot. Since Moltbot doesn't provide official Docker images, this project clones the source and builds using their own Dockerfile/build process.

## Usage

### Pull from GitHub Container Registry

```bash
# Latest version (main branch)
docker pull ghcr.io/cermakjn/moltbot:latest

# Specific version
docker pull ghcr.io/cermakjn/moltbot:v2026.1.24
```

### Run the Container

```bash
docker run -d \
  --name moltbot \
  -p 18789:18789 \
  -p 18790:18790 \
  -v ~/.clawdbot:/home/node/.clawdbot \
  -v ~/clawd:/home/node/clawd \
  -e CLAWDBOT_GATEWAY_TOKEN=your-secret-token \
  ghcr.io/cermakjn/moltbot:latest \
  node dist/index.js gateway --bind lan --port 18789
```

### Environment Variables

| Variable | Description |
|----------|-------------|
| `CLAWDBOT_GATEWAY_TOKEN` | Authentication token for the gateway (required) |
| `TELEGRAM_BOT_TOKEN` | Telegram bot token |
| `DISCORD_BOT_TOKEN` | Discord bot token |

#### Generating CLAWDBOT_GATEWAY_TOKEN

```bash
# Using openssl
openssl rand -hex 32

# Or using Python
python3 -c 'import secrets; print(secrets.token_hex(32))'
```

### Volumes

| Path | Description |
|------|-------------|
| `/home/node/.clawdbot` | Configuration and credentials |
| `/home/node/clawd` | Agent workspace |

### First Run Setup

The container runs as `node` user (UID 1000). Create directories with correct permissions:

```bash
mkdir -p ~/.clawdbot ~/clawd
sudo chown -R 1000:1000 ~/.clawdbot ~/clawd
```

Run the onboard wizard to configure the gateway:

```bash
docker run -it --rm \
  -v ~/.clawdbot:/home/node/.clawdbot \
  -v ~/clawd:/home/node/clawd \
  ghcr.io/cermakjn/moltbot:latest \
  node dist/index.js onboard --no-install-daemon
```

When prompted:
- Gateway bind: `lan`
- Gateway auth: `token`
- Gateway token: (enter your token or generate one)
- Tailscale exposure: `Off`
- Install Gateway daemon: `No`

Then start the gateway:

```bash
docker run -d \
  --name moltbot \
  -p 18789:18789 \
  -p 18790:18790 \
  -v ~/.clawdbot:/home/node/.clawdbot \
  -v ~/clawd:/home/node/clawd \
  ghcr.io/cermakjn/moltbot:latest \
  node dist/index.js gateway --bind lan --port 18789
```

### Device Pairing

With `gateway.mode=local`, each new browser/device needs approval. Get the dashboard URL:

```bash
docker exec moltbot node dist/index.js dashboard --no-open
```

Open the URL in your browser. If you see "pairing required", approve the pending device:

```bash
# List pending pairing requests
docker exec moltbot node dist/index.js devices list

# Approve a request (use the Request ID from the list)
docker exec moltbot node dist/index.js devices approve <request-id>
```

## Creating a New Release

To build a container for a specific Moltbot version, create a tag matching the release:

```bash
git tag v2026.1.24
git push origin v2026.1.24
```

The GitHub Action will automatically build and push to `ghcr.io/cermakjn/moltbot:v2026.1.24`.

## Building Locally

```bash
# Build latest (main branch)
docker build -t moltbot:latest .

# Build specific version
docker build --build-arg MOLTBOT_VERSION=v2026.1.24 -t moltbot:v2026.1.24 .
```

## License

MIT. Moltbot itself is also [MIT licensed](https://github.com/moltbot/moltbot/blob/main/LICENSE).

## Links

- [Moltbot Repository](https://github.com/moltbot/moltbot)
- [Moltbot Documentation](https://docs.molt.bot/)
- [Moltbot Releases](https://github.com/moltbot/moltbot/releases)
