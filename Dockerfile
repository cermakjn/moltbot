# Moltbot Docker Container
# Clones moltbot source and builds using their Dockerfile
# Based on: https://github.com/moltbot/moltbot

ARG MOLTBOT_VERSION=main

FROM alpine/git AS clone

ARG MOLTBOT_VERSION

WORKDIR /src

# Clone moltbot at specified version/branch
RUN git clone --depth 1 --branch ${MOLTBOT_VERSION} https://github.com/moltbot/moltbot.git .

# Build using moltbot's own Dockerfile
FROM node:22-bookworm AS builder

# Install Bun (required for build scripts)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app

# Copy cloned source
COPY --from=clone /src .

# Build using moltbot's build process
ARG CLAWDBOT_DOCKER_APT_PACKAGES=""
RUN if [ -n "$CLAWDBOT_DOCKER_APT_PACKAGES" ]; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $CLAWDBOT_DOCKER_APT_PACKAGES && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
    fi

RUN pnpm install --frozen-lockfile

ENV CLAWDBOT_A2UI_SKIP_MISSING=1
RUN pnpm build

ENV CLAWDBOT_PREFER_PNPM=1
RUN pnpm ui:install
RUN pnpm ui:build

# Production stage
FROM node:22-bookworm-slim

WORKDIR /app

COPY --from=builder /app .

ENV NODE_ENV=production

# Security: run as non-root user (node user exists in base image)
USER node

EXPOSE 18789 18790

CMD ["node", "dist/index.js"]
