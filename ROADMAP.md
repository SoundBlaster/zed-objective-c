# Objective-C for Zed — Roadmap

## TL;DR

Core Objective-C support is complete: Tree-sitter queries, editor features,
snippets, `clangd`, the Xcode compilation database, and CI checks are working.
The next priorities are validating the extension in a live Zed session,
restoring a clean sample application build, and making semantic regression
tests fully reproducible.

## Current Status

- [x] Automatic language detection for `.m` files.
- [x] Project-local mapping from `.h` to Objective-C.
- [x] Syntax highlighting and semantic highlighting in `combined` mode.
- [x] Bracket matching, folding, and indentation.
- [x] Outline entries with complete Objective-C selectors.
- [x] Vim text objects.
- [x] Objective-C snippets.
- [x] `clangd` language server adapter.
- [x] Generation of `compile_commands.json` from real Xcode invocations.
- [x] Tree-sitter regression corpus with six fixtures.
- [x] Native and `wasm32-wasip2` Rust builds.
- [x] GitHub Actions validation.

## Principles

1. Do not claim support for a construct without a regression fixture.
2. Do not hide diagnostics caused by an incorrect Xcode compilation context.
3. Prefer exact compiler flags from `compile_commands.json` over manually
   maintained `CompileFlags` in `.clangd`.
4. Test malformed and incomplete code: an IDE analyzes files while they are
   being edited, not only after a successful build.
5. Use original, minimal fixtures. Preserve licenses and attribution whenever
   code is borrowed.

## Phase 5 — Live Validation in Zed

**Priority:** P0

**Goal:** Confirm that the built extension works correctly inside Zed, not only
in command-line tests.

### Tasks

- [ ] Reinstall `zed-objective-c-extension` as a dev extension.
- [ ] Verify automatic detection for `.m` and `.h`.
- [ ] Inspect syntax captures with `dev: open highlights tree view`.
- [ ] Verify semantic tokens for types, methods, properties, parameters, and
      variables.
- [ ] Test completion, signature help, and hover.
- [ ] Test diagnostics and code actions.
- [ ] Test go-to-definition, references, and rename.
- [ ] Test the outline for methods, protocols, categories, and class
      extensions.
- [ ] Test indentation, folding, text objects, and snippets.
- [ ] Inspect `dev: open language server logs` for startup and runtime errors.
- [ ] Create `MANUAL_TESTING.md` with a repeatable smoke-test checklist.

### Success Metrics

- Zed automatically selects Objective-C for every declared suffix.
- `objc-clangd` starts without errors.
- Semantic tokens are visible in `combined` mode.
- Navigation and completion work for UIKit and project symbols.
- Every item in `MANUAL_TESTING.md` passes on the current stable Zed release.

## Phase 6 — Green Xcode and clangd Pipeline

**Priority:** P0

**Goal:** The sample application and semantic checks must complete without
unexpected diagnostics.

### Tasks

- [ ] Move the intentional `[self tes]` error from the sample application into
      a negative fixture.
- [ ] Restore a successful `xcodebuild` for `ZedObjC`.
- [ ] Add `scripts/test-clangd.sh`.
- [ ] Validate the presence and structure of `compile_commands.json`.
- [ ] Run `clangd --check` for every project `.m` and `.h` file.
- [ ] Separate positive checks from intentional negative diagnostics.
- [ ] Document regeneration after changes to the scheme, SDK, or build flags.
- [ ] Consider a separate manual or nightly macOS CI job for Xcode integration.

### Success Metrics

- `xcodebuild` exits with status `0`.
- `scripts/test-clangd.sh` exits with status `0`.
- Positive project files contain no unexpected diagnostics.
- Negative fixtures assert the exact diagnostic and its location.

## Phase 7 — Regression Corpus and Query Polish

**Priority:** P1

**Goal:** Cover modern and less common Objective-C constructs, as well as
resilience to incomplete code.

### New Fixtures

