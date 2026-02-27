#!/usr/bin/env bash
# ============================================================
# run.sh — Run the NeamForge Site Generator locally
# Usage: ./run.sh [site-spec.json]
# ============================================================

set -euo pipefail

SPEC_FILE="${1:-site-spec.json}"
WORKSPACE="./workspace"
AGENT_FILE="site_generator.neam"

echo "========================================"
echo "  NeamForge Static Site Generator"
echo "========================================"
echo ""

# --- Pre-flight checks ---

# Check Neam is installed
if ! command -v neamc &> /dev/null; then
    echo "ERROR: 'neamc' not found. Install the Neam compiler first."
    echo "       See: https://github.com/neam-lang/neam"
    exit 1
fi

if ! command -v neam-forge &> /dev/null; then
    echo "ERROR: 'neam-forge' not found. Install the Neam runtime first."
    exit 1
fi

# Check Ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "ERROR: Ollama is not running. Start it with: ollama serve"
    exit 1
fi

# Check model is available
if ! ollama list | grep -q "llama3.1"; then
    echo "Model llama3.1 not found. Pulling now..."
    ollama pull llama3.1
fi

# Check spec file exists
if [ ! -f "$SPEC_FILE" ]; then
    echo "ERROR: Site spec not found: $SPEC_FILE"
    echo "Usage: ./run.sh [path-to-spec.json]"
    exit 1
fi

echo "Spec file:  $SPEC_FILE"
echo "Workspace:  $WORKSPACE"
echo ""

# --- Setup workspace ---

mkdir -p "$WORKSPACE/output"

# Copy spec to workspace
cp "$SPEC_FILE" "$WORKSPACE/site-spec.json"

# Initialize git in workspace (for checkpoint: "git")
if [ ! -d "$WORKSPACE/.git" ]; then
    cd "$WORKSPACE"
    git init
    git config user.email "forge@neam"
    git config user.name "NeamForge"
    cd ..
    echo "Initialized git repo in workspace."
fi

echo ""

# --- Compile ---

echo "Compiling $AGENT_FILE ..."
neamc "$AGENT_FILE" -o site_generator.neamb
echo "Compilation successful."
echo ""

# --- Run Forge ---

echo "Starting forge agent..."
echo "---"
neam-forge --agent site_generator.neamb \
           --name site_generator \
           --workspace "$WORKSPACE" \
           --max-iterations 30 \
           --verbose

# --- Done ---

echo ""
echo "========================================"
echo "  Generation Complete!"
echo "========================================"
echo ""
echo "Generated site is in: $WORKSPACE/output/"
echo ""
echo "To preview locally:"
echo "  cd $WORKSPACE/output && python3 -m http.server 3000"
echo "  Open http://localhost:3000"
echo ""
echo "To view git history of generation steps:"
echo "  cd $WORKSPACE && git log --oneline"
echo ""
