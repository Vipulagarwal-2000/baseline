class_name ProductionProcessCatalogTest
extends RefCounted


static func run() -> bool:

	var catalog := ProductionProcessCatalog.new()

	var passed := true

	if not catalog.has_process("steel_basic"):
		print("Catalog steel_basic: FAIL")
		passed = false
	else:
		print("Catalog steel_basic: PASS")

	if not catalog.has_process("coal_mining"):
		print("Catalog coal_mining: FAIL")
		passed = false
	else:
		print("Catalog coal_mining: PASS")

	if not catalog.has_process("iron_ore_mining"):
		print("Catalog iron_ore_mining: FAIL")
		passed = false
	else:
		print("Catalog iron_ore_mining: PASS")

	if not catalog.has_process(
		"advanced_steel_production"
	):
		print(
			"Catalog advanced_steel_production: FAIL"
		)
		passed = false
	else:
		print(
			"Catalog advanced_steel_production: PASS"
		)

	var steel := catalog.get_process(
		"steel_basic"
	)

	if float(
		steel.get("inputs", {}).get("iron", 0.0)
	) != 2.0:
		print("Steel iron input: FAIL")
		passed = false
	else:
		print("Steel iron input: PASS")

	var available_1950 := (
		catalog.get_available_process_ids(1950)
	)

	if not available_1950.has("steel_basic"):
		print(
			"1950 steel availability: FAIL"
		)
		passed = false
	else:
		print(
			"1950 steel availability: PASS"
		)

	if available_1950.has(
		"advanced_steel_production"
	):
		print(
			"1950 advanced steel blocked: FAIL"
		)
		passed = false
	else:
		print(
			"1950 advanced steel blocked: PASS"
		)

	var available_1955 := (
		catalog.get_available_process_ids(1955)
	)

	if not available_1955.has(
		"advanced_steel_production"
	):
		print(
			"1955 advanced steel date availability: FAIL"
		)
		passed = false
	else:
		print(
			"1955 advanced steel date availability: PASS"
		)

	print(
		"ProductionProcessCatalog test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed
