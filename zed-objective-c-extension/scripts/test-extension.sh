#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TREE_SITTER_CLI=${TREE_SITTER_CLI:-tree-sitter}
GRAMMAR_DIR=${GRAMMAR_DIR:-$ROOT_DIR/grammars/objc}
GRAMMAR_REPOSITORY=https://github.com/tree-sitter-grammars/tree-sitter-objc
GRAMMAR_REVISION=181a81b8f23a2d593e7ab4259981f50122909fda
TEMP_GRAMMAR_DIR=

cleanup() {
    if [[ -n "$TEMP_GRAMMAR_DIR" ]]; then
        rm -rf "$TEMP_GRAMMAR_DIR"
    fi
}
trap cleanup EXIT

if ! command -v "$TREE_SITTER_CLI" >/dev/null 2>&1; then
    echo "tree-sitter CLI not found: $TREE_SITTER_CLI" >&2
    echo "Set TREE_SITTER_CLI=/absolute/path/to/tree-sitter." >&2
    exit 1
fi

if [[ ! -f "$GRAMMAR_DIR/grammar.js" ]]; then
    TEMP_GRAMMAR_DIR=$(mktemp -d)
    GRAMMAR_DIR=$TEMP_GRAMMAR_DIR/objc
    git clone --quiet "$GRAMMAR_REPOSITORY" "$GRAMMAR_DIR"
    git -C "$GRAMMAR_DIR" checkout --quiet "$GRAMMAR_REVISION"
fi

python3 - "$ROOT_DIR" <<'PY'
import json
import pathlib
import sys

try:
    import tomllib
except ImportError:
    import tomli as tomllib

root = pathlib.Path(sys.argv[1])
for path in root.rglob("*.toml"):
    tomllib.loads(path.read_text(encoding="utf-8"))
for path in root.rglob("*.json"):
    json.loads(path.read_text(encoding="utf-8"))
PY

fixtures=("$ROOT_DIR"/test/fixtures/*.m)
queries=("$ROOT_DIR"/languages/objective-c/*.scm)

(
    cd "$GRAMMAR_DIR"
    "$TREE_SITTER_CLI" parse --quiet --stat "${fixtures[@]}"
    for query in "${queries[@]}"; do
        "$TREE_SITTER_CLI" query --quiet "$query" "${fixtures[@]}" >/dev/null
    done
)

captures=$(
    cd "$GRAMMAR_DIR"
    "$TREE_SITTER_CLI" query --captures \
        "$ROOT_DIR/languages/objective-c/highlights.scm" \
        "${fixtures[@]}" 2>/dev/null
)

assert_capture() {
    local capture=$1
    local text=$2
    if ! grep -E "capture: .* - ${capture}, .*text: \`${text}\`" <<<"$captures" >/dev/null; then
        echo "missing @${capture} capture for: ${text}" >&2
        exit 1
    fi
}

assert_capture_count_at_least() {
    local capture=$1
    local text=$2
    local expected=$3
    local actual
    actual=$(grep -Ec "capture: .* - ${capture}, .*text: \`${text}\`" <<<"$captures" || true)
    if (( actual < expected )); then
        echo "expected at least ${expected} @${capture} captures for ${text}, found ${actual}" >&2
        exit 1
    fi
}

assert_capture type ZEDWidgetDataSource
assert_capture property displayName
assert_capture attribute nonatomic
assert_capture type NSString
assert_capture boolean YES
assert_capture constant.builtin nil
assert_capture comment.doc '/\*\* Supplies values to a widget\. \*/'

# Blocks and variables: typedef, pointer parameters, literal parameters, and captures.
assert_capture_count_at_least type ZEDCompletionBlock 3
assert_capture variable.parameter result
assert_capture variable.parameter error
assert_capture_count_at_least variable ZEDStaticCounter 2
assert_capture_count_at_least variable _instanceCounter 2
assert_capture attribute __block
assert_capture_count_at_least variable mutableTotal 3
assert_capture_count_at_least variable capturedIncrement 3
assert_capture variable localBlock
assert_capture function localBlock
assert_capture variable.parameter amount

# Protocol declarations, inheritance/adoption, qualified id, category, and extension.
assert_capture_count_at_least type ZEDReadable 4
assert_capture_count_at_least type ZEDWritable 3
assert_capture_count_at_least type ZEDReadWrite 2
assert_capture type.builtin id
assert_capture property delegate
assert_capture_count_at_least type Diagnostics 2
assert_capture function diagnosticSummary
assert_capture_count_at_least type ZEDDocument 4
assert_capture property internalRevision

echo "Objective-C extension checks passed."
