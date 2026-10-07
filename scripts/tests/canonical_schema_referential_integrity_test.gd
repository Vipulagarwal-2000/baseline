class_name CanonicalSchemaReferentialIntegrityTest
extends RefCounted


const CANONICAL_ID_PATH := "res://data/canonical_ids.json"
const DOMAIN_OWNERSHIP_PATH := "res://data/domain_ownership.json"


static func run() -> bool:
	var registry := CanonicalSchemaRegistry.new()
	var passed := true

	if not registry.is_loaded():
		TestLogger.write_line(
			"Canonical schema registry available for integrity audit: FAIL | "
			+ registry.get_load_error()
		)
		return false

	var canonical_data = _load_json(
		CANONICAL_ID_PATH
	)

	var ownership_data = _load_json(
		DOMAIN_OWNERSHIP_PATH
	)

	if typeof(canonical_data) != TYPE_DICTIONARY:
		TestLogger.write_line(
			"Canonical ID registry readable for schema audit: FAIL"
		)
		return false

	if typeof(ownership_data) != TYPE_DICTIONARY:
		TestLogger.write_line(
			"Domain ownership registry readable for schema audit: FAIL"
		)
		return false

	var canonical_domains = canonical_data.get(
		"domains",
		{}
	)

	var ownership_domains = ownership_data.get(
		"domains",
		{}
	)

	if typeof(canonical_domains) != TYPE_DICTIONARY:
		TestLogger.write_line(
			"Canonical ID domain map readable for schema audit: FAIL"
		)
		return false

	if typeof(ownership_domains) != TYPE_DICTIONARY:
		TestLogger.write_line(
			"Domain ownership map readable for schema audit: FAIL"
		)
		return false

	for raw_domain_id in canonical_domains.keys():
		var domain_id := str(raw_domain_id)

		if not registry.has_domain(domain_id):
			TestLogger.write_line(
				"Every canonical ID domain has a schema: "
				+ domain_id
				+ ": FAIL"
			)
			passed = false
			continue

		if not ownership_domains.has(domain_id):
			TestLogger.write_line(
				"Every canonical ID domain has ownership and schema: "
				+ domain_id
				+ ": FAIL"
			)
			passed = false
			continue

		var schema := registry.get_domain_schema(domain_id)
		var schema_status := str(
			schema.get(
				"schema_status",
				""
			)
		)

		var canonical_status := str(
			canonical_domains[domain_id].get(
				"status",
				""
			)
		)

		if (
			canonical_status == "reserved_unmodeled"
			and schema_status != "reserved_identity_contract"
		):
			TestLogger.write_line(
				"Reserved canonical domain keeps reserved schema status: "
				+ domain_id
				+ ": FAIL"
			)
			passed = false

		if (
			canonical_status != "reserved_unmodeled"
			and schema_status == "reserved_identity_contract"
		):
			TestLogger.write_line(
				"Active/partial canonical domain is not identity-only reserved: "
				+ domain_id
				+ ": FAIL"
			)
			passed = false

		var ownership = ownership_domains[domain_id]
		var ownership_canonical_domain := str(
			ownership.get(
				"canonical_domain",
				""
			)
		)

		var schema_canonical_domain := str(
			schema.get(
				"canonical_domain",
				""
			)
		)

		if (
			ownership_canonical_domain != domain_id
			or schema_canonical_domain != domain_id
		):
			TestLogger.write_line(
				"Schema/ownership/canonical ID identity agrees: "
				+ domain_id
				+ ": FAIL"
			)
			passed = false

	if passed:
		TestLogger.write_line(
			"Canonical schema references agree with IDs and ownership: PASS"
		)

	TestLogger.write_line(
		"CanonicalSchemaReferentialIntegrityTest: "
		+ (
			"PASS"
			if passed
			else "FAIL"
		)
	)

	return passed


static func _load_json(path: String):
	if not FileAccess.file_exists(path):
		return null

	var file := FileAccess.open(
		path,
		FileAccess.READ
	)

	if file == null:
		return null

	var parsed = JSON.parse_string(
		file.get_as_text()
	)

	file.close()
	return parsed
