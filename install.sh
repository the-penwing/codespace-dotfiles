#!/usr/bin/env bash

fail() {
  echo "install.sh: $1" >&2
  exit 1
}

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)" || fail "could not find the dotfiles directory"

GPG_FPR="3949612C4B58A93F3DCD7488A11420689178B907"
GITHUB_USER="the-penwing"

NVIM_SRC="$HOME/.local/src/nixos-config"
NVIM_CONFIG="$HOME/.config/nvim"

NIX_PREFIX="/nix/var/nix/profiles/default"
NIX_PROFILE="$NIX_PREFIX/etc/profile.d/nix-daemon.sh"
NIX_BIN="$NIX_PREFIX/bin/nix"
NIX_DAEMON="$NIX_PREFIX/bin/nix-daemon"
NIX_SOCKET="/nix/var/nix/daemon-socket/socket"

# --- Step 1: Nix ---
if [ ! -x "$NIX_BIN" ]; then
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix |
    sh -s -- install --no-confirm || fail "Nix install failed"
fi
if [ -f "$NIX_PROFILE" ]; then
  # shellcheck source=/dev/null
  . "$NIX_PROFILE"
fi
export PATH="$NIX_PREFIX/bin:$PATH"

[ -x "$NIX_BIN" ] || fail "Nix binary not found at $NIX_BIN after install"

if [ ! -S "$NIX_SOCKET" ]; then
  # The log is written by this shell as your user, not by sudo, so the redirect is intended.
  # shellcheck disable=SC2024
  sudo "$NIX_DAEMON" >"$HOME/nix-daemon.log" 2>&1 &
  for _ in 1 2 3 4 5; do
    [ -S "$NIX_SOCKET" ] && break
    sleep 1
  done
  [ -S "$NIX_SOCKET" ] || fail "nix-daemon did not start; see $HOME/nix-daemon.log"
fi

command -v nix >/dev/null 2>&1 || fail "nix is installed but not on PATH"

# --- Step 2: GPG public key ---
KEY_FILE="$(mktemp)" || fail "could not create a temp file for the GPG key"

curl -fsSL -o "$KEY_FILE" "https://github.com/$GITHUB_USER.gpg" || fail "could not download GPG key from GitHub"
gpg --batch --import "$KEY_FILE" || fail "could not import GPG key"
rm -f "$KEY_FILE"

gpg --list-keys "$GPG_FPR" >/dev/null 2>&1 || fail "GPG key $GPG_FPR not found after import"

# --- Step 3: home-manager ---
nix run home-manager/master -- switch --flake "$DOTFILES_DIR#codespace" -b backup ||
  fail "home-manager switch failed"

# --- Step 4: Neovim config ---
if [ ! -d "$NVIM_SRC/.git" ]; then
  mkdir -p "$(dirname "$NVIM_SRC")" || fail "could not create $(dirname "$NVIM_SRC")"
  git clone --filter=blob:none --no-checkout --sparse \
    "https://github.com/$GITHUB_USER/nixos-config" "$NVIM_SRC" ||
    fail "could not clone nixos-config"
  git -C "$NVIM_SRC" sparse-checkout set --cone dotfiles/editor/nvim ||
    fail "could not set sparse checkout"
  git -C "$NVIM_SRC" checkout ||
    fail "could not check out nixos-config"
fi

if [ -e "$NVIM_CONFIG" ] && [ ! -L "$NVIM_CONFIG" ]; then
  mv "$NVIM_CONFIG" "$NVIM_CONFIG.backup" || fail "could not move existing $NVIM_CONFIG aside"
fi
mkdir -p "$HOME/.config" || fail "could not create $HOME/.config"
ln -sfn "$NVIM_SRC/dotfiles/editor/nvim" "$NVIM_CONFIG" || fail "could not link $NVIM_CONFIG"

mkdir -p "$HOME/.vim/undodir" || fail "could not create ~/.vim/undodir"

echo "install.sh: finished"
exit 0
