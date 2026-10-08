class_name DataTestRunner
extends RefCounted


# ============================================================
# DATA TEST RUNNER
# ============================================================
#
# Phase 3 data/governance validation isolated from RunAllTests.
#
# The result now carries structured source-aware diagnostics so the master
# diagnostic summary can point directly to the failing test source.
# Phase 4.4A adds the technology catalog foundation checks to this same
# data/governance runner because they validate definition data and control
# metadata rather than mutable runtime state.
# Phase 4.4C adds technology/runtime parity and causal-content validation
# without moving runtime technology authority out of TechnologyManager /
# TechnologyLibrary.
# ============================================================


const RUNNER_ID: String = "data"
const DISPLAY_NAME: String = "Data Test Runner"


static func run() -> TestRunResult:

	var result: TestRunResult = TestRunResult.new(
		RUNNER_ID,
		DISPLAY_NAME
	)

	TestLogger.start_scope(
		RUNNER_ID,
		DISPLAY_NAME
	)

	TestLogger.section(
		"DATA TEST RUNNER"
	)

	TestLogger.write_line(
		"Phase 3 data/governance validation + Phase 4.4A technology catalog foundation + Phase 4.4C causal/content validation"
	)

	# ============================================================
	# STEP 3.1 — CANONICAL RESOURCE DATA CONTRACT
	# ============================================================

	TestLogger.section(
		"[DATA] CANONICAL RESOURCE CATALOG — STEP 3.1"
	)

	_record(
		result,
		"Step 3.1 Resource Catalog Schema",
		ResourceCatalogSchemaTest.run(),
		"res://scripts/tests/resource_catalog_schema_test.gd",
		"Resource catalog schema validation returned FAIL.",
		"Inspect the resource catalog schema test and canonical resource catalog."
	)

	_record(
		result,
		"Step 3.1 Resource Catalog Referential Integrity",
		ResourceCatalogReferentialIntegrityTest.run(),
		"res://scripts/tests/resource_catalog_referential_integrity_test.gd",
		"Resource catalog referential integrity validation returned FAIL.",
		"Inspect resource references in country and production data against the canonical resource catalog."
	)

	# ============================================================
	# PHASE 3.1 — COMPLETE DATA INVENTORY
	# ============================================================

	TestLogger.section(
		"[DATA] COMPLETE DATA INVENTORY — PHASE 3.1"
	)

	_record(
		result,
		"Phase 3.1 Data Inventory",
		DataInventoryTest.run(),
		"res://scripts/tests/data_inventory_test.gd",
		"Complete data inventory validation returned FAIL.",
		"Inspect the declared inventory and repository data file set."
	)

	# ============================================================
	# STEP 3.2 — CANONICAL ID REGISTRY
	# ============================================================

	TestLogger.section(
		"[DATA] CANONICAL ID REGISTRY — STEP 3.2"
	)

	_record(
		result,
		"Step 3.2 Canonical ID Registry Schema",
		CanonicalIdRegistryTest.run(),
		"res://scripts/tests/canonical_id_registry_test.gd",
		"Canonical ID registry schema validation returned FAIL.",
		"Inspect canonical domain declarations and canonical ID registry structure."
	)

	_record(
		result,
		"Step 3.2 Canonical ID Referential Integrity",
		CanonicalIdReferentialIntegrityTest.run(),
		"res://scripts/tests/canonical_id_referential_integrity_test.gd",
		"Canonical ID referential integrity validation returned FAIL.",
		"Inspect referenced domain IDs against the canonical ID registry."
	)

	# ============================================================
	# STEP 3.3 — DOMAIN OWNERSHIP
	# ============================================================

	TestLogger.section(
		"[DATA] DOMAIN OWNERSHIP — STEP 3.3"
	)

	_record(
		result,
		"Step 3.3 Domain Ownership Registry",
		DomainOwnershipRegistryTest.run(),
		"res://scripts/tests/domain_ownership_registry_test.gd",
		"Domain ownership registry validation returned FAIL.",
		"Inspect domain ownership declarations and authority policy."
	)

	_record(
		result,
		"Step 3.3 Domain Ownership Referential Integrity",
		DomainOwnershipReferentialIntegrityTest.run(),
		"res://scripts/tests/domain_ownership_referential_integrity_test.gd",
		"Domain ownership referential integrity validation returned FAIL.",
		"Inspect ownership references against the canonical domain and schema registries."
	)

	# ============================================================
	# STEP 3.4 — CANONICAL SCHEMAS
	# ============================================================

	TestLogger.section(
		"[DATA] CANONICAL SCHEMAS — STEP 3.4"
	)

	_record(
		result,
		"Step 3.4 Canonical Schema Registry",
		CanonicalSchemaRegistryTest.run(),
		"res://scripts/tests/canonical_schema_registry_test.gd",
		"Canonical schema registry validation returned FAIL.",
		"Inspect canonical schema declarations and required schema contracts."
	)

	_record(
		result,
		"Step 3.4 Canonical Schema Referential Integrity",
		CanonicalSchemaReferentialIntegrityTest.run(),
		"res://scripts/tests/canonical_schema_referential_integrity_test.gd",
		"Canonical schema referential integrity validation returned FAIL.",
		"Inspect schema-to-domain references and source paths."
	)

	# ============================================================
	# STEP 3.5 — REFERENTIAL INTEGRITY
	# ============================================================

	TestLogger.section(
		"[DATA] REFERENTIAL INTEGRITY — STEP 3.5"
	)

	_record(
		result,
		"Step 3.5 Referential Integrity Rules Registry",
		ReferentialIntegrityRulesRegistryTest.run(),
		"res://scripts/tests/referential_integrity_rules_registry_test.gd",
		"Referential integrity rule registry validation returned FAIL.",
		"Inspect referential integrity rule declarations and selector definitions."
	)

	_record(
		result,
		"Step 3.5 Referential Integrity Audit",
		ReferentialIntegrityAuditTest.run(),
		"res://scripts/tests/referential_integrity_audit_test.gd",
		"Referential integrity audit returned FAIL.",
		"Inspect the failed cross-domain references reported by the audit."
	)

	# ============================================================
	# STEP 3.6 — PROVENANCE
	# ============================================================

	TestLogger.section(
		"[DATA] PROVENANCE — STEP 3.6"
	)

	_record(
		result,
		"Step 3.6 Provenance Registry",
		ProvenanceRegistryTest.run(),
		"res://scripts/tests/provenance_registry_test.gd",
		"Provenance registry validation returned FAIL.",
		"Inspect provenance declarations and record coverage."
	)

	_record(
		result,
		"Step 3.6 Provenance Referential Integrity",
		ProvenanceReferentialIntegrityTest.run(),
		"res://scripts/tests/provenance_referential_integrity_test.gd",
		"Provenance referential integrity validation returned FAIL.",
		"Inspect provenance coverage against the declared data inventory."
	)

	# ============================================================
	# STEP 3.7 — VERSIONING
	# ============================================================

	TestLogger.section(
		"[DATA] VERSIONING — STEP 3.7"
	)

	_record(
		result,
		"Step 3.7 Versioning Registry",
		VersioningRegistryTest.run(),
		"res://scripts/tests/versioning_registry_test.gd",
		"Versioning registry validation returned FAIL.",
		"Inspect version metadata, record counts, and controlled-version declarations."
	)

	_record(
		result,
		"Step 3.7 Versioning Referential Integrity",
		VersioningReferentialIntegrityTest.run(),
		"res://scripts/tests/versioning_referential_integrity_test.gd",
		"Versioning referential integrity validation returned FAIL.",
		"Inspect versioning records against the data inventory."
	)

	# ============================================================
	# STEP 3.8 — CATALOG / LOADER OWNERSHIP
	# ============================================================

	TestLogger.section(
		"[DATA] CATALOG / LOADER OWNERSHIP — STEP 3.8"
	)

	_record(
		result,
		"Step 3.8 Catalog/Loader Ownership Registry",
		CatalogLoaderOwnershipRegistryTest.run(),
		"res://scripts/tests/catalog_loader_ownership_registry_test.gd",
		"Catalog/loader ownership registry validation returned FAIL.",
		"Inspect catalog/loader ownership declarations and domain coverage."
	)

	_record(
		result,
		"Step 3.8 Catalog/Loader Ownership Referential Integrity",
		CatalogLoaderOwnershipReferentialIntegrityTest.run(),
		"res://scripts/tests/catalog_loader_ownership_referential_integrity_test.gd",
		"Catalog/loader ownership referential integrity validation returned FAIL.",
		"Inspect ownership mappings against canonical domains and schemas."
	)

	# ============================================================
	# PHASE 4.4A — TECHNOLOGY CATALOG FOUNDATION
	# ============================================================

	TestLogger.section(
		"[DATA] TECHNOLOGY CATALOG FOUNDATION — PHASE 4.4A"
	)

	_record(
		result,
		"Phase 4.4A Technology Catalog Schema",
		TechnologyCatalogSchemaTest.run(),
		"res://scripts/tests/technology_catalog_schema_test.gd",
		"Technology catalog schema validation returned FAIL.",
		"Inspect the technology catalog contract, definitions, and schema test."
	)

	_record(
		result,
		"Phase 4.4A Technology Catalog Semantic Validation",
		TechnologyCatalogSemanticTest.run(),
		"res://scripts/tests/technology_catalog_semantic_test.gd",
		"Technology catalog semantic validation returned FAIL.",
		"Inspect technology IDs, prerequisite references, capability lists, historical windows, and definition metadata."
	)

	# ============================================================
	# PHASE 4.4C — TECHNOLOGY CAUSAL / CONTENT VALIDATION
	# ============================================================

	TestLogger.section(
		"[DATA] TECHNOLOGY CAUSAL / CONTENT VALIDATION — PHASE 4.4C"
	)

	_record(
		result,
		"Phase 4.4C Technology Catalog Runtime Parity",
		TechnologyCatalogRuntimeParityTest.run(),
		"res://scripts/tests/technology_catalog_runtime_parity_test.gd",
		"Technology catalog/runtime parity validation returned FAIL.",
		"Inspect the dedicated technology catalog against DefaultTechnologies runtime definitions."
	)

	_record(
		result,
		"Phase 4.4C Technology Causal Content Validation",
		TechnologyCausalContentValidationTest.run(),
		"res://scripts/tests/technology_causal_content_validation_test.gd",
		"Technology causal/content validation returned FAIL.",
		"Inspect prerequisite ordering, effect compatibility, production-process technology references, and reference-only boundaries."
	)

	result.set_metadata(
		"scope",
		"Phase 3 data/governance + Phase 4.4A technology catalog foundation + Phase 4.4C technology/runtime parity and causal content validation"
	)

	result.set_metadata(
		"tests_expected",
		21
	)

	result.set_metadata(
		"requires_world",
		false
	)

	result.set_metadata(
		"requires_simulation",
		false
	)

	result.set_metadata(
		"mutation_policy",
		"read_only"
	)

	# Detailed execution output remains in the active TestLogger stream.
	# The structured runner result intentionally stores only compact test
	# counts and structured failure diagnostics so result files stay small.
	result.set_metadata(
		"detail_source",
		"legacy TestLogger report"
	)

	result.set_metadata(
		"compact_result",
		true
	)

	result.finish()

	TestLogger.write_line("")
	TestLogger.write_line(
		result.summary_line()
	)

	TestLogger.finish()

	return result


static func _record(
	result: TestRunResult,
	test_name: String,
	passed: bool,
	source_file: String,
	diagnostic_message: String,
	action: String
) -> void:

	result.record_test(
		test_name,
		passed,
		"",
		source_file,
		diagnostic_message,
		action
	)

	TestLogger.write_line("")
	TestLogger.write_line(
		test_name
		+ ": "
		+ (
			"PASS"
			if passed
			else "FAIL"
		)
	)
