# Phase 4.7A Design Notes — Policy Catalog Runtime Binding

## Verified starting point

The authoritative source was identified as `Vipulagarwal-2000/baseline` `main` at commit `08b317032617a9a8f60dc025775969c3482720e8`. The uploaded Run 791 report states overall `PASS`, full-suite scope, all seven runners passing, zero failed runners and zero failures/errors. Its Data Test Runner report states 25 tests run, 25 passed, zero failed, zero errored and zero diagnostics.

The 4.6B catalog has schema version 2 and three simulation-calibrated definitions: `revenue_mobilization`, `investment_stimulation`, and `infrastructure_priority`. The definitions cover all six effect keys currently supported by `GovernmentPolicyEffectSystem`. The catalog schema stays at version 2 in this phase; the catalog contract/content version advances to 3.0.0 for the explicit runtime-binding contract.

## Existing authorities preserved

- `PolicyCatalog` remains a read-only loader for `data/policies/policy_catalog.json`.
- `GovernmentPolicyDefinition` remains the runtime-compatible definition object.
- `GovernmentComponent` remains the owner of registered definitions and mutable activation/cost/effect audit state.
- Existing government policy cost and effect systems remain the execution authorities.
- The policy definitions' numeric values, costs, durations, effects and simulation-calibration provenance are not reinterpreted as real historical country observations.

## New binder

`PolicyCatalogRuntimeBinder` validates the catalog identity, minimum contract version, runtime mapping contract, activation boundary and runtime-state authority contract before attempting registration. It validates all catalog entries against the currently supported cost/effect contracts and rejects duplicate runtime activation targets, overlapping effect ownership, an incomplete supported-effect set, and invalid spending-share bundles.

Every government component in the world is preflighted before mutation. An existing same-ID definition is accepted only if its complete serialized runtime payload equals the expected catalog-derived payload; a mismatch rejects the whole binding attempt. Repeated binding is idempotent. Disabled entries are validated but not registered. A defensive rollback restores saved component states if a definition API unexpectedly rejects a definition during the commit pass.

Catalog metadata not represented directly by `GovernmentPolicyDefinition` (display name, description, provenance, definition version and catalog identity/version) is retained under the runtime metadata key `catalog_binding`. Authored policy metadata remains present beside it.

## Startup and tests

`main.gd` calls the binder after initial country entities enter the world and before downstream simulation setup. A failure is reported via `push_error` and is visible in the validation report.

A new Data-runner contract check validates the version and declared binding contract. A new Domain-runner test checks the live startup-bound countries, confirms no policy was activated/charged/applied, and exercises idempotency, disabled entries, incompatible-contract rejection and conflict preflight using isolated synthetic worlds.

## Explicitly out of scope

This phase does not activate any policy, invoke `request_policy_activation`, process cost requests, apply effect maps, schedule duration expiry, replace the policy runtime APIs, change the policy entry schema, or introduce a generic DataManager.

## Verification boundary

The package was reconstructed and statically checked in the authoring environment. No Godot executable is available there, so GDScript parse/compile success and the 26/95 local runner totals must be confirmed by the project's Godot runtime before Phase 4.7A is accepted as passed.
