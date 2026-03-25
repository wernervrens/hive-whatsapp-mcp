# Stage 1: Build Go bridge
FROM golang:1.25-bookworm AS go-builder

WORKDIR /build/whatsapp-bridge

COPY whatsapp-bridge/ ./
RUN CGO_ENABLED=1 GOOS=linux go build -mod=vendor -o whatsapp-bridge .

# Stage 2: Final image with Python + Go binary
FROM python:3.11-slim-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libc6-dev \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app

# Copy Go binary
COPY --from=go-builder /build/whatsapp-bridge/whatsapp-bridge ./whatsapp-bridge/whatsapp-bridge

# Copy Python MCP server
COPY whatsapp-mcp-server/ ./whatsapp-mcp-server/

# Install Python dependencies
WORKDIR /app/whatsapp-mcp-server
RUN uv sync --frozen

WORKDIR /app/whatsapp-bridge

# Volume for persistent WhatsApp session and message database
VOLUME ["/app/whatsapp-bridge/store"]

EXPOSE 8080

CMD ["./whatsapp-bridge"]
