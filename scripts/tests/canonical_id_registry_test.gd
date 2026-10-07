class_name CanonicalIdRegistryTest
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
	var registry := CanonicalIdRegistry.new()
	var passed := true

	if not registry.is_loaded():
		TestLogger.write_line(
			"Canonical ID registry loads: FAIL | "
			+ registry.get_load_error()
		)
		return false

	TestLogger.write_line("Canonical ID registry loads: PASS")

	if registry.get_version() <= 0:
		TestLogger.write_line("Canonical ID registry version: FAIL")
		passed = false
	else:
		TestLogger.write_line("Canonical ID registry version: PASS")

	if registry.get_registry_id().is_empty():
		TestLogger.write_line("Canonical ID registry identifier: FAIL")
		passed = false
	else:
		TestLogger.write_line("Canonical ID registry identifier: PASS")

	var policy := registry.get_id_policy()
	if not policy.has("general_pattern") or not policy.has("stability"):
		TestLogger.write_line("Canonical ID policy metadata: FAIL")
		passed = false
	else:
		TestLogger.write_line("Canonical ID policy metadata: PASS")

	for domain in REQUIRED_DOMAINS:
		if not registry.has_domain(domain):
			TestLogger.write_line(
				"Required canonical ID domain exists: "
				+ domain
				+ ": FAIL"
			)
			passed = false
			continue

		TestLogger.write_line(
			"Required canonical ID domain exists: "
			+ domain
			+ ": PASS"
		)

	for domain in registry.get_domains():
		var ids := registry.get_domain_ids(domain)
		var domain_valid := true

		for identifier in ids:
			var entry := registry.get_entry(domain, str(identifier))

			if str(entry.get("status", "")).is_empty():
				TestLogger.write_line(
					"Canonical ID entry status present: "
					+ domain
					+ "/"
					+ str(identifier)
					+ ": FAIL"
				)
				domain_valid = false

			var source_paths = entry.get("source_paths", [])
			if typeof(source_paths) != TYPE_ARRAY or source_paths.is_empty():
				TestLogger.write_line(
					"Canonical ID source paths present: "
					+ domain
					+ "/"
					+ str(identifier)
					+ ": FAIL"
				)
				domain_valid = false

			if str(identifier) != str(entry.get("id", identifier)):
				TestLogger.write_line(
					"Canonical ID entry matches registry key: "
					+ domain
					+ "/"
					+ str(identifier)
					+ ": FAIL"
				)
				domain_valid = false

			if not registry.matches_id_format(domain, str(identifier)):
				TestLogger.write_line(
					"Canonical ID format is valid: "
					+ domain
					+ "/"
					+ str(identifier)
					+ ": FAIL"
				)
				domain_valid = false

		if domain_valid:
			TestLogger.write_line(
				"Canonical ID domain entry schema: "
				+ domain
				+ ": PASS | count="
				+ str(ids.size())
			)
		else:
			passed = false

	var globally_seen: Dictionary = {}
	for domain in registry.get_domains():
		for identifier in registry.get_domain_ids(domain):
			var key := str(identifier)
			if globally_seen.has(key):
				TestLogger.write_line(
					"Canonical ID has one registry owner: "
					+ key
					+ ": FAIL | domains="
					+ str(globally_seen[key])
					+ ","
					+ domain
				)
				passed = false
			else:
				globally_seen[key] = domain

	if passed:
		TestLogger.write_line("CanonicalIdRegistryTest: PASS")
	else:
		TestLogger.write_line("CanonicalIdRegistryTest: FAIL")

	return passed
