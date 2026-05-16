# AeroBeat Environment Core

`aerobeat-environment-core` is the shared **environment-lane contract package** for AeroBeat.

It owns the reusable environment request/result/error/progress/config vocabulary that sibling
repos such as `aerobeat-environment-loader` and `aerobeat-environment-gaussian-splat` can depend on
without pushing environment architecture truth back into those repos.

This repo is intentionally **not** a new universal architecture lane.

In plain English: this package is **not a new universal architecture lane**. It stays aligned with
the existing environment-family package role and the asset-side dependency direction built on
`aerobeat-asset-core`.

## What this repo owns now

- canonical environment kinds, lifecycle states, and status vocabulary
- typed request/result/error/progress/config contracts
- typed async operation handles for fulfillment lifecycle and progress reporting
- narrow fulfillment/provider base interfaces for kind handlers
- reusable request normalization and environment config helpers
- room for package-local internal environment assets when a concrete environment repo needs them

## Contract subtree

Current shared contract surface lives under:

- `src/contracts/globals/` - constants and shared vocabulary
- `src/contracts/data_types/` - typed DTO-style contract resources/classes plus async operation handles
- `src/contracts/interfaces/` - fulfillment/provider base interfaces, including sync-to-async wrapper entrypoints
- `src/contracts/validators/` - request normalization and config helpers

The initial contract slice is intentionally narrow. It is designed to unblock downstream migration
while preserving current public entrypoints in consumer repos.

## Downstream usage intent

- `aerobeat-environment-loader` should consume these contracts internally while keeping its current
  public API stable for existing callers.
- `aerobeat-environment-gaussian-splat` should adapt its fulfillment wrapper/lower package to this
  contract instead of defining competing environment truth.
- `aerobeat-environment-core` must not depend back on loader or splat.

## Repository Details

- **Type:** Environment contract/core package
- **License:** **CC BY-NC 4.0** (Attribution-NonCommercial)
- **Dependency contract:**
  - `aerobeat-asset-core` — required shared asset/resource contract for the environment lane
  - `aerobeat-feature-*` — optional consumer-selected runtime dependency when validating a concrete
    environment against a specific feature such as Boxing or Flow
  - additional adjacent lane/core repos only when a concrete environment package truly consumes them

## GodotEnv development flow

This repo uses the AeroBeat GodotEnv asset-package convention.

- Canonical dev/test manifest: `.testbed/addons.jsonc`
- Installed dev/test addons: `.testbed/addons/`
- GodotEnv cache: `.testbed/.addons/`
- Hidden workbench project: `.testbed/project.godot`
- Repo-local unit tests: `.testbed/tests/`

The repo root remains the package/published boundary for downstream consumers. Day-to-day
validation happens from the hidden `.testbed/` workbench using the pinned OpenClaw toolchain:
Godot `4.6.2 stable standard`.

### Restore dev/test dependencies

From the repo root:

```bash
cd .testbed
godotenv addons install
```

### Import smoke check

From the repo root:

```bash
godot --headless --path .testbed --import
```

### Run unit tests

From the repo root:

```bash
godot --headless --path .testbed --script addons/gut/gut_cmdln.gd \
  -gdir=res://tests \
  -ginclude_subdirs \
  -gexit
```

## Structure

- `src/contracts/` - shared environment contract code for loader/fulfillment consumers
- `assets/environments/` - optional internal environment scenes/resources if this package grows
  authored environment content later
- `assets/lighting/` - optional lighting and presentation resources
- `assets/reactive/` - optional reactive presentation resources

## Validation notes

- `.testbed/addons.jsonc` is the committed dev/test dependency contract.
- The canonical manifest for this repo remains narrow: `aerobeat-asset-core` + `gut`.
- Repo-local tests now validate the environment contract subtree and basic behavior, not just
  template metadata.
- Keep the dependency direction clean: consumer repos depend on this package; this package does not
  reach back into loader or specialized fulfillment repos.
