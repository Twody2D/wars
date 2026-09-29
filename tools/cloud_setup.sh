#!/usr/bin/env bash
# Setup script for a Claude Code cloud session (Linux): installs Godot 4.7.2
# headless, imports the project once so tests can run.
# Paste into the environment's "Setup script" field (claude.ai/code), or run:
#   bash tools/cloud_setup.sh
# Rendering (screenshots, Movie Maker) and the web export with our custom
# template are NOT possible in the cloud — they are done on Twody's PC.
set -euo pipefail

VERSION="4.7.2-stable"
DIR="/opt/godot"
BIN="$DIR/Godot_v${VERSION}_linux.x86_64"

if [ ! -x "$BIN" ]; then
	mkdir -p "$DIR"
	curl -sSL -o /tmp/godot.zip \
		"https://github.com/godotengine/godot/releases/download/${VERSION}/Godot_v${VERSION}_linux.x86_64.zip"
	unzip -q -o /tmp/godot.zip -d "$DIR"
	rm /tmp/godot.zip
fi
ln -sf "$BIN" /usr/local/bin/godot

# First import (creates .godot/), so scripts and tests see all resources.
if [ -f project.godot ]; then
	godot --headless --path . --import >/dev/null 2>&1 || true
fi
echo "Godot ready: $(godot --version)"
