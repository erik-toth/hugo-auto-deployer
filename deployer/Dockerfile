FROM alpine:latest

ARG HUGO_VERSION=0.159.1

RUN apk add --no-cache \
    git \
    openssh-client \
    ca-certificates \
    wget \
    tar \
    gettext \
    su-exec \
    tzdata \
    webhook \
    gcompat \
    libstdc++

ENV TZ=Europe/Vienna

RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
      x86_64)  HUGO_ARCH="amd64" ;; \
      aarch64) HUGO_ARCH="arm64" ;; \
      armv7l)  HUGO_ARCH="arm"   ;; \
      *) echo "Unsupported arch: $ARCH" && exit 1 ;; \
    esac && \
    URL="https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-${HUGO_ARCH}.tar.gz" && \
    echo "Downloading Hugo ${HUGO_VERSION} from: ${URL}" && \
    wget -O /tmp/hugo.tar.gz "${URL}" \
      || { echo "ERROR: Hugo download failed"; exit 1; } && \
    mkdir -p /tmp/hugo-extract && \
    tar -xzf /tmp/hugo.tar.gz -C /tmp/hugo-extract && \
    ls -la /tmp/hugo-extract/ && \
    HUGO_BIN=$(find /tmp/hugo-extract -type f -name 'hugo' | head -1) && \
    [ -n "$HUGO_BIN" ] || { echo "ERROR: hugo binary not in archive"; exit 1; } && \
    mv "$HUGO_BIN" /usr/local/bin/hugo && \
    chmod +x /usr/local/bin/hugo && \
    rm -rf /tmp/hugo.tar.gz /tmp/hugo-extract && \
    hugo version

RUN webhook --version && hugo version

WORKDIR /app

COPY hooks.json.tpl  /app/hooks.json.tpl
COPY deploy.sh       /app/deploy.sh
COPY entrypoint.sh   /app/entrypoint.sh

RUN chmod +x /app/deploy.sh /app/entrypoint.sh

RUN mkdir -p /public /app/repo

EXPOSE 9000

ENTRYPOINT ["/app/entrypoint.sh"]
