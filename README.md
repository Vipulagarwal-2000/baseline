# Phase 4.7A — Policy Catalog Runtime Binding

This batch targets the successful 4.6B content baseline currently identified by GitHub commit `08b317032617a9a8f60dc025775969c3482720e8` in `Vipulagarwal-2000/baseline`.

## Apply

1. Back up or commit local edits first.
2. Extract the archive into the Godot project root. The bundled `scripts/` tree is project-relative.
3. Run `py apply_phase_4_7A.py` from the project root, or run `apply_phase_4_7A.bat` on Windows.
4. Reopen/reload the project in Godot, run the full validation suite, and inspect the detailed Data Test Runner and master diagnostic summary.

The patcher checks source anchors and JSON contracts before writing the 11 existing-file replacements. If a source anchor differs, it aborts without writing those existing files. The three new GDScript files and their UID files are shipped separately at their project-relative paths.

## Runtime boundary

The binder registers enabled catalog definitions as `GovernmentPolicyDefinition` instances through `GovernmentComponent.define_policy()`. It does not activate a policy, queue an activation request, charge treasury, apply effects, or advance durations. The existing activation, cost, and effect systems remain the runtime authorities.

## Expected validation counts

- Data Test Runner: 26 tests
- Domain Test Runner: 95 tests
- All seven runners should pass

Godot compilation and the local full suite are not certified by static packaging checks; they must be run in the user's Godot workspace.
