# AeroBeat Environment Contract Async Progress Rollout

**Date:** 2026-05-16  
**Status:** In Progress  
**Agent:** Cookie 🍪

---

## Goal

Extend the shared AeroBeat environment contract so it supports async fulfillment, state updates, and progress reporting cleanly, then thread that support through gaussian-splat without waiting on the separate splat-runtime bug to be resolved.

---

## Overview

The environment contract pivot is landed, but the current shared contract is still sync-first. That is too narrow for the real gaussian-splat use case, because splat loading naturally needs longer-running operations, background execution, and state/progress updates. Derrick wants that debt item promoted into active work now.

This rollout should focus on plumbing and contract design/implementation, not on pretending the separate gaussian-splat runtime bug is solved. We can finish the async/progress/state contract path now, adapt gaussian-splat to expose it through the new shared contract, and validate as far as the current bug allows. Final real-world behavioral proof inside `aerobeat-assembly-community` is expected to remain partially blocked until that separate bug is fixed.

Because this work changes the shared contract and at least one fulfillment implementation, the coordination plan lives in `aerobeat-environment-core` and tracks child work in `aerobeat-environment-core` and `aerobeat-environment-gaussian-splat`. If loader needs a follow-up adaptation for parity or API coherence, we should capture that explicitly instead of smuggling it in.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Completed contract-pivot plan | `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/.plans/archive/2026-05-16-environment-contract-pivot-rollout.md` |
| `REF-02` | Current environment core contract package | `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core` |
| `REF-03` | Current gaussian-splat fulfillment repo | `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-gaussian-splat` |
| `REF-04` | Current loader repo for compatibility follow-up if needed | `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-loader` |
| `REF-05` | Current architecture docs repo | `/home/derrick/Documents/projects/aerobeat/aerobeat-docs` |

---

## Tasks

### Task 1: Design the async/progress/state contract extension

**Bead ID:** `aerobeat-environment-core-5ef`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** From coordination repo `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core`, claim the assigned bead and inspect the current shared contract plus gaussian-splat runtime/wrapper surfaces. Define a concrete extension for async fulfillment, state transitions, and progress updates that can support gaussian-splat cleanly without depending on the separate runtime bug being resolved.