- [ ] `NS_ENUM`, `NS_OPTIONS`, and typed enums.
- [ ] Preprocessor macros and conditional compilation.
- [ ] Nullability: `nullable`, `nonnull`, `_Nullable`, and `_Nonnull`.
- [ ] Lightweight generics such as `NSArray<NSString *> *`.
- [ ] `instancetype`, `Class`, `SEL`, and `Protocol`.
- [ ] Literals and subscripting.
- [ ] `@try`, `@catch`, `@finally`, and `@throw`.
- [ ] `@synchronized` and `@autoreleasepool`.
- [ ] Forward declarations and class properties.
- [ ] ARC qualifiers and bridging casts.
- [ ] Unclosed messages, methods, blocks, and declarations.

### Query Improvements

- [ ] Make category names searchable in the outline while preserving
      parentheses as context.
- [ ] Add `@class.inside` for interfaces, implementations, and protocols.
- [ ] Add `imports.scm` for `#import` and `#include`.
- [ ] Add exact capture snapshots containing the fixture, line, text, and
      capture name.
- [ ] Reduce test dependence on the textual output format of the Tree-sitter
      CLI.
- [ ] Open an upstream issue for the opaque contents of `@selector(foo:)` in
      the currently pinned grammar revision.

### Success Metrics

- Every supported construct has a positive fixture.
- Known grammar limitations are documented and have upstream issues.
- Capture regressions are detected at a specific token and location.
- Every query compiles and passes against the pinned Tree-sitter grammar
  revision.

## Phase 8 — Distribution and Upstream

**Priority:** P1

**Goal:** Establish a single supported distribution channel.

### Publication Decision

- [ ] Compare the changes with the existing `Akzestia/objcpp` registry
      extension.
- [ ] Propose the fixtures, queries, and clangd/Xcode improvements upstream.
- [ ] If an upstream contribution is unsuitable, choose a unique ID such as
      `objective-c-enhanced`.

### Repository Preparation

- [ ] Move the extension into a standalone Git repository or explicitly adopt
      a monorepo strategy.
- [x] Set the real `repository` URL in `extension.toml`.
- [ ] Add `CHANGELOG.md` and a release policy.
- [ ] Add syntax and semantic highlighting screenshots.
- [ ] Verify MIT notices and attribution for Tree-sitter queries and grammar.
- [ ] Configure version bumps and release validation.
- [ ] Prepare a PR to `zed-industries/extensions` if independent publication
      is selected.

### Success Metrics

- The extension has a canonical repository and a maintainer policy.
- The extension ID does not conflict with the registry, or the changes have
  been accepted upstream.
- A release builds successfully from a clean checkout.
- Licensing and third-party attribution are complete.

## Phase 9 — Objective-C++ Feasibility Spike

**Priority:** P2

**Goal:** Determine whether support for `.mm` can be claimed honestly without
regressions in either C++ or Objective-C syntax.

### Corpus Gate

- [ ] Namespaces and nested namespaces.
- [ ] Function and class templates.
- [ ] Lambdas and captures.
- [ ] C++ classes next to Objective-C interfaces and implementations.
- [ ] Objective-C messages with C++ argument and return types.
- [ ] Blocks using C++ types.
- [ ] Exceptions, RAII, and overloaded operators.
- [ ] Modern C++ attributes and concepts.

### Decision Gate

`.mm` may be added to `path_suffixes` only if:

- the corpus parses without systematic errors;
- C++ and Objective-C tokens receive correct captures;
- outline, indentation, and folding work for both languages;
- `clangd` receives the correct `objective-c++` compile command;
- limitations are listed explicitly in the README.

If these conditions are not met, `.mm` remains in C++ mode and Objective-C++
support is not claimed.

## Optional Backlog

- [ ] Project tasks for `xcodebuild build` and `xcodebuild test` from Zed.
- [ ] An optional `.clang-format` example that does not impose a project style.
- [ ] Verification of `clangd` inlay hints.
- [ ] Completion label customization for Objective-C selectors.
- [ ] XCTest-aware runnables after a reliable execution workflow is available.
- [ ] Performance audit of release WASM and query execution on large `.m`
      files.

## Release Checklist

- [ ] Tree-sitter fixtures and capture assertions pass.
- [ ] Rust formatting and the `wasm32-wasip2` build pass.
- [ ] The Xcode sample project builds.
- [ ] `clangd` checks pass.
- [ ] Manual Zed smoke tests pass.
- [ ] README, changelog, licenses, and screenshots are current.
- [ ] The extension version has been incremented according to the scope of the
      changes.
