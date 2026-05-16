# AeroBeat Environment Contract Pivot Rollout

**Date:** 2026-05-16  
**Status:** In Progress  
**Agent:** Cookie 🍪

---

## Goal

Shape and roll out the pure AeroBeat environment architecture so `aerobeat-environment-core` defines the contract boundary, `aerobeat-environment-loader` consumes that contract cleanly, and `aerobeat-environment-gaussian-splat` fulfills implementation responsibilities through the new boundary.

---

## Overview

The previous session completed the repo-family rename, the lower fulfillment-package refactor, and the architecture/docs rollout describing the new environment family. That gives us a clean pushed baseline. The remaining follow-up from the handoff is the architecture pivot itself: stop treating the environment family as a loose set of repos and instead make the contract/core boundary explicit so consumers adopt a stable AeroBeat-native path.

Because this spans multiple repos, the coordination plan lives in `aerobeat-environment-core` so it is stored in git while still tracking child work across `aerobeat-environment-core`, `aerobeat-environment-loader`, and `aerobeat-environment-gaussian-splat`. We should first lock the contract shape in `aerobeat-environment-core`, then migrate the loader and splat repos against it, then run QA and an independent audit before landing.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Previous docs rollout plan and handoff context | `/home/derrick/Documents/projects/aerobeat/aerobeat-docs/.plans/2026-05-15-environment-docs-reference-audit-and-core-rollout.md` |
| `REF-02` | Environment core repo template / current baseline | `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/README.md` |
| `REF-03` | Environment loader repo current baseline | `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-loader/README.md` |
| `REF-04` | Environment gaussian splat repo current baseline | `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-gaussian-splat/README.md` |
| `REF-05` | Updated architecture repo map | `/home/derrick/Documents/projects/aerobeat/aerobeat-docs/docs/architecture/repository-map.md` |
| `REF-06` | Updated architecture workflow guidance | `/home/derrick/Documents/projects/aerobeat/aerobeat-docs/docs/architecture/workflow.md` |
| `REF-07` | Updated repo structure reference | `/home/derrick/Documents/projects/aerobeat/aerobeat-docs/docs/architecture/repo-structure-reference.md` |

---

## Tasks

### Task 1: Define the pure environment contract pivot and implementation plan

**Bead ID:** `aerobeat-environment-core-ef1`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** From coordination repo `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core`, claim the assigned bead and inspect the current environment-family repos plus the updated architecture docs. Produce a concrete contract-pivot recommendation for the pure AeroBeat architecture: what belongs in `aerobeat-environment-core`, what stays in `aerobeat-environment-loader`, what `aerobeat-environment-gaussian-splat` should fulfill directly or through the lower package boundary, and what migration order keeps consumers stable.

