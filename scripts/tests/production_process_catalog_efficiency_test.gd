class_name ProductionProcessCatalogEfficiencyTest
extends RefCounted


static func run() -> bool:

	var catalog := ProductionProcessCatalog.new()

	var steel := catalog.get_process(
		"steel_basic"
	)

	if steel.is_empty():
		print(
			"Catalog efficiency test: steel_basic missing: FAIL"
		)
		return false

	var efficiency := float(
		steel.get(
			"efficiency",
			-1.0
		)
	)

	if efficiency != 1.0:
		print(
			"steel_basic catalog efficiency: FAIL | expected=1.0 actual="
			+ str(efficiency)
		)
		return false

	print(
		"steel_basic catalog efficiency: PASS | value="
		+ str(efficiency)
	)

	var advanced := catalog.get_process(
		"advanced_steel_production"
	)

	if advanced.is_empty():
		print(
			"Advanced steel catalog lookup: FAIL"
		)
		return false

	var advanced_efficiency := float(
		advanced.get(
			"efficiency",
			-1.0
		)
	)

	if advanced_efficiency != 1.10:
		print(
			"advanced_steel_production catalog efficiency: FAIL | expected=1.10 actual="
			+ str(advanced_efficiency)
		)
		return false

	print(
		"advanced_steel_production catalog efficiency: PASS | value="
		+ str(advanced_efficiency)
	)

	print(
		"ProductionProcessCatalogEfficiencyTest: PASS"
	)

	return true
