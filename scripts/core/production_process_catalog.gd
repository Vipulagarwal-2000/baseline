class_name ProductionProcessCatalog
extends RefCounted


var processes: Dictionary = {}


func _init() -> void:
	_load_catalog()


func _load_catalog() -> void:
	var file_path := "res://data/production_processes/production_processes.json"

	if not FileAccess.file_exists(file_path):
		push_error(
			"ProductionProcessCatalog: Catalog file not found: "
			+ file_path
		)
		return

	var file := FileAccess.open(
		file_path,
		FileAccess.READ
	)

	if file == null:
		push_error(
			"ProductionProcessCatalog: Could not open catalog."
		)
		return

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(text)

	if parse_result != OK:
		push_error(
			"ProductionProcessCatalog: JSON parse failed."
		)
		return

	var data = json.data

	if typeof(data) != TYPE_DICTIONARY:
		push_error(
			"ProductionProcessCatalog: Root must be a Dictionary."
		)
		return

	for process_id in data.keys():
		var definition = data[process_id]

		if typeof(definition) != TYPE_DICTIONARY:
			continue

		processes[str(process_id)] = (
			definition.duplicate(true)
		)


func has_process(
	process_id: String
) -> bool:
	return processes.has(process_id)


func get_process(
	process_id: String
) -> Dictionary:

	if not processes.has(process_id):
		return {}

	return processes[process_id].duplicate(true)


func get_process_ids() -> Array:
	return processes.keys()


func get_available_process_ids(
	year: int
) -> Array:

	var available: Array = []

	for process_id in processes.keys():
		var definition: Dictionary = processes[process_id]

		var available_from := int(
			definition.get(
				"available_from",
				-999999
			)
		)

		var available_until_value = definition.get(
			"available_until",
			null
		)

		if year < available_from:
			continue

		if available_until_value != null:
			var available_until := int(
				available_until_value
			)

			if year > available_until:
				continue

		available.append(process_id)

	return available
