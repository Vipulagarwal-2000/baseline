class_name DomainOwnershipRegistryTest
extends RefCounted


const REQUIRED_DOMAINS: Array = [
	"country",
	"region",
	"resource",
	"process",
	"technology",
	"research_program",
	"policy",
	"action",
	"event",
	"trade",
	"scenario",
	"external_actor"
]


static func run() -> bool:
	var registry := DomainOwnershipRegistry.new()
	var passed := true

	if not registry.is_loaded():
		TestLogger.write_line(
			"Domain ownership registry loads: FAIL | "
			+ registry.get_load_error()
		)
		return false

	TestLogger.write_line(
		"Domain ownership registry loads: PASS"
	)

	if registry.get_version() <= 0:
		TestLogger.write_line(
			"Domain ownership registry version: FAIL"
		)
		passed = false
	else:
		TestLogger.write_line(
			"Domain ownership registry version: PASS"
		)

	if registry.get_ownership_id().strip_edges().is_empty():
		TestLogger.write_line(
			"Domain ownership registry identifier: FAIL"
		)
		passed = false
	else:
		TestLogger.write_line(
			"Domain ownership registry identifier: PASS"
		)

	var policy := registry.get_policy()

	if (
		not policy.get(
			"one_authoritative_owner_per_domain",
			false
		)
	):
		TestLogger.write_line(
			"Domain ownership policy: one authoritative owner: FAIL"
		)
		passed = false
	else:
		TestLogger.write_line(
			"Domain ownership policy: one authoritative owner: PASS"
		)

	if (
		not policy.get(
			"definition_and_runtime_are_distinct",
			false
		)
	):
		TestLogger.write_line(
			"Domain ownership policy: definition/runtime separation: FAIL"
		)
		passed = false
	else:
		TestLogger.write_line(
			"Domain ownership policy: definition/runtime separation: PASS"
		)

	var invalid_entries := registry.get_invalid_entries()

	if invalid_entries.is_empty():
		TestLogger.write_line(
			"Domain ownership entry schema: PASS"
		)
	else:
		TestLogger.write_line(
			"Domain ownership entry schema: FAIL | "
			+ ", ".join(invalid_entries)
		)
		passed = false

	var missing_domains := registry.get_domains_missing_from(
		REQUIRED_DOMAINS
	)

	if missing_domains.is_empty():
		TestLogger.write_line(
			"Required domain ownership entries exist: PASS"
		)
	else:
		TestLogger.write_line(
			"Required domain ownership entries exist: FAIL | "
			+ ", ".join(missing_domains)
		)
		passed = false

	var duplicate_domains := (
		registry.get_duplicate_canonical_domains()
	)

	if duplicate_domains.is_empty():
		TestLogger.write_line(
			"Canonical domain owners are unique: PASS"
		)
	else:
		TestLogger.write_line(
			"Canonical domain owners are unique: FAIL | "
			+ ", ".join(duplicate_domains)
		)
		passed = false

	var invalid_paths := registry.get_invalid_definition_paths()

	if invalid_paths.is_empty():
		TestLogger.write_line(
			"Domain ownership definition paths are canonical: PASS"
		)
	else:
		TestLogger.write_line(
			"Domain ownership definition paths are canonical: FAIL | "
			+ ", ".join(invalid_paths)
		)
		passed = false

	for domain_id in registry.get_domain_ids():
		var definition := registry.get_domain(domain_id)

		TestLogger.write_line(
			"Domain ownership entry: "
			+ domain_id
			+ ": "
			+ str(definition.get("status", ""))
		)

	TestLogger.write_line(
		"DomainOwnershipRegistryTest: "
		+ (
			"PASS"
			if passed
			else "FAIL"
		)
	)

	return passed
