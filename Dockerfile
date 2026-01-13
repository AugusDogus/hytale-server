# Hytale Server Docker Image
# Inspired by itzg/minecraft-server for familiar configuration

ARG BASE_IMAGE=eclipse-temurin:25-jdk
FROM ${BASE_IMAGE}

LABEL maintainer="your-email@example.com"
LABEL description="Hytale Dedicated Server"
LABEL version="1.0"

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    ca-certificates \
    gosu \
    jq \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Create hytale user with UID/GID 1001 (1000 is taken by ubuntu in base image)
RUN groupadd -g 1001 hytale \
    && useradd -u 1001 -g 1001 -d /data -s /bin/bash hytale

# Set working directory
WORKDIR /data

# Create necessary directories
RUN mkdir -p /data/mods /data/universe /data/logs /data/.cache /opt/hytale/downloader /opt/hytale/game \
    && chown -R hytale:hytale /data /opt/hytale

# Download and extract the Hytale Downloader CLI
RUN curl -fsSL https://downloader.hytale.com/hytale-downloader.zip -o /tmp/hytale-downloader.zip \
    && unzip /tmp/hytale-downloader.zip -d /tmp/downloader \
    && mv /tmp/downloader/hytale-downloader-linux-amd64 /opt/hytale/downloader/hytale-downloader \
    && chmod +x /opt/hytale/downloader/hytale-downloader \
    && rm -rf /tmp/hytale-downloader.zip /tmp/downloader \
    && chown -R hytale:hytale /opt/hytale

# ============================================================================
# Environment Variables
# ============================================================================

# User/Group configuration (itzg-style)
ENV UID=1001
ENV GID=1001

# Memory configuration
# Hytale requires at least 4GB - default view distance (384 blocks) equals ~24 Minecraft chunks
ENV MEMORY="4G"
ENV INIT_MEMORY=""
ENV MAX_MEMORY=""

# JVM options
ENV JVM_OPTS=""
ENV JVM_XX_OPTS=""

# Timezone
ENV TZ="UTC"

# Logging
ENV LOG_TIMESTAMP="true"

# ----------------------------------------------------------------------------
# Download Options
# ----------------------------------------------------------------------------
ENV AUTO_DOWNLOAD="true"
ENV PATCHLINE="release"

# ----------------------------------------------------------------------------
# Server Options (maps to actual Hytale server arguments)
# ----------------------------------------------------------------------------

# --bind (default: 0.0.0.0:5520)
ENV SERVER_PORT=5520

# --allow-op
ENV ALLOW_OP="false"

# --auth-mode (authenticated|offline)
ENV AUTH_MODE="authenticated"

# --backup, --backup-frequency, --backup-dir
ENV ENABLE_BACKUP="false"
ENV BACKUP_INTERVAL=30

# --disable-sentry (recommended for plugin development)
ENV DISABLE_SENTRY="false"

# --accept-early-plugins
ENV ACCEPT_EARLY_PLUGINS="false"

# Additional arguments passed directly to the server
ENV EXTRA_ARGS=""

# ----------------------------------------------------------------------------
# Docker Options
# ----------------------------------------------------------------------------

# Setup only mode - download files but don't start server
ENV SETUP_ONLY="false"

# ============================================================================

# Expose the default Hytale server port (UDP for QUIC protocol)
EXPOSE 5520/udp

# Volume for persistent data
VOLUME ["/data"]

# Copy scripts
COPY --chmod=755 scripts/ /opt/hytale/scripts/

# Create symlinks for helper commands
RUN ln -s /opt/hytale/scripts/send-to-console /usr/local/bin/send-to-console \
    && ln -s /opt/hytale/scripts/hytale-health /usr/local/bin/hytale-health

# Signal handling
STOPSIGNAL SIGTERM

# Health check
HEALTHCHECK --start-period=2m --interval=30s --timeout=10s --retries=3 \
    CMD /opt/hytale/scripts/hytale-health

ENTRYPOINT ["/opt/hytale/scripts/start"]
