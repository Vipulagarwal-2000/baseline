class_name EventDefinitionLoader
extends RefCounted


# ============================================================
# STATE
# ============================================================

var definitions: Array[EventDefinition] = []


# ============================================================
# LOAD DEFINITIONS
# ============================================================

func load_from_file(
	file_path: String
) -> bool:

	definitions.clear()

	if file_path.is_empty():
		return false

	if not FileAccess.file_exists(file_path):
		return false

	var file := FileAccess.open(
		file_path,
		FileAccess.READ
	)

	if file == null:
		return false

	var json_text := file.get_as_text()

	file.close()

	var json := JSON.new()

	var parse_result := json.parse(
		json_text
	)

	if parse_result != OK:
		return false

	var data = json.data

	if not data is Dictionary:
		return false

	if not data.has("events"):
		return false

	var event_data = data["events"]

	if not event_data is Array:
		return false

	for entry in event_data:

		if not entry is Dictionary:
			return false

		var definition := EventDefinition.new(
			str(entry.get("id", "")),
			str(entry.get("name", "")),
			str(entry.get("description", "")),
			str(entry.get("category", "general")),
			str(entry.get("scope", "country"))
		)

		var metadata = entry.get(
			"metadata",
			{}
		)

		if metadata is Dictionary:

			for key in metadata:

				definition.set_metadata_value(
					str(key),
					metadata[key]
				)

		definitions.append(
			definition
		)

	return true


# ============================================================
# LOOKUP
# ============================================================

func get_definition(
	event_id: String
) -> EventDefinition:

	if event_id.is_empty():
		return null

	for definition in definitions:

		if definition.id == event_id:
			return definition

	return null


# ============================================================
# ACCESS
# ============================================================

func get_definitions() -> Array[EventDefinition]:
	return definitions


func get_definition_count() -> int:
	return definitions.size()
