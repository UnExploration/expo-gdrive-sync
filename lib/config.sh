#!/bin/bash

# Platform Detection
detect_platform() {
    case "$(uname -s)" in
        Linux*)     echo "linux" ;;
        Darwin*)    echo "macos" ;;
        CYGWIN*|MINGW*|MSYS*)    echo "windows" ;;
        *)          echo "unknown" ;;
    esac
}

# Find Expo project root
# This tools package is designed to be used as a submodule in an Expo project
# So we look for app.json in the parent directory of the tools root
find_project_root() {
    local tools_root="$1"

    # Check parent of TOOLS_ROOT first (submodule case - most common)
    if [ -f "$(dirname "$tools_root")/app.json" ]; then
        echo "$(dirname "$tools_root")"
    # Then check if TOOLS_ROOT itself is the project root (standalone case)
    elif [ -f "$tools_root/app.json" ]; then
        echo "$tools_root"
    # Finally check current directory
    elif [ -f "$PWD/app.json" ]; then
        echo "$PWD"
    else
        return 1
    fi
}

PLATFORM=$(detect_platform)

# Google Drive Configuration
GDRIVE_REMOTE="gdrive:"

# Build Configuration
# Use project-relative path by default (works across all platforms)
# Falls back to system temp if EXPO_BUILD_OUTPUT is set
if [ -n "$EXPO_BUILD_OUTPUT" ]; then
    TEMP_DIR="$EXPO_BUILD_OUTPUT"
elif [ -n "$TEMP_DIR" ]; then
    # Allow override via environment variable
    :  # Keep existing TEMP_DIR
else
    # Default to ./builds directory relative to the Expo project root
    # Note: This logic works for config.sh being sourced, assumes lib/ is in tools root
    CONFIG_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CONFIG_TOOLS_ROOT="$(dirname "$CONFIG_LIB_DIR")"
    if CONFIG_PROJECT_ROOT=$(find_project_root "$CONFIG_TOOLS_ROOT"); then
        TEMP_DIR="$CONFIG_PROJECT_ROOT/builds"
    else
        # Fallback if we can't find project root
        TEMP_DIR="$CONFIG_TOOLS_ROOT/builds"
    fi
fi

# Upload Configuration
DEFAULT_UPLOAD_FOLDER="Builds"

# Color codes for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Load local overrides if they exist
[ -f "$SCRIPT_DIR/config.local.sh" ] && source "$SCRIPT_DIR/config.local.sh" || true
