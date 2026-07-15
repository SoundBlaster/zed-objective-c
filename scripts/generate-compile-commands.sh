#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PROJECT=${PROJECT:-$ROOT_DIR/ZedObjC/ZedObjC.xcodeproj}
SCHEME=${SCHEME:-ZedObjC}
CONFIGURATION=${CONFIGURATION:-Debug}
SDK=${SDK:-iphonesimulator}
DESTINATION=${DESTINATION:-generic/platform=iOS Simulator}
ARCH=${ARCH:-$(uname -m)}
DERIVED_DATA=${DERIVED_DATA:-$ROOT_DIR/.clangd-cache/DerivedData}
BUILD_LOG=${BUILD_LOG:-$ROOT_DIR/.clangd-cache/xcodebuild.log}
OUTPUT=${OUTPUT:-$ROOT_DIR/compile_commands.json}
TEMP_OUTPUT=

cleanup() {
    if [[ -n "$TEMP_OUTPUT" && -f "$TEMP_OUTPUT" ]]; then
        rm -f "$TEMP_OUTPUT"
    fi
}
trap cleanup EXIT

if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "xcodebuild was not found. Install Xcode and select it with xcode-select." >&2
    exit 1
fi

if ! command -v xcode-build-server >/dev/null 2>&1; then
    echo "xcode-build-server was not found." >&2
    echo "Install it with: brew install xcode-build-server" >&2
    exit 1
fi

mkdir -p "$(dirname "$BUILD_LOG")" "$DERIVED_DATA"
TEMP_OUTPUT=$(mktemp "$(dirname "$OUTPUT")/.compile_commands.XXXXXX")

echo "Building $SCHEME for $DESTINATION to capture exact Clang invocations..."
set +e
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -sdk "$SDK" \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA" \
    ARCHS="$ARCH" \
    ONLY_ACTIVE_ARCH=YES \
    CODE_SIGNING_ALLOWED=NO \
    COMPILER_INDEX_STORE_ENABLE=NO \
    clean build 2>&1 | tee "$BUILD_LOG" >/dev/null
XCODEBUILD_STATUS=${PIPESTATUS[0]}
set -e

xcode-build-server parse -o "$TEMP_OUTPUT" "$BUILD_LOG"

python3 - "$TEMP_OUTPUT" <<'PY'
import json
import pathlib
import shlex
import sys

path = pathlib.Path(sys.argv[1])
entries = json.loads(path.read_text(encoding="utf-8"))
if not isinstance(entries, list) or not entries:
    raise SystemExit("compile_commands.json contains no compiler entries")

missing = [
    entry
    for entry in entries
    if not entry.get("file")
    or not entry.get("directory")
    or not (entry.get("command") or entry.get("arguments"))
]
if missing:
    raise SystemExit(f"compile_commands.json has {len(missing)} incomplete entries")

missing_sources = []
missing_response_files = []
for entry in entries:
    directory = pathlib.Path(entry["directory"])
    source = pathlib.Path(entry["file"])
    if not source.is_absolute():
        source = directory / source
    if not source.is_file():
        missing_sources.append(source)

    arguments = entry.get("arguments") or shlex.split(entry["command"])
    for argument in arguments:
        if not argument.startswith("@"):
            continue
        response_file = pathlib.Path(argument[1:])
        if not response_file.is_absolute():
            response_file = directory / response_file
        if not response_file.is_file():
            missing_response_files.append(response_file)

if missing_sources:
    raise SystemExit(
        f"compile_commands.json references {len(missing_sources)} missing source files"
    )
if missing_response_files:
    raise SystemExit(
        "compile_commands.json references "
        f"{len(missing_response_files)} missing response files"
    )

objective_c = [entry for entry in entries if pathlib.Path(entry["file"]).suffix in {".m", ".mm"}]
if not objective_c:
    raise SystemExit("compile_commands.json contains no Objective-C sources")

print(f"Generated {path} with {len(entries)} entries ({len(objective_c)} Objective-C).")
PY

mv "$TEMP_OUTPUT" "$OUTPUT"
TEMP_OUTPUT=
echo "Installed validated compilation database at $OUTPUT."

if [[ $XCODEBUILD_STATUS -ne 0 ]]; then
    echo "Warning: xcodebuild exited with status $XCODEBUILD_STATUS; the database was still generated." >&2
    echo "This means semantic tooling is configured; it does not mean the application built successfully." >&2
    tail -n 12 "$BUILD_LOG" >&2
fi

echo "Restart clangd in Zed after regenerating the database."
