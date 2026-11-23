#!/usr/bin/env bash
# Placeholder dotfiles hook: proves Codespaces runs this script
# Real setup gets added one by one

MARKER="$HOME/dotfiles-hook-ran"

if ! date -u +"%Y-%m-%dT%H:%M:%SZ" >"$MARKER"; then
  echo "install.sh: could not write marker file $MARKER" >&2
  exit 1
fi

echo "install.sh: marker written to $MARKER"
exit 0