**Folders Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/.plans/`
- Repo-local notes only if needed

**Files Created/Deleted/Modified:**
- Coordination plan updates only unless the research pass uncovers missing docs references

**Status:** ✅ Complete

**Results:** Research complete. Current repo reality shows the contract accidentally lives in `aerobeat-environment-loader/src/AeroToolManager.gd`: it owns the request dictionary shape (`request_id`, `kind`, `asset_path`, `config_path`, `display_mode`, `context`, `metadata`), the generic lifecycle signals (`environment_load_started`, `environment_load_progress`, `environment_load_succeeded`, `environment_load_failed`, `environment_cleared`), the canonical generic kinds (`image`, `video`, `glb`, `splat`), and the normalized progress/status vocabulary. `aerobeat-environment-gaussian-splat` is already healthier architecturally because it has a stable lower fulfillment package boundary under `addons/aerobeat-environment-gaussian-splat-fulfillment/`, while `aerobeat-environment-core` is still only the internal environment package template with no shared runtime contract code yet.

**Recommended pivot:** make `aerobeat-environment-core` the AeroBeat-native contract package for environment requests/results/fulfillment interfaces **without** turning it into a new seventh platform core lane. In practice, `aerobeat-environment-core` should own the shared environment API surface that multiple environment-family repos consume, while still remaining an environment-family package built on `aerobeat-asset-core` rather than a universal architecture root.

**What belongs in `aerobeat-environment-core`:**
- shared environment constants/enums currently duplicated or implicitly owned by the loader, especially kind and status truth (`image`, `video`, `glb`, `splat`; resolving/loading/decoding/instantiating/applying_config/ready)
- typed request/result/error/progress contracts for generic environment fulfillment
- fulfillment/provider interfaces so the loader can delegate kind-specific work instead of hardcoding every implementation path
- optional shared transform/config application helpers for 3D environment config sidecars
- any reusable validation helpers for environment request normalization
- likely file/class names to introduce, matching current repo shapes: `interfaces/environment_fulfillment.gd`, `interfaces/environment_kind_handler.gd`, `data_types/environment_request.gd`, `data_types/environment_result.gd`, `data_types/environment_progress.gd`, `data_types/environment_error.gd`, `data_types/environment_config.gd`, `validators/environment_request_validator.gd`, `globals/aero_environment_constants.gd`; if Derrick wants to stay closer to the current concrete-package shape, the same files could instead live under a new `src/contracts/` subtree, but the important point is that the contract must move here, not remain in loader globals.

**What stays in `aerobeat-environment-loader`:**
- orchestration/consumer behavior: mount roots, default canvas/world ownership, current scene replacement, and the generic top-level manager node that product/testbed consumers instantiate
- official generic built-in fulfillment for kinds that do not need a specialized sibling repo: image, video, and GLB
- workout/package resolution helpers such as `AeroWorkoutYamlEnvironmentBridge.gd` and the lightweight `AeroSimpleYamlParser.gd` unless Derrick later decides YAML package resolution belongs in a content/tool repo
- backward-compatibility wrapper surface: keep `src/AeroToolManager.gd` as the public entrypoint first, but refactor it into a consumer/orchestrator of `aerobeat-environment-core` contracts instead of the contract owner
- likely loader-side new/changed files: keep `src/AeroToolManager.gd`, add adapters such as `src/fulfillment/AeroImageEnvironmentHandler.gd`, `src/fulfillment/AeroVideoEnvironmentHandler.gd`, `src/fulfillment/AeroGlbEnvironmentHandler.gd`, and possibly `src/fulfillment/AeroEnvironmentFulfillmentRegistry.gd`; update tests to validate that the loader accepts core-defined request/result contracts while preserving current signal behavior

**What `aerobeat-environment-gaussian-splat` should fulfill directly vs. through its lower package boundary:**
- the lower package should continue to own the real decode/load/build/background/compositor logic because it already solves the dependency-safe reuse problem cleanly
- the repo-root wrapper should own only AeroBeat-facing adapter/global ergonomics (`class_name` wrappers, stable top-level manager names, contract adapter classes)
- after the pivot, splat-specific generic-environment fulfillment should ideally be exposed as an adapter implementing the new core fulfillment interface, with likely names such as `src/AeroSplatEnvironmentHandler.gd` or `src/AeroGaussianSplatEnvironmentFulfillment.gd`, while the lower package keeps `runtime/gaussian_splat_runtime.gd`, background worker scripts, and vendor-facing logic unchanged except where interface adaptation is needed
- `AeroToolManager.gd` in the splat repo should remain a wrapper/composition façade if Derrick still wants that ergonomic path, but it should not become the architectural contract source of truth

**Stable migration order:**
1. Add the shared environment contract files to `aerobeat-environment-core` first, plus narrow tests proving request normalization, status vocabulary, and interface expectations.
2. Update `aerobeat-environment-loader` to consume the new core contracts internally **while preserving its current public API**: accept the existing request dictionaries/signals, normalize them through the new core types/helpers, and keep image/video/GLB behavior stable.
3. Add splat fulfillment adapters in `aerobeat-environment-gaussian-splat` against the new core interface, but keep the lower runtime package boundary intact and keep current public wrapper entrypoints working.
4. Only after all three repos are working, consider cleanup/renames such as reducing `AeroToolManager` naming drift or exposing a more environment-native class name. That rename should be a follow-up, not part of the first stabilizing pivot.

**Recommended compatibility stance:** do not break consumers onto typed-only APIs immediately. Let `aerobeat-environment-core` define the authoritative contract, but keep dictionary-based compatibility shims in loader/splat wrappers for at least one rollout slice so current testbeds and downstream assemblies do not need simultaneous rewrites.

**Risks / ambiguities Derrick may need to resolve:**
- naming drift: both loader and splat still use `AeroToolManager`, which reflects their prior tool-template origin and weakens the pure environment story; the safest rollout keeps the name temporarily, but Derrick should decide whether the end state wants `AeroEnvironmentManager`-style naming
- repo-shape purity: current docs describe `aerobeat-environment-core` primarily as an internal environment package repo (`assets/environments`, `assets/lighting`, `assets/reactive`), so adding shared script contracts there slightly stretches the documented example; Derrick should decide whether to update docs to explicitly allow a contract subtree in this repo or to split authored-environment assets and contracts more strongly later
- ownership of workout YAML/package-resolution helpers: today they live in loader, but long-term they may fit better in content/tool land if the environment family should only handle already-resolved environment requests
- dependency direction: loader should depend on core, and splat should depend on core, but core should not depend back on loader or splat; implementation should guard that boundary carefully
- status/result contract granularity: current loader progress payloads and splat background payloads are similar but not identical, so Derrick may need to choose whether the first pivot unifies them fully or defines a generic baseline plus optional implementation-specific metadata

This recommendation is strong enough to unblock implementation. It gives a concrete ownership split, specific candidate files/classes, and a migration order that preserves existing consumer call sites while moving architectural truth into `aerobeat-environment-core`. 

---

### Task 2: Implement the contract/core boundary in `aerobeat-environment-core`

**Bead ID:** `aerobeat-environment-core-13q`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-02`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** In repo `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core`, claim the assigned bead and implement the agreed environment contract/core boundary for the pure AeroBeat architecture. Add the contract classes/resources/interfaces needed for downstream consumers, keep the repo aligned with the internal environment lane ownership rules, run repo-local validation, and commit/push the result before handoff unless blocked.

