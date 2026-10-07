class_name DomainOwnershipReferentialIntegrityTest
extends RefCounted


const CANONICAL_ID_PATH := (
	"res://data/canonical_ids.json"
)


static func run() -> bool:
	var registry := DomainOwnershipRegistry.new()
	var passed := true

	if not registry.is_loaded():
		TestLogger.write_line(
			"Domain ownership registry available for integrity audit: FAIL | "
			+ registry.get_load_error()
		)
		return false

	var canonical_data = _load_json(CANONICAL_ID_PATH)

	if typeof(canonical_data) != TYPE_DICTIONARY:
		TestLogger.write_line(
			"Canonical ID registry readable for domain ownership audit: FAIL"
		)
		return false

	var canonical_domains = canonical_data.get(
		"domains",
		{}
	)

	if typeof(canonical_domains) != TYPE_DICTIONARY:
		TestLogger.write_line(
			"Canonical ID domains readable for ownership audit: FAIL"
		)
		return false

	for raw_domain_id in canonical_domains.keys():
		var domain_id := str(raw_domain_id)

		if not registry.has_domain(domain_id):
			TestLogger.write_line(
				"Canonical domain has an ownership entry: "
				+ domain_id
				+ ": FAIL"
			)
			passed = false
			continue

		var ownership := registry.get_domain(domain_id)

		if str(
			ownership.get(
				"canonical_domain",
				""
			)
		) != domain_id:
			TestLogger.write_line(
				"Canonical domain ownership matches registry domain: "
				+ domain_id
				+ ": FAIL"
			)
			passed = false
			continue

		var canonical_definition = canonical_domains[domain_id]

		var canonical_status := str(
			canonical_definition.get(
				"status",
				""
			)
		)

		var ownership_status := str(
			ownership.get(
				"status",
				""
			)
		)

		if (
			canonical_status == "active"
			and ownership_status == "reserved_unmodeled"
		):
			TestLogger.write_line(
				"Active canonical domain is not reserved: "
				+ domain_id
				+ ": FAIL"
			)
			passed = false

		var definition_paths = ownership.get(
			"definition_paths",
			[]
		)

		if typeof(definition_paths) != TYPE_ARRAY:
			continue

		for raw_path in definition_paths:
			var path := str(raw_path)

			if path.is_empty():
				continue

			if path.begins_with("res://") and not (
				FileAccess.file_exists(path)
				or DirAccess.dir_exists_absolute(
					ProjectSettings.globalize_path(path)
				)
			):
				TestLogger.write_line(
					"Domain ownership source path exists: "
					+ domain_id
					+ " -> "
					+ path
					+ ": FAIL"
				)
				passed = false

	if passed:
		TestLogger.write_line(
			"All canonical domains have coherent ownership: PASS"
		)

	TestLogger.write_line(
		"DomainOwnershipReferentialIntegrityTest: "
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
