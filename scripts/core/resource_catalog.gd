class_name ResourceCatalog
extends RefCounted

const CATALOG_PATH := "res://data/resources/resource_catalog.json"

var resources: Dictionary = {}
var unit_policy: Dictionary = {}


func _init() -> void:
    _load_catalog()


func _load_catalog() -> void:
    resources = {}
    unit_policy = {}

    if not FileAccess.file_exists(CATALOG_PATH):
        push_error(
            "ResourceCatalog: Catalog file not found: "
            + CATALOG_PATH
        )
        return

    var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
    if file == null:
        push_error("ResourceCatalog: Could not open catalog.")
        return

    var parsed = JSON.parse_string(file.get_as_text())
    file.close()

    if typeof(parsed) != TYPE_DICTIONARY:
        push_error("ResourceCatalog: Catalog root must be a dictionary.")
        return

    var parsed_resources = parsed.get("resources", {})
    if typeof(parsed_resources) != TYPE_DICTIONARY:
        push_error("ResourceCatalog: 'resources' must be a dictionary.")
        return

    var parsed_unit_policy = parsed.get("unit_policy", {})
    if typeof(parsed_unit_policy) == TYPE_DICTIONARY:
        unit_policy = parsed_unit_policy.duplicate(true)

    for resource_id in parsed_resources.keys():
        var definition = parsed_resources[resource_id]
        if typeof(definition) != TYPE_DICTIONARY:
            push_error(
                "ResourceCatalog: Invalid definition for "
                + str(resource_id)
            )
            continue

        resources[str(resource_id)] = definition.duplicate(true)


func has_resource(resource_id: String) -> bool:
    return resources.has(resource_id)


func get_resource(resource_id: String) -> Dictionary:
    if not resources.has(resource_id):
        return {}
    return resources[resource_id].duplicate(true)


func get_resource_ids() -> Array:
    var ids: Array = resources.keys()
    ids.sort()
    return ids


func get_unit_policy() -> Dictionary:
    return unit_policy.duplicate(true)


func get_unknown_resource_ids(resource_ids: Array) -> Array:
    var unknown: Array = []

    for raw_id in resource_ids:
        var resource_id := str(raw_id)
        if resource_id.is_empty():
            continue

        if not has_resource(resource_id):
            unknown.append(resource_id)

    unknown.sort()
    return unknown