**Folders Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/.plans/`

**Files Created/Deleted/Modified:**
- Plan updates only unless minor notes are needed

**Status:** ✅ Complete

**Results:** Research complete. The currently-landed shared contract is still sync-first: `AeroEnvironmentFulfillment.fulfill()` returns a terminal `AeroEnvironmentResult`/`AeroEnvironmentError`, `AeroEnvironmentProgress` only models a single status/progress snapshot, and gaussian-splat keeps its richer async surface entirely outside the shared contract via `background_load_started` / `background_load_progressed` / `background_load_finished` plus runtime dictionaries like `{ pending, progress, phase, status }`. That means the cleanest rollout is to **add an async operation layer on top of the existing sync contract instead of replacing it**.

**Recommended core contract extension in `aerobeat-environment-core`:**
- Add a new typed operation object, e.g. `src/contracts/data_types/environment_operation.gd` (`class_name AeroEnvironmentOperation`, `extends RefCounted`). It should own the request, latest progress snapshot, terminal result/error, lifecycle state, and typed signals.
- Add signals on `AeroEnvironmentOperation`: `started(progress: AeroEnvironmentProgress)`, `progressed(progress: AeroEnvironmentProgress)`, `succeeded(result: AeroEnvironmentResult)`, `failed(error: AeroEnvironmentError)`, and `finished(operation: AeroEnvironmentOperation)`. `finished` gives callers a single terminal hook even if they do not care about success vs failure separately.
- Add state fields/constants so the operation lifecycle is explicit and not inferred only from progress percent. Core should introduce constants such as `STATE_PENDING`, `STATE_RUNNING`, `STATE_SUCCEEDED`, `STATE_FAILED`, and `STATE_CANCELLED` in `src/contracts/globals/aero_environment_constants.gd`.
- Extend `src/contracts/data_types/environment_progress.gd` rather than replacing it. Keep existing fields (`request_id`, `kind`, `asset_path`, `status`, `progress`, `message`, `metadata`) for compatibility, and add:
  - `state: String` — lifecycle state (`pending`/`running`/terminal)
  - `phase: String` — optional implementation-specific fine-grained phase (`reading`, `decoding`, `building`, etc.)
  - `sequence: int` — monotonically increasing event index so consumers can reason about ordered updates
  - `indeterminate: bool` — allows async flows to report work before total progress is knowable
- Keep `status` as the shared cross-kind stage vocabulary and **do not** overload it with every splat-specific phase. Keep / extend the generic statuses in core (`resolving`, `loading`, `decoding`, `instantiating`, `applying_config`, `ready`) and add only the minimal terminal/queue states needed for orchestration coherence: `queued`, `failed`, `cancelled`. Use `phase` for splat-specific detail so the core contract stays generic.
- Add helpers on `AeroEnvironmentOperation` so sync and async providers share one shape: `mark_started(progress)`, `push_progress(progress)`, `succeed(result, final_progress)`, `fail(error, final_progress)`, `cancel(message, final_progress)`, `to_dict()`, and `is_terminal()`.

**Recommended interface changes:**
- Keep `src/contracts/interfaces/environment_fulfillment.gd::fulfill()` exactly as the sync convenience path.
- Add `begin_fulfill(request: Variant) -> AeroEnvironmentOperation` to `environment_fulfillment.gd`. The default base implementation should call existing `fulfill()`, wrap the terminal result in an already-finished `AeroEnvironmentOperation`, and return it. This preserves sync compatibility automatically for existing and future sync-first handlers.
- Optionally add `supports_async() -> bool` with a default `false`, mainly for UI/adapter convenience. This is helpful but not strictly required if `begin_fulfill()` always exists.
- `environment_kind_handler.gd` can inherit the new default behavior unchanged; most kinds will remain sync until they explicitly override `begin_fulfill()`.

**How gaussian-splat should use the extension cleanly:**
- Keep `src/AeroGaussianSplatEnvironmentFulfillment.gd::fulfill()` as the existing synchronous contract path so current typed-contract tests and simple consumers stay valid.
- Add `begin_fulfill(request: Variant) -> AeroEnvironmentOperation` in `AeroGaussianSplatEnvironmentFulfillment.gd`. It should:
  1. normalize the request with the existing validator,
  2. create an `AeroEnvironmentOperation`,
  3. emit a started/progress event for `state=running`, `status=loading`, `phase=reading`,
  4. start the lower runtime background path (`begin_create_splat_node_from_path()`),
  5. translate runtime `background_load_*` dictionaries into typed `AeroEnvironmentProgress` updates,
  6. on finish, apply config / optional `WorldEnvironment` compositor wiring in the adapter layer, then resolve to typed `AeroEnvironmentResult` or `AeroEnvironmentError`.
- The important mapping rule is: **runtime progress stays implementation-specific, contract progress stays typed and generic**. Recommended mapping from lower runtime to core progress is:
  - runtime started `{ pending=true, progress=0.0, phase=reading }` -> core progress `{ state=running, status=loading, phase=reading, progress=0.0 }`
  - runtime progressed `phase=decoding` -> core `{ state=running, status=decoding, phase=decoding, progress=<same> }`
  - runtime progressed `phase=building` -> core `{ state=running, status=instantiating, phase=building, progress=<same> }`
  - post-runtime config application -> core `{ state=running, status=applying_config, phase=applying_config, progress=max(existing, 0.95) }`
  - terminal success -> core final progress `{ state=succeeded, status=ready, phase=ready, progress=1.0 }`
  - terminal failure -> core final progress `{ state=failed, status=failed, phase=<last-known-phase>, progress=<last-known-progress> }`
- This lets gaussian-splat expose real async progress now without waiting for the separate visible-render/runtime bug to be fixed.

**Sync compatibility stance:**
- Existing sync consumers remain intact because `fulfill()` still returns terminal typed result/error values.
- Existing dictionary consumers remain intact because current DTO `to_dict()` behavior stays and new fields are additive.
- Existing loader signal consumers remain intact because loader can keep emitting dictionary progress payloads built from `AeroEnvironmentProgress.to_dict()` without understanding the async operation object yet.
- Existing gaussian-splat wrapper signals (`background_load_started`, `background_load_progressed`, `background_load_finished`) should remain for compatibility; the new contract async path should wrap them, not replace them.

**Loader follow-up recommendation:**
- `aerobeat-environment-loader` can remain untouched for this rollout slice unless implementation reveals a very small compatibility tweak is needed.
- Reason: the loader already has its own signal-based orchestration surface, and the proposed core changes are additive. It can continue using sync fulfillment plus its current progress emission. A later cleanup could teach loader to expose/consume `AeroEnvironmentOperation`, but that is not required to unblock the async gaussian-splat contract rollout.

**Validation that is real now vs. still blocked:**
- **Can validate now in core:** operation object state transitions; DTO round-tripping with new additive fields; default `begin_fulfill()` wrapping sync providers into already-finished operations; fake-provider tests for success/failure/cancel flows.
- **Can validate now in gaussian-splat repo:** adapter returns an `AeroEnvironmentOperation`; background runtime signals are translated into ordered typed progress events; final typed result/error resolution works; config application and optional compositor wiring still happen in the adapter after background decode/build completes; sync `fulfill()` continues to work.
- **Still blocked by the known splat bug:** claiming stable visible rendering/compositor success in real Forward+ / Vulkan runtime paths and claiming full end-to-end proof inside downstream assemblies such as `aerobeat-assembly-community`. The async contract plumbing can be declared complete even while that rendering bug remains open.

**Implementation recommendation strength:** strong enough to unblock Tasks 2 and 3. Task 1 should be treated as complete with this design. The only deliberate scope cut is that loader follow-up remains optional unless the coder finds a concrete break during implementation.

---

### Task 2: Implement async/progress/state support in `aerobeat-environment-core`

**Bead ID:** `aerobeat-environment-core-b75`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-02`  
**Prompt:** In repo `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core`, claim the assigned bead and implement the shared contract changes needed for async fulfillment, state updates, and progress reporting. Keep dependency direction clean, preserve compatibility with the existing sync-first contract where practical, add tests, validate, and commit/push before handoff unless blocked.

