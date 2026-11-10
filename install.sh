#!/bin/sh
# Installs the prufy CLI as one standalone binary. No Node needed.
#
#   curl -fsSL https://prufy.dev/install.sh | bash
#
# It downloads the binary for this machine from this repository's Releases, checks it
# against that release's published SHA-256, and puts it in ~/.local/bin. It never asks
# for a password and never uses sudo.
#
#   PRUFY_VERSION        a version to install, instead of the latest release
#   PRUFY_INSTALL        where to put it, instead of ~/.local/bin
#   PRUFY_DOWNLOAD_BASE  where releases live, instead of this repository's Releases
set -eu

REPO="agnelnieves/prufy-cli"
BASE="${PRUFY_DOWNLOAD_BASE:-https://github.com/$REPO/releases}"
INSTALL_DIR="${PRUFY_INSTALL:-$HOME/.local/bin}"

say() { printf '  %s\n' "$1"; }
stop() {
  printf '\n  %s\n' "$1" >&2
  [ -n "${2:-}" ] && printf '  %s\n' "$2" >&2
  printf '\n' >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 ||
    stop "This installer needs $1, and it isn't on this machine." \
      "The files are here to download by hand: https://github.com/$REPO/releases/latest"
}
need curl
need uname
need gunzip

case "$(uname -s)" in
  Darwin) os="darwin" ;;
  Linux) os="linux" ;;
  *) stop "There's no prufy binary for $(uname -s) yet." "See what there is: https://github.com/$REPO/releases/latest" ;;
esac
case "$(uname -m)" in
  arm64 | aarch64) arch="arm64" ;;
  x86_64 | amd64) arch="x64" ;;
  *) stop "There's no prufy binary for $(uname -m) yet." "See what there is: https://github.com/$REPO/releases/latest" ;;
esac
asset="prufy-$os-$arch.gz"

# This repository only ever releases the CLI, so its latest release is the latest prufy.
version="${PRUFY_VERSION:-}"
case "$version" in
  "") from="$BASE/latest/download" ;;
  *[!0-9A-Za-z.-]*) stop "\"$version\" doesn't look like a version." "For example: PRUFY_VERSION=0.1.0" ;;
  *) from="$BASE/download/v$version" ;;
esac

if command -v sha256sum >/dev/null 2>&1; then
  sha256() { sha256sum "$1" | cut -d ' ' -f 1; }
elif command -v shasum >/dev/null 2>&1; then
  sha256() { shasum -a 256 "$1" | cut -d ' ' -f 1; }
else
  stop "This installer checks the download with sha256sum or shasum, and neither is here." \
    "The files are here to download by hand: https://github.com/$REPO/releases/latest"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT INT TERM

say "Downloading prufy${version:+ $version} for $os $arch"
curl -fsL "$from/$asset" -o "$tmp/$asset" ||
  stop "We couldn't download prufy${version:+ $version} for $os $arch." \
    "Check your connection, then run this again. Releases: https://github.com/$REPO/releases"
curl -fsL "$from/checksums.txt" -o "$tmp/checksums.txt" ||
  stop "We couldn't download the checksums for that release." "Nothing was installed."

# The file is only unpacked and run if it's the one that release published.
expected="$(grep " $asset\$" "$tmp/checksums.txt" | cut -d ' ' -f 1)"
actual="$(sha256 "$tmp/$asset")"
[ -n "$expected" ] && [ "$expected" = "$actual" ] ||
  stop "The download doesn't match its published checksum, so it wasn't installed." \
    "Run this again. If it keeps happening, tell us: https://github.com/$REPO/issues"

gunzip "$tmp/$asset"
chmod +x "$tmp/prufy-$os-$arch"
mkdir -p "$INSTALL_DIR"
mv "$tmp/prufy-$os-$arch" "$INSTALL_DIR/prufy"

say "Installed prufy $("$INSTALL_DIR/prufy" --version) to $INSTALL_DIR/prufy"
case ":$PATH:" in
  *":$INSTALL_DIR:"*) say "Start with: prufy verify yourcompany.com" ;;
  *)
    say "$INSTALL_DIR isn't on your PATH yet. Add this line to your shell profile:"
    say "  export PATH=\"$INSTALL_DIR:\$PATH\""
    ;;
esac
