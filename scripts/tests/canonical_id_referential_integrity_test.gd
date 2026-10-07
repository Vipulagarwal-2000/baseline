class_name CanonicalIdReferentialIntegrityTest
extends RefCounted


const COUNTRY_PATHS: Array = [
	"res://data/countries/china.json",
	"res://data/countries/india.json",
	"res://data/countries/usa.json"
]

const REGION_PATHS: Array = [
	"res://data/regions/china_regions.json",
	"res://data/regions/india_regions.json",
	"res://data/regions/usa_regions.json"
]

const REGIONAL_PROFILE_PATHS: Array = [
	"res://data/regions/industry/china_industry.json",
	"res://data/regions/industry/india_industry.json",
	"res://data/regions/industry/usa_industry.json",
	"res://data/regions/infrastructure/china_infrastructure.json",
	"res://data/regions/infrastructure/india_infrastructure.json",
	"res://data/regions/infrastructure/usa_infrastructure.json",
	"res://data/regions/population/china_population.json",
	"res://data/regions/population/india_population.json",
	"res://data/regions/population/usa_population.json",
	"res://data/regions/resources/china_resources.json",
	"res://data/regions/resources/india_resources.json",
	"res://data/regions/resources/usa_resources.json",
	"res://data/regions/transport/china_transport.json",
	"res://data/regions/transport/india_transport.json",
	"res://data/regions/transport/usa_transport.json",
	"res://data/regions/terrain/china_terrain.json",
	"res://data/regions/terrain/india_terrain.json",
	"res://data/regions/terrain/usa_terrain.json"
]

const PRODUCTION_CATALOG_PATH := "res://data/production_processes/production_processes.json"
const EVENT_CATALOG_PATH := "res://data/events/events.json"
const CURRENCY_PATH := "res://data/currency_exchange_rates.json"


static func run() -> bool:
	var registry := CanonicalIdRegistry.new()
	var passed := true

	if not registry.is_loaded():
		TestLogger.write_line(
			"Canonical ID registry available for integrity audit: FAIL | "
			+ registry.get_load_error()
		)
		return false

	var references: Dictionary = {}
	var _status := _collect_references(references)

	for domain in references.keys():
		var ids: Array = references[domain].keys()
		ids.sort()

		var unknown := registry.get_unknown_ids(domain, ids)
		if unknown.is_empty():
			TestLogger.write_line(
				"Canonical references resolve: "
				+ domain
				+ ": PASS | count="
				+ str(ids.size())
			)
		else:
			TestLogger.write_line(
				"Canonical references resolve: "
				+ domain
				+ ": FAIL | unknown="
				+ ", ".join(unknown)
			)
			passed = false

	if passed:
		TestLogger.write_line("CanonicalIdReferentialIntegrityTest: PASS")
	else:
		TestLogger.write_line("CanonicalIdReferentialIntegrityTest: FAIL")

	return passed


