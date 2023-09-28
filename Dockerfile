# syntax=docker/dockerfile:1

# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/engine/reference/builder/

################################################################################
# Create a stage for building the application.

ARG RUST_VERSION=1.70
ARG APP_NAME=inspectord
# FROM rust:${RUST_VERSION}-slim-bookworm AS build
FROM rustlang/rust:nightly-bookworm-slim AS build
ARG APP_NAME
WORKDIR /app

RUN apt-get update && apt-get install -y \
     libbpf-dev \
&& apt-get clean && rm -rf /var/lib/apt/lists/*

# Build the application.
# Leverage a cache mount to /usr/local/cargo/registry/
# for downloaded dependencies and a cache mount to /app/target/ for 
# compiled dependencies which will speed up subsequent builds.
# Leverage a bind mount to the src directory to avoid having to copy the
# source code into the container. Once built, copy the executable to an
# output directory before the cache mounted /app/target is unmounted.
RUN --mount=type=bind,source=Cargo.toml,target=Cargo.toml \
    --mount=type=bind,source=Cargo.lock,target=Cargo.lock \
    --mount=type=bind,source=inspectord,target=inspectord \
    --mount=type=bind,source=inspectord-ebpf,target=inspectord-ebpf \
    --mount=type=bind,source=inspectord-common,target=inspectord-common \
    --mount=type=bind,source=xtask,target=xtask \
    --mount=type=bind,source=.cargo,target=.cargo\
    --mount=type=cache,target=/app/target/ \
    --mount=type=cache,target=/usr/local/cargo/registry/ \
    <<EOF
set -e
echo "### Installing eBPF tools ###"
rustup toolchain uninstall nightly
rustup toolchain install nightly
cargo install bpf-linker cargo-xtask
echo "### Building eBPF Bytecodes ###"
cargo xtask build-ebpf --release

ls target/
ls target/bpfel-unknown-none/

echo "### Building eBPF Application ###"
cargo build --locked --release
cp ./target/release/$APP_NAME /bin/inspectord
EOF

################################################################################
# Create a new stage for running the application that contains the minimal
# runtime dependencies for the application. This often uses a different base
# image from the build stage where the necessary files are copied from the build
# stage.
#
# The example below uses the debian bullseye image as the foundation for running the app.
# By specifying the "bullseye-slim" tag, it will also use whatever happens to be the
# most recent version of that tag when you build your Dockerfile. If
# reproducability is important, consider using a digest
# (e.g., debian@sha256:ac707220fbd7b67fc19b112cee8170b41a9e97f703f588b2cdbbcdcecdd8af57).
FROM debian:bookworm-slim AS final

# Copy the executable from the "build" stage.
COPY --from=build /bin/inspectord /bin/

# Expose the port that the application listens on.
EXPOSE 1192

# What the container should run when it is started.
CMD ["/bin/inspectord"]
