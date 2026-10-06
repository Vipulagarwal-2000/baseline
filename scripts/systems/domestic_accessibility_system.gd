class_name DomesticAccessibilitySystem
extends SimulationSystem


const EPSILON: float = 0.000001


func _init() -> void:
	super("domestic_accessibility_system")


func process_month(world: WorldState) -> void:

	if world == null:
		push_error(
			"DomesticAccessibilitySystem: World is null."
		)
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		var resources = entity.get_component(
			"resources"
		)

		if resources == null:
			continue

		_process_entity(
			resources
		)


func _process_entity(
	resources: ResourceComponent
) -> void:

	# Step 5.10 remains the physical distribution owner. Step 7.3 makes
	# the country-level accessibility result explicit and auditable without
	# introducing another stockpile, transport model, or distribution layer.
	var resolved_supply_value = resources.get_state(
		"resolved_supply",
		{}
	)
	var exports_value = resources.get_state(
		"exports",
		{}
	)
	var accessibility_value = resources.get_state(
		"accessibility",
		{}
	)
	var domestic_accessible_value = resources.get_state(
		"domestic_accessible_supply",
		{}
	)
	var distribution_loss_value = resources.get_state(
		"distribution_access_loss",
		{}
	)
	var distribution_ledger_value = resources.get_state(
		"domestic_distribution_ledger",
		{}
	)

	var resolved_supply: Dictionary = _as_dictionary(
		resolved_supply_value
	)
	var exports: Dictionary = _as_dictionary(
		exports_value
	)
	var accessibility: Dictionary = _as_dictionary(
		accessibility_value
	)
	var domestic_accessible_supply: Dictionary = _as_dictionary(
		domestic_accessible_value
	)
	var distribution_access_loss: Dictionary = _as_dictionary(
		distribution_loss_value
	)
	var distribution_ledger: Dictionary = _as_dictionary(
		distribution_ledger_value
	)

	var resource_names: Dictionary = {}

	_collect_keys(
		resource_names,
		resolved_supply
	)
	_collect_keys(
		resource_names,
		exports
	)
	_collect_keys(
		resource_names,
		accessibility
	)
	_collect_keys(
		resource_names,
		domestic_accessible_supply
	)
	_collect_keys(
		resource_names,
		distribution_access_loss
	)
	_collect_keys(
		resource_names,
		distribution_ledger
	)

	if resource_names.is_empty():
		_clear_derived_state(
			resources
		)
		return

	var domestic_physical_supply: Dictionary = {}
	var domestic_accessibility_factor: Dictionary = {}
	var accessibility_reconciliation_error: Dictionary = {}
	var accessibility_ledger: Dictionary = {}

	var total_physical := 0.0
	var total_accessible := 0.0
	var total_access_loss := 0.0

	for resource_name_value in resource_names.keys():

		var resource_id := str(
			resource_name_value
		)

		var resolved := maxf(
			float(
				resolved_supply.get(
					resource_id,
					0.0
				)
			),
			0.0
		)

		var reserved_exports := maxf(
			float(
				exports.get(
					resource_id,
					0.0
				)
			),
			0.0
		)
		reserved_exports = minf(
			reserved_exports,
			resolved
		)

		# Prefer the Step 5.10 ledger because it is the current authoritative
		# record of the physically resolved domestic distribution quantity and
		# its already-applied accessibility factor.
		var upstream_entry_value = distribution_ledger.get(
			resource_id,
			{}
		)
		var upstream_entry: Dictionary = _as_dictionary(
			upstream_entry_value
		)

		var physical_domestic := maxf(
			resolved - reserved_exports,
			0.0
		)

		var access_factor := clampf(
			float(
				accessibility.get(
					resource_id,
					1.0
				)
			),
			0.0,
			1.0
		)

		if upstream_entry.has("supply_after_exports"):
			physical_domestic = maxf(
				float(
					upstream_entry.get(
						"supply_after_exports",
						physical_domestic
					)
				),
				0.0
			)

		if upstream_entry.has("accessibility"):
			access_factor = clampf(
				float(
					upstream_entry.get(
						"accessibility",
						access_factor
					)
				),
				0.0,
				1.0
			)

		var expected_accessible := (
			physical_domestic * access_factor
		)
		var expected_loss := maxf(
			physical_domestic - expected_accessible,
			0.0
		)

		var upstream_accessible := maxf(
			float(
				domestic_accessible_supply.get(
					resource_id,
					expected_accessible
				)
			),
			0.0
		)

		var upstream_loss := maxf(
			float(
				distribution_access_loss.get(
					resource_id,
					expected_loss
				)
			),
			0.0
		)

		var reconciliation_error := maxf(
			absf(
			upstream_accessible
			- expected_accessible
			),
			absf(
			upstream_loss
			- expected_loss
			)
		)

		# The derived 7.3 states expose the same authoritative result rather
		# than replacing the Step 5.10 owner.
		domestic_physical_supply[resource_id] = physical_domestic
		domestic_accessibility_factor[resource_id] = access_factor
		accessibility_reconciliation_error[resource_id] = reconciliation_error

		accessibility_ledger[resource_id] = {
			"resolved_supply": resolved,
			"export_quantity_reserved": reserved_exports,
			"physical_domestic_supply": physical_domestic,
			"accessibility": access_factor,
			"expected_accessible_supply": expected_accessible,
			"authoritative_accessible_supply": upstream_accessible,
			"access_loss": expected_loss,
			"authoritative_access_loss": upstream_loss,
			"reconciliation_error": reconciliation_error,
			"source": "step_5_10_resource_allocation_distribution"
		}

		total_physical += physical_domestic
		total_accessible += upstream_accessible
		total_access_loss += upstream_loss

	resources.set_state(
		"domestic_physical_supply",
		domestic_physical_supply
	)
	resources.set_state(
		"domestic_accessibility_factor",
		domestic_accessibility_factor
	)
	resources.set_state(
		"domestic_accessibility_reconciliation_error",
		accessibility_reconciliation_error
	)
	resources.set_state(
		"domestic_accessibility_ledger",
		accessibility_ledger
	)
	resources.set_state(
		"domestic_accessibility_total_physical",
		total_physical
	)
	resources.set_state(
		"domestic_accessibility_total_accessible",
		total_accessible
	)
	resources.set_state(
		"domestic_accessibility_total_loss",
		total_access_loss
	)


func _clear_derived_state(
	resources: ResourceComponent
) -> void:

	resources.set_state(
		"domestic_physical_supply",
		{}
	)
	resources.set_state(
		"domestic_accessibility_factor",
		{}
	)
	resources.set_state(
		"domestic_accessibility_reconciliation_error",
		{}
	)
	resources.set_state(
		"domestic_accessibility_ledger",
		{}
	)
	resources.set_state(
		"domestic_accessibility_total_physical",
		0.0
	)
	resources.set_state(
		"domestic_accessibility_total_accessible",
		0.0
	)
	resources.set_state(
		"domestic_accessibility_total_loss",
		0.0
	)


func _as_dictionary(value) -> Dictionary:

	if typeof(value) == TYPE_DICTIONARY:
		return value

	return {}


func _collect_keys(
	resource_names: Dictionary,
	values: Dictionary
) -> void:

	for resource_name in values.keys():
		resource_names[str(resource_name)] = true