**Folders Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/`

**Files Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/src/contracts/globals/aero_environment_constants.gd`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/src/contracts/data_types/environment_request.gd`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/src/contracts/data_types/environment_result.gd`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/src/contracts/data_types/environment_error.gd`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/src/contracts/data_types/environment_progress.gd`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/src/contracts/data_types/environment_config.gd`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/src/contracts/interfaces/environment_fulfillment.gd`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/src/contracts/interfaces/environment_kind_handler.gd`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/src/contracts/validators/environment_request_validator.gd`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/src/contracts/validators/environment_config_helper.gd`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/.testbed/tests/test_environment_contracts.gd`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/.testbed/tests/test_example.gd`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/README.md`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/plugin.cfg`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/.gitignore`

**Status:** ✅ Complete

**Results:** Implemented a narrow but real `src/contracts/` subtree in `aerobeat-environment-core` so this repo now owns the shared environment contract boundary instead of leaving it implicit in loader code. The slice includes shared constants/status vocabulary, typed request/result/error/progress/config DTO-style classes, fulfillment/provider base interfaces, a request validator that preserves dictionary-friendly normalization for incremental downstream adoption, and a config helper that can apply 3D transform sidecars without pulling in loader/splat dependencies. README and plugin metadata were updated to describe the repo as the environment contract/core package while explicitly preserving the environment-lane-only scope. Repo-local validation was upgraded from template-only metadata checks to real contract tests covering script existence, request normalization, unsupported-format errors, config application, and DTO round-tripping. Validation run: `godotenv addons install`; `godot --headless --path .testbed --import`; `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` (9/9 passing). Implementation commit: `b635863` (`Add environment core contract boundary`). One small repo-local fix was needed during landing: the stock `.gitignore` pattern `data_*/` would have silently excluded `src/contracts/data_types/`, so Task 2 also added a targeted unignore for that subtree.

---

### Task 3: Migrate `aerobeat-environment-loader` to consume the new contract path

**Bead ID:** `aerobeat-environment-core-rvb`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-03`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** In repo `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-loader`, claim the assigned bead and migrate the loader surface to the new `aerobeat-environment-core` contract path. Preserve working behavior where possible, update manifests/tests/docs as needed, run repo-local validation, and commit/push before handoff unless blocked.

**Folders Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-loader/`

**Files Created/Deleted/Modified:**
- Loader contract-consumer files to be determined by Task 1
- Tests/README/manifest files as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Migrate `aerobeat-environment-gaussian-splat` to fulfill the new contract cleanly

**Bead ID:** `aerobeat-environment-core-r2w`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** In repo `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-gaussian-splat`, claim the assigned bead and adapt the wrapper plus lower fulfillment package so the repo fulfills the new `aerobeat-environment-core` contract cleanly. Keep the dependency-safe lower package boundary intact, update manifests/tests/docs as needed, run repo-local validation, and commit/push before handoff unless blocked.

**Folders Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-gaussian-splat/`

**Files Created/Deleted/Modified:**
- Gaussian-splat fulfillment/adapter files to be determined by Task 1
- Tests/README/manifest files as needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 5: Verify the end-to-end environment contract flow

**Bead ID:** `aerobeat-environment-core-eav`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Across the touched environment repos, claim the assigned bead and perform QA on the new contract flow end-to-end. Verify that the core contract is consumable, the loader resolves against it, the gaussian-splat implementation fulfills it, and the available validation/testbed flows support the claimed architecture.

**Folders Created/Deleted/Modified:**
- Validation only expected

**Files Created/Deleted/Modified:**
- Plan updates and any small QA-fix follow-ups if absolutely required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 6: Independently audit the environment contract pivot

**Bead ID:** `aerobeat-environment-core-uxi`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Across the touched environment repos, claim the assigned bead and independently audit whether the pure AeroBeat environment architecture pivot actually landed. Check the plan, diffs, manifests, tests, and any QA evidence. Close the work only if the contract/core boundary, implementation fulfillment, and consumer adoption path are all real and coherent.

**Folders Created/Deleted/Modified:**
- Audit only expected

**Files Created/Deleted/Modified:**
- Plan updates only unless the audit requires a clearly documented retry

**Status:** ⏳ Pending

**Results:** Pending.

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending.

**Reference Check:** Pending.

**Commits:**
- Pending

**Lessons Learned:** Pending.

---

*Completed on Pending*