**Folders Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/`

**Files Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/src/contracts/data_types/environment_operation.gd`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/src/contracts/data_types/environment_progress.gd`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/src/contracts/globals/aero_environment_constants.gd`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/src/contracts/interfaces/environment_fulfillment.gd`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/src/contracts/interfaces/environment_kind_handler.gd`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/.testbed/tests/test_environment_contracts.gd`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/.testbed/tests/support/fake_success_fulfillment.gd`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/.testbed/tests/support/fake_failure_fulfillment.gd`
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-core/README.md`

**Status:** ✅ Complete

**Results:** Implemented the async contract additively without breaking the sync surface. `AeroEnvironmentProgress` now carries lifecycle `state`, implementation-specific `phase`, monotonic `sequence`, and `indeterminate` alongside the existing status/progress payload. Core constants now expose lifecycle states plus additive queued/failed/cancelled status vocabulary. New `AeroEnvironmentOperation` provides typed `started`, `progressed`, `succeeded`, `failed`, and `finished` signals plus helpers for success/failure/cancel transitions and progress snapshots. `AeroEnvironmentFulfillment` now exposes `begin_fulfill(request)` with a default sync-wrapper implementation that converts existing `fulfill()` results/errors/dictionaries into an already-finished operation, while `supports_async()` defaults to `false`. `AeroEnvironmentKindHandler` inherited the wrapper behavior unchanged, so no loader-facing break was introduced in this slice. Validation: `cd .testbed && godotenv addons install`; `godot --headless --path .testbed --import`; `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` (13/13 passing). Implementation commit: `0f5c86b` (`Add async environment operation contract`).

---

### Task 3: Adapt `aerobeat-environment-gaussian-splat` to the async/progress contract path

**Bead ID:** `aerobeat-environment-core-e7k`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-03`  
**Prompt:** In repo `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-gaussian-splat`, claim the assigned bead and adapt the wrapper/adapter layer so gaussian-splat exposes async fulfillment, state updates, and progress through the shared environment contract while preserving the lower fulfillment package boundary. Do not pretend the separate splat runtime bug is solved; implement the plumbing and document any validation limits clearly.

**Folders Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-gaussian-splat/`

**Files Created/Deleted/Modified:**
- Adapter/test/doc/manifest files to be determined by Task 1

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 4: Decide and implement any required loader compatibility follow-up

**Bead ID:** `aerobeat-environment-core-ggw`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-04`  
**Prompt:** In repo `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-loader`, claim the assigned bead only if Task 1 or Task 2 shows the loader needs compatibility updates for the expanded async/progress contract. Keep scope narrow and focused on API coherence rather than unrelated refactors.

**Folders Created/Deleted/Modified:**
- `/home/derrick/Documents/projects/aerobeat/aerobeat-environment-loader/` if needed

**Files Created/Deleted/Modified:**
- Only if Task 1/2 prove they are needed

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 5: QA the async/progress contract path with explicit bug-boundary notes

**Bead ID:** `aerobeat-environment-core-1r7`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Across the touched repos, claim the assigned bead and verify the async/progress/state contract path as far as current repo-local validation and the known gaussian-splat bug allow. Clearly separate successful plumbing validation from anything still blocked by the external splat bug.

**Folders Created/Deleted/Modified:**
- Validation only expected

**Files Created/Deleted/Modified:**
- Plan updates only unless minimal QA-fix follow-ups are absolutely required

**Status:** ⏳ Pending

**Results:** Pending.

---

### Task 6: Independently audit the async/progress rollout

**Bead ID:** `aerobeat-environment-core-ppj`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Across the touched repos, claim the assigned bead and independently audit whether the shared environment contract now genuinely supports async fulfillment, state updates, and progress reporting, while documenting any remaining blocker that is truly caused by the separate gaussian-splat runtime bug.

**Folders Created/Deleted/Modified:**
- Audit only expected

**Files Created/Deleted/Modified:**
- Plan updates only unless an audit retry is required

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
