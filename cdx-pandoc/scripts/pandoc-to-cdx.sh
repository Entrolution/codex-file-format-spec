#!/usr/bin/env bash
#
# pandoc-to-cdx.sh - Convert documents to Codex format using Pandoc
#
# Usage:
#   ./pandoc-to-cdx.sh input.md output.cdx
#   ./pandoc-to-cdx.sh input.docx output.cdx
#
# This script:
# 1. Runs Pandoc with the Codex custom writer
# 2. Extracts the JSON output into proper directory structure
# 3. Computes content hash and updates manifest
# 4. Packages into a .cdx ZIP archive
#
# Requirements:
# - Pandoc 2.11+ (for custom Lua writers)
# - jq (for JSON processing)
# - sha256sum or shasum (for hashing)

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRITER_DIR="$(dirname "$SCRIPT_DIR")"
CODEX_WRITER="$WRITER_DIR/codex.lua"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $(basename "$0") <input_file> <output.cdx>"
    echo ""
    echo "Convert any Pandoc-supported format to Codex Document Format (.cdx)"
    echo ""
    echo "Arguments:"
    echo "  input_file   Source document (Markdown, LaTeX, Word, etc.)"
    echo "  output.cdx   Output Codex archive"
    echo ""
    echo "Options:"
    echo "  -h, --help   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") document.md output.cdx"
    echo "  $(basename "$0") paper.tex paper.cdx"
    echo "  $(basename "$0") report.docx report.cdx"
    exit 1
}

error() {
    echo -e "${RED}Error:${NC} $1" >&2
    exit 1
}

warn() {
    echo -e "${YELLOW}Warning:${NC} $1" >&2
}

info() {
    echo -e "${GREEN}==>${NC} $1"
}

# Check dependencies
check_dependencies() {
    if ! command -v pandoc &> /dev/null; then
        error "pandoc is required but not installed"
    fi

    if ! command -v jq &> /dev/null; then
        error "jq is required but not installed"
    fi

    # Check for sha256sum or shasum
    if command -v sha256sum &> /dev/null; then
        SHA_CMD="sha256sum"
    elif command -v shasum &> /dev/null; then
        SHA_CMD="shasum -a 256"
    else
        error "sha256sum or shasum is required but not installed"
    fi

    if ! command -v zip &> /dev/null; then
        error "zip is required but not installed"
    fi
}

# Compute SHA-256 hash of a file
compute_hash() {
    local file="$1"
    $SHA_CMD "$file" | cut -d' ' -f1
}

# Main conversion function
convert() {
    local input_file="$1"
    local output_file="$2"

    if [[ ! -f "$input_file" ]]; then
        error "Input file not found: $input_file"
    fi

    if [[ ! -f "$CODEX_WRITER" ]]; then
        error "Codex writer not found: $CODEX_WRITER"
    fi

    # Create temp directory
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf '$temp_dir'" EXIT

    info "Converting $input_file to Codex format..."

    # Run Pandoc with the Codex writer
    local json_output="$temp_dir/output.json"
    if ! pandoc "$input_file" -t "$CODEX_WRITER" -o "$json_output" 2>&1; then
        error "Pandoc conversion failed"
    fi

    # Create directory structure
    info "Creating Codex directory structure..."
    mkdir -p "$temp_dir/cdx/content"
    mkdir -p "$temp_dir/cdx/metadata"

    # Extract content section
    jq '.content' "$json_output" > "$temp_dir/cdx/content/document.json"

    # Extract dublin_core section
    jq '.dublin_core' "$json_output" > "$temp_dir/cdx/metadata/dublin-core.json"

    # Compute content hash
    info "Computing content hash..."
    local content_hash
    content_hash=$(compute_hash "$temp_dir/cdx/content/document.json")

    # Extract and update manifest with correct hash
    jq --arg hash "sha256:$content_hash" \
       '.manifest | .content.hash = $hash' \
       "$json_output" > "$temp_dir/cdx/manifest.json"

    # Create the .cdx archive
    info "Creating Codex archive..."
    local output_path
    output_path="$(cd "$(dirname "$output_file")" && pwd)/$(basename "$output_file")"

    # Remove existing output file
    rm -f "$output_path"

    # Create ZIP with manifest.json as first file (spec requirement)
    (cd "$temp_dir/cdx" && zip -q -X "$output_path" manifest.json)
    (cd "$temp_dir/cdx" && zip -q -r -X "$output_path" content metadata)

    info "Created: $output_file"

    # Verify the archive
    if command -v cdx &> /dev/null; then
        info "Validating with cdx-cli..."
        if cdx validate "$output_path"; then
            info "Validation passed!"
        else
            warn "Validation failed - check the output file"
        fi
    fi
}

# Parse arguments
if [[ $# -lt 2 ]]; then
    usage
fi

case "${1:-}" in
    -h|--help)
        usage
        ;;
esac

INPUT_FILE="$1"
OUTPUT_FILE="$2"

check_dependencies
convert "$INPUT_FILE" "$OUTPUT_FILE"
