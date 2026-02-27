# ============================================================
# NeamForge Site Generator — Docker Build
# Multi-stage: compile Neam → minimal runtime with git
# ============================================================

# --- Stage 1: Builder ---
FROM neam-lang/neamc:latest AS builder

WORKDIR /build
COPY site_generator.neam .

# Compile the .neam source to bytecode
RUN neamc site_generator.neam -o site_generator.neamb

# --- Stage 2: Runtime ---
FROM neam-lang/runtime:latest

WORKDIR /home/neam

# Install git (needed for checkpoint: "git") and basic tools
RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*

# Copy compiled bytecode
COPY --from=builder /build/site_generator.neamb .

# Copy site spec and examples
COPY site-spec.json .
COPY examples/ ./examples/

# Create workspace directory
RUN mkdir -p workspace/output

# Initialize git repo in workspace for checkpoint
RUN cd workspace && git init && git config user.email "forge@neam" && git config user.name "NeamForge"

# Volume mount for workspace (persists generated site)
VOLUME ["/home/neam/workspace"]

# Run forge agent
# Override site-spec.json by mounting a different one at /home/neam/site-spec.json
ENTRYPOINT ["neam-forge", "--agent", "site_generator.neamb", "--name", "site_generator", "--workspace", "./workspace"]
CMD ["--verbose"]