static func _collect_references(output: Dictionary) -> bool:
	var ok := true

	for path in COUNTRY_PATHS:
		var data = _load_json(path)
		if typeof(data) != TYPE_DICTIONARY:
			TestLogger.write_line("Country data readable for canonical ID audit: " + path + ": FAIL")
			ok = false
			continue

		_add(output, "country", str(data.get("id", "")))

		var relationships = data.get("relationships", {})
		if typeof(relationships) == TYPE_DICTIONARY:
			for country_id in relationships.keys():
				_add(output, "country", str(country_id))

		var resources = data.get("resources", {})
		if typeof(resources) == TYPE_DICTIONARY:
			for section_name in ["production", "consumption", "reserves", "stockpile", "imports", "exports"]:
				var section = resources.get(section_name, {})
				if typeof(section) != TYPE_DICTIONARY:
					continue

				for resource_id in section.keys():
					_add(output, "resource", str(resource_id))

		var industry = data.get("industry", {})
		if typeof(industry) == TYPE_DICTIONARY:
			var processes = industry.get("processes", {})
			if typeof(processes) == TYPE_DICTIONARY:
				for process_id in processes.keys():
					_add(output, "process", str(process_id))

		var research = data.get("research", {})
		if typeof(research) == TYPE_DICTIONARY:
			var technologies = research.get("technologies", {})
			if typeof(technologies) == TYPE_DICTIONARY:
				for technology_id in technologies.keys():
					_add(output, "technology", str(technology_id))

		var economy = data.get("economy", {})
		if typeof(economy) == TYPE_DICTIONARY:
			_add(output, "currency", str(economy.get("currency_id", "")))

	for path in REGION_PATHS:
		var data = _load_json(path)
		if typeof(data) != TYPE_DICTIONARY:
			TestLogger.write_line("Region data readable for canonical ID audit: " + path + ": FAIL")
			ok = false
			continue

		_add(output, "country", str(data.get("country_id", "")))
		_collect_field_values(data, "id", output, "region")

	for path in REGIONAL_PROFILE_PATHS:
		var data = _load_json(path)
		if typeof(data) != TYPE_DICTIONARY:
			TestLogger.write_line("Regional data readable for canonical ID audit: " + path + ": FAIL")
			ok = false
			continue

		_add(output, "country", str(data.get("country_id", "")))
		_collect_field_values(data, "region_id", output, "region")
		_collect_field_values(data, "route_id", output, "route")
		_collect_field_values(data, "from_region_id", output, "region")
		_collect_field_values(data, "to_region_id", output, "region")

		if path.find("regions/industry/") != -1:
			_collect_field_values(data, "process_id", output, "process")
			_collect_process_keys(data, output)

	var production_data = _load_json(PRODUCTION_CATALOG_PATH)
	if typeof(production_data) != TYPE_DICTIONARY:
		TestLogger.write_line("Production catalog readable for canonical ID audit: FAIL")
		ok = false
	else:
		for process_id in production_data.keys():
			_add(output, "process", str(process_id))
			var definition = production_data[process_id]
			if typeof(definition) != TYPE_DICTIONARY:
				continue
			var technology_requirements = definition.get("technology_requirements", {})
			if typeof(technology_requirements) == TYPE_DICTIONARY:
				for technology_id in technology_requirements.keys():
					_add(output, "technology", str(technology_id))
			var capability_requirements = definition.get("capability_requirements", {})
			if typeof(capability_requirements) == TYPE_DICTIONARY:
				for capability_id in capability_requirements.keys():
					_add(output, "capability", str(capability_id))
			var infrastructure_requirements = definition.get("infrastructure_requirements", {})
			if typeof(infrastructure_requirements) == TYPE_DICTIONARY:
				for infrastructure_id in infrastructure_requirements.keys():
					_add(output, "infrastructure", str(infrastructure_id))
			var infrastructure_usage = definition.get("infrastructure_usage", {})
			if typeof(infrastructure_usage) == TYPE_DICTIONARY:
				for infrastructure_id in infrastructure_usage.keys():
					_add(output, "infrastructure", str(infrastructure_id))
			var equipment_requirement = definition.get("equipment_requirement", {})
			if typeof(equipment_requirement) == TYPE_DICTIONARY:
				for equipment_id in equipment_requirement.keys():
					_add(output, "equipment", str(equipment_id))
			for resource_field in [
				"inputs",
				"outputs",
				"byproducts",
				"energy_requirement",
				"maintenance_requirement",
				"waste"
			]:
				var resource_section = definition.get(resource_field, {})
				if typeof(resource_section) != TYPE_DICTIONARY:
					continue

				for resource_id in resource_section.keys():
					_add(output, "resource", str(resource_id))

			var displacement = definition.get("displacement", {})
			if typeof(displacement) == TYPE_DICTIONARY:
				for displacement_process_id in displacement.keys():
					_add(output, "process", str(displacement_process_id))

	var event_data = _load_json(EVENT_CATALOG_PATH)
	if typeof(event_data) != TYPE_DICTIONARY:
		TestLogger.write_line("Event catalog readable for canonical ID audit: FAIL")
		ok = false
	else:
		var events = event_data.get("events", [])
		if typeof(events) == TYPE_ARRAY:
			for event in events:
				if typeof(event) == TYPE_DICTIONARY:
					_add(output, "event", str(event.get("id", "")))

	var currency_data = _load_json(CURRENCY_PATH)
	if typeof(currency_data) != TYPE_DICTIONARY:
		TestLogger.write_line("Currency data readable for canonical ID audit: FAIL")
		ok = false
	else:
		_add(output, "currency", str(currency_data.get("base_currency", "")))
		var rates = currency_data.get("rates_to_base", {})
		if typeof(rates) == TYPE_DICTIONARY:
			for currency_id in rates.keys():
				_add(output, "currency", str(currency_id))

	return ok


static func _collect_process_keys(data, output: Dictionary) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return

	var processes = data.get("processes", {})
	if typeof(processes) == TYPE_DICTIONARY:
		for process_id in processes.keys():
			_add(output, "process", str(process_id))


static func _collect_field_values(data, field_name: String, output: Dictionary, domain: String) -> void:
	if typeof(data) == TYPE_DICTIONARY:
		for key in data.keys():
			if str(key) == field_name:
				_add(output, domain, str(data[key]))
			_collect_field_values(data[key], field_name, output, domain)
	elif typeof(data) == TYPE_ARRAY:
		for value in data:
			_collect_field_values(value, field_name, output, domain)


static func _add(output: Dictionary, domain: String, identifier: String) -> void:
	if identifier.is_empty():
		return

	if not output.has(domain):
		output[domain] = {}

	output[domain][identifier] = true


static func _load_json(path: String):
	if not FileAccess.file_exists(path):
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed
