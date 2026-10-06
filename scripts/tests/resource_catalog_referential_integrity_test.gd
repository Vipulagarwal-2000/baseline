class_name ResourceCatalogReferentialIntegrityTest
extends RefCounted


const COUNTRY_PATHS: Array = [
    "res://data/countries/china.json",
    "res://data/countries/india.json",
    "res://data/countries/usa.json"
]

const PRODUCTION_CATALOG_PATH := (
    "res://data/production_processes/production_processes.json"
)


static func run() -> bool:
    var catalog := ResourceCatalog.new()
    var referenced_resource_ids: Dictionary = {}
    var passed := true

    for path in COUNTRY_PATHS:
        var data = _load_json(path)

        if typeof(data) != TYPE_DICTIONARY:
            print(
                "Country data readable for resource audit: "
                + path
                + ": FAIL"
            )
            passed = false
            continue

        var resources = data.get("resources", {})
        if typeof(resources) != TYPE_DICTIONARY:
            continue

        for section_name in [
            "production",
            "consumption",
            "reserves",
            "stockpile",
            "imports",
            "exports"
        ]:
            var section = resources.get(section_name, {})
            if typeof(section) != TYPE_DICTIONARY:
                continue

            for resource_id in section.keys():
                referenced_resource_ids[str(resource_id)] = true

    var production_data = _load_json(PRODUCTION_CATALOG_PATH)

    if typeof(production_data) != TYPE_DICTIONARY:
        print("Production catalog readable for resource audit: FAIL")
        passed = false
    else:
        for process_id in production_data.keys():
            var definition = production_data[process_id]
            if typeof(definition) != TYPE_DICTIONARY:
                continue

            for field_name in [
                "inputs",
                "outputs",
                "energy_requirement",
                "maintenance_requirement"
            ]:
                var section = definition.get(field_name, {})
                if typeof(section) != TYPE_DICTIONARY:
                    continue

                for resource_id in section.keys():
                    referenced_resource_ids[str(resource_id)] = true

    var referenced_ids: Array = referenced_resource_ids.keys()
    referenced_ids.sort()

    var unknown_ids := catalog.get_unknown_resource_ids(
        referenced_ids
    )

    if not unknown_ids.is_empty():
        print(
            "Resource references missing from canonical catalog: "
            + ", ".join(unknown_ids)
            + ": FAIL"
        )
        passed = false
    else:
        print(
            "All country and production resource references resolve: PASS"
        )

    print(
        "ResourceCatalogReferentialIntegrityTest: "
        + ("PASS" if passed else "FAIL")
    )

    return passed


static func _load_json(path: String):
    if not FileAccess.file_exists(path):
        return null

    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return null

    var parsed = JSON.parse_string(file.get_as_text())
    file.close()
    return parsed
