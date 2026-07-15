# Objective-C for Zed

Development-stage Zed extension that adds Tree-sitter syntax support and
`clangd` semantic features for Objective-C (`.m`).

## Features

- automatic language detection for `.m` files;
- C and Objective-C syntax highlighting;
- Objective-C declarations, messages, selectors, properties, protocols,
  nullability qualifiers, and literals;
- bracket matching, folding, indentation, full-selector outlines, and Vim text
  objects;
- snippets for common Objective-C declarations;
- clangd completion, diagnostics, navigation, background indexing, and
  combined semantic highlighting.

## Quick start

No project configuration is required for syntax highlighting, indentation,
folding, outlines, text objects, or snippets. If `clangd` is available in
`PATH`, the extension starts it automatically with Objective-C-friendly
defaults and enables completion, diagnostics, hover, navigation, rename,
references, and semantic highlighting.

On macOS, Xcode or the Xcode Command Line Tools normally provides `clangd`.
You do not need to copy an LSP configuration into Zed for the standard setup.

## Requirements and optional tools

- Zed 1.11.3 or newer;
- `clangd` in `PATH` for semantic features;
- Rust installed through `rustup` only when building or developing the
  extension;
- an accurate `compile_commands.json` is optional, but recommended for full
  project-aware semantics in non-trivial Xcode projects.

The Tree-sitter editor features continue to work when `clangd` is unavailable.

| Goal | User action |
| --- | --- |
| Syntax highlighting and editor features | Install the extension; no configuration required. |
| Basic semantic features | Ensure `clangd` is available in `PATH`. |
| Accurate UIKit and project-wide semantics | Optionally provide `compile_commands.json`. |
| Stop formatting while typing | Set `use_on_type_format` to `false` for Objective-C. |
| Build the extension from source | Install Rust through `rustup`. |
| Use a non-standard clangd binary | Add the troubleshooting override shown below. |

## Install as a development extension

1. Open Zed's Command Palette.
2. Run `zed: install dev extension`.
3. Select the root of this repository.
4. Open `test/fixtures/sample.m` and verify that the language selector shows
   `Objective-C`.

If installation fails, run `zed: open log` and inspect the grammar or query
error reported there.

The extension ID `objective-c` is also used by the community Objective-C
extension in the Zed registry. Installing this directory as a dev extension
intentionally overrides that registry extension. Before publishing this work,
either contribute the changes upstream or choose a distinct extension ID.

## Objective-C headers

The extension intentionally does not claim `.h`: that suffix is shared by C,
C++, and Objective-C. In an Objective-C-only project, add a project-local
`.zed/settings.json` if you want all headers treated as Objective-C:

```json
{
  "file_types": {
    "Objective-C": ["h"]
  }
}
```

## Recommended Zed settings

Zed enables LSP on-type formatting by default. Because `clangd` advertises
that capability, it may reformat incomplete Objective-C expressions while you
are typing—for example, immediately after inserting a line break or a trigger
character. To keep clangd completion, diagnostics, navigation, rename, hover,
references, and semantic highlighting without automatic formatting during
typing, disable on-type formatting for Objective-C:

```json
{
  "file_types": {
    "Objective-C": ["h"]
  },
  "languages": {
    "Objective-C": {
      "semantic_tokens": "combined",
      "use_on_type_format": false
    }
  }
}
```

The `file_types` entry is optional and should only be used when the project's
`.h` files are Objective-C headers. `use_on_type_format` is independent of
`format_on_save`; disabling it does not disable manual formatting. Use a
project-level `.clang-format` if manual formatting should follow a specific
style.

Objective-C++ (`.mm`) is also intentionally not claimed yet. The upstream
grammar extends Tree-sitter's C grammar, not its C++ grammar, so treating `.mm`
as fully supported would misparse C++ constructs such as namespaces and
templates. Until a combined Objective-C++ grammar is available, use Zed's C++
mode for C++-heavy `.mm` files.

## clangd integration

### Automatic setup

The extension finds `clangd` in `PATH` and starts it with:

- background indexing;
- project-level `.clangd` configuration support;
- detailed completion items;
- `#import` insertion for accepted completions.

This is enough to get started. Without project-specific compiler flags,
`clangd` uses a fallback command and may still provide useful results for
simple files. Missing frameworks, incorrect diagnostics, or incomplete
cross-file navigation usually indicate that it needs the real build flags.

### Accurate Xcode project semantics (optional)

Xcode build settings determine the SDK, architecture, deployment target,
framework search paths, header maps, preprocessor definitions, and ARC mode.
For the most accurate completion, diagnostics, and indexing, provide those
settings to `clangd` through a standard
[`compile_commands.json`](https://clang.llvm.org/docs/JSONCompilationDatabase.html).

The extension does not generate this file automatically. An Xcode workspace
may contain several schemes, configurations, SDKs, and destinations, so there
is no single build command the extension can safely choose on the user's
behalf. Use an Xcode-compatible compilation-database generator that records the
real compiler invocations, then place `compile_commands.json` in the project
root, an ancestor of the source files, or a `build/` directory where `clangd`
can discover it. Regenerate it after changing important build settings and
restart the Objective-C language server in Zed.

To confirm that the database was discovered, open Zed's language-server logs
and look for a `clangd` message that names the loaded compilation database. If
UIKit imports are unresolved or diagnostics disagree with Xcode, verify the
database before changing the extension's language-server arguments.

`xcode-build-server` is not required by this extension. It implements the Build
Server Protocol for SourceKit-LSP and normally creates `buildServer.json`;
`clangd` does not consume that file. See the official
[`clangd` project setup documentation](https://clangd.llvm.org/installation.html#project-setup)
for compilation-database discovery and fallback behavior.

### Custom clangd binary (troubleshooting only)

Do not add this configuration for a normal installation. Use it only when
`clangd` is not in `PATH` or when you intentionally want to replace the
extension's default arguments:

```json
{
  "lsp": {
    "objc-clangd": {
      "binary": {
        "path": "/usr/bin/clangd",
        "arguments": [
          "--background-index",
          "--enable-config",
          "--header-insertion=iwyu",
          "--import-insertions",
          "--completion-style=detailed"
        ]
      }
    }
  }
}
```

When `binary.arguments` is present, it replaces the extension defaults rather
than extending them.

## Development checks

Run the Tree-sitter corpus, query, TOML, and JSON checks with:

```sh
TREE_SITTER_CLI=/path/to/tree-sitter ./scripts/test-extension.sh
```

Then verify formatting and the actual Zed WASI build:

```sh
cargo fmt --check
cargo check --locked --target wasm32-wasip2
```

The test runner uses the grammar checkout generated by Zed when present and
otherwise checks out the pinned grammar revision into a temporary directory.
GitHub Actions runs both the Tree-sitter and Rust validations.

## Third-party components

The extension uses
[`tree-sitter-objc`](https://github.com/tree-sitter-grammars/tree-sitter-objc)
at a pinned revision. The grammar and the C highlight query from
[`tree-sitter-c`](https://github.com/tree-sitter/tree-sitter-c) are available
under the MIT License.
