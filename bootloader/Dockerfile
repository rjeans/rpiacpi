# Use a lightweight Debian base
FROM debian:bookworm

LABEL maintainer="you@example.com"
LABEL description="Build environment for EDK2 DXEs with ACPI SSDT support via modern iasl"

# Install only what you need
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    bison \
    flex \
    uuid-dev \
    vim \
    qemu-utils \
    git \
    gcc-11 \
    g++-11 \
    python3 \
    curl \
    acpica-tools \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clean up build environment to keep image lean
RUN rm -rf  /var/cache/apt/* /tmp/*

# Set default working directory for mounted volumes or dev
WORKDIR /workspace

# Default entrypoint
CMD ["bash"]

