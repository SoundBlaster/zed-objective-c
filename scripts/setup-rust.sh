#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TOOLCHAIN=stable
TARGET=wasm32-wasip2
INSTALL_RUSTUP=false
CHECK_ONLY=false
VERIFY=false
TEMP_DIR=

usage() {
    cat <<'EOF'
Usage: scripts/setup-rust.sh [options]

Prepare the Rust toolchain required to build this Zed development extension.

Options:
  --check            Validate the environment without changing it.
  --install-rustup   Install rustup from the official installer when missing.
  --verify           Run cargo fmt --check and the WASI cargo check afterward.
  -h, --help         Show this help.

Examples:
  scripts/setup-rust.sh --check
  scripts/setup-rust.sh
  scripts/setup-rust.sh --install-rustup --verify
EOF
}

fail() {
    echo "error: $*" >&2
    exit 1
}

cleanup() {
    if [[ -n "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

while (($#)); do
    case "$1" in
        --check)
            CHECK_ONLY=true
            ;;
        --install-rustup)
            INSTALL_RUSTUP=true
            ;;
        --verify)
            VERIFY=true
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            usage >&2
            fail "unknown option: $1"
            ;;
    esac
    shift
done

if ! command -v rustup >/dev/null 2>&1; then
    if [[ "$CHECK_ONLY" == true ]]; then
        fail "rustup was not found; run scripts/setup-rust.sh --install-rustup"
    fi
    if [[ "$INSTALL_RUSTUP" != true ]]; then
        cat >&2 <<'EOF'
error: rustup was not found.

Run this script again with --install-rustup to download and execute the
official installer, or install rustup yourself from https://rustup.rs/.
EOF
        exit 1
    fi

    command -v curl >/dev/null 2>&1 || fail "curl is required to install rustup"
    TEMP_DIR=$(mktemp -d)
    INSTALLER="$TEMP_DIR/rustup-init.sh"

    echo "Downloading the official rustup installer..."
    curl \
        --proto '=https' \
        --tlsv1.2 \
        --fail \
        --silent \
        --show-error \
        https://sh.rustup.rs \
        --output "$INSTALLER"

    echo "Installing a minimal stable Rust toolchain through rustup..."
    sh "$INSTALLER" -y --profile minimal --default-toolchain "$TOOLCHAIN"
fi

CARGO_HOME=${CARGO_HOME:-"$HOME/.cargo"}
export PATH="$CARGO_HOME/bin:$PATH"

command -v rustup >/dev/null 2>&1 || fail "rustup is still unavailable after setup"

if [[ "$CHECK_ONLY" == true ]]; then
    rustup toolchain list | grep -Eq "^${TOOLCHAIN}(-| )" ||
        fail "the $TOOLCHAIN toolchain is not installed"
    rustup component list --installed --toolchain "$TOOLCHAIN" |
        grep -Eq '^rustfmt-' || fail "rustfmt is not installed for $TOOLCHAIN"
    rustup target list --installed --toolchain "$TOOLCHAIN" |
        grep -qx "$TARGET" || fail "$TARGET is not installed for $TOOLCHAIN"
else
    echo "Preparing Rust $TOOLCHAIN with rustfmt and $TARGET..."
    rustup toolchain install "$TOOLCHAIN" --profile minimal
    rustup component add rustfmt --toolchain "$TOOLCHAIN"
    rustup target add "$TARGET" --toolchain "$TOOLCHAIN"
fi

echo "Using $(rustup run "$TOOLCHAIN" rustc --version)"
echo "Using $(rustup run "$TOOLCHAIN" cargo --version)"

if [[ "$VERIFY" == true ]]; then
    echo "Verifying the extension crate..."
    (
        cd "$ROOT_DIR"
        rustup run "$TOOLCHAIN" cargo fmt --check
        rustup run "$TOOLCHAIN" cargo check --locked --target "$TARGET"
    )
fi

cat <<EOF

Rust environment is ready for the Zed development-extension build.
If Zed was already running, fully quit it before retrying the installation.
To test the inherited shell environment, run:

  export PATH="$CARGO_HOME/bin:\$PATH"
  zed --foreground
EOF
