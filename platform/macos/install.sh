#!/usr/bin/env bash
# platform/macos/install.sh — macOS system package auto-install via Homebrew.
# Invoked by ../../install.sh after dotfile sync. Idempotent: skips packages
# already present. Non-fatal: any failure exits 0 so the parent install.sh
# (which runs under `set -e`) keeps going.

set -u

REQUIRED_PKGS=(tmux)

if ! command -v brew >/dev/null 2>&1; then
  printf '[platform/macos] WARNING: Homebrew not found — install via https://brew.sh, then: brew install %s\n' "${REQUIRED_PKGS[*]}"
  exit 0
fi

missing=()
for pkg in "${REQUIRED_PKGS[@]}"; do
  brew list --formula "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
done

if [[ ${#missing[@]} -eq 0 ]]; then
  printf '[platform/macos] system packages already present (skip): %s\n' "${REQUIRED_PKGS[*]}"
  exit 0
fi

printf '[platform/macos] installing: %s\n' "${missing[*]}"
if brew install "${missing[@]}"; then
  printf '[platform/macos] installed: %s\n' "${missing[*]}"
else
  printf '[platform/macos] WARNING: brew install failed for: %s\n' "${missing[*]}"
fi
