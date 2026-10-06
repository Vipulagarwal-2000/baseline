class_name GovernmentSpendingAllocationSystem
extends SimulationSystem


# ============================================================
# GOVERNMENT — STEP 8.6
# GOVERNMENT SPENDING ALLOCATION
# ============================================================
#
# EconomyComponent owns total government_spending.
# GovernmentComponent owns the allocation shares and this system
# derives the category amounts.
#
# MVP categories:
#   infrastructure
#   military
#   public_services
#   administration
#
# This step intentionally does NOT create service outputs, military
# effects, infrastructure changes, or a second fiscal model. Those
# belong to later government-causal steps.
# ============================================================

const EPSILON: float = 0.000001

const CATEGORIES: Array[String] = [
	"infrastructure",
	"military",
	"public_services",
	"administration"
]

const DEFAULT_SHARES: Dictionary = {
	"infrastructure": 0.30,
	"military": 0.20,
	"public_services": 0.30,
	"administration": 0.20
}


func _init() -> void:
	super("government_spending_allocation_system")


func process_month(world: WorldState) -> void:

	if world == null:
		return

	for entity in world.entities.values():

		if entity == null:
			continue

		var government = entity.get_component("government")
		var economy = entity.get_component("economy")

		if government == null or economy == null:
			continue

		_process_country(
			government,
			economy
		)


func _process_country(government, economy) -> void:

	var raw_shares = government.get_state(
		"government_spending_allocation_shares",
		DEFAULT_SHARES
	)

	if not raw_shares is Dictionary:
		_record_result(
			government,
			"rejected",
			["invalid_share_state"],
			{}
		)
		return

	var shares: Dictionary = {}
	var errors: Array[String] = []
	var share_total: float = 0.0

	for category in CATEGORIES:

		var raw_value = raw_shares.get(
			category,
			DEFAULT_SHARES.get(
				category,
				0.0
			)
		)

		if not (raw_value is int or raw_value is float):
			errors.append(
				"invalid_share:" + category
			)
			continue

		var share: float = float(raw_value)

		if share < 0.0 or share > 1.0:
			errors.append(
				"share_out_of_range:" + category
			)
			continue

		shares[category] = share
		share_total += share

	for raw_category in raw_shares.keys():

		var category_name: String = str(raw_category)

		if not CATEGORIES.has(category_name):
			errors.append(
				"unsupported_category:" + category_name
			)

	if absf(share_total - 1.0) > EPSILON:
		errors.append(
			"share_total_must_equal_1.0:" + str(share_total)
		)

	if not errors.is_empty():
		_record_result(
			government,
			"rejected",
			errors,
			{}
		)
		return

	var raw_total = economy.get_state(
		"government_spending",
		0.0
	)

	var government_spending: float = 0.0

	if raw_total is int or raw_total is float:
		government_spending = maxf(
			float(raw_total),
			0.0
		)

	var allocations: Dictionary = {}

	for category in CATEGORIES:
		allocations[category] = (
			government_spending
			* float(shares[category])
		)

	var allocation_total: float = 0.0

	for category in CATEGORIES:
		allocation_total += float(
			allocations[category]
		)

	var raw_current_allocations = government.get_state(
		"government_spending_allocation",
		{}
	)

	var current_allocations: Dictionary = (
		raw_current_allocations.duplicate(true)
		if raw_current_allocations is Dictionary
		else {}
	)

	var current_total: float = float(
		government.get_state(
			"government_spending_allocation_total",
			0.0
		)
	)

	var unchanged: bool = (
		is_equal_approx(
			current_total,
			allocation_total
		)
		and _dictionary_values_match(
			current_allocations,
			allocations
		)
	)

	if unchanged:
		_record_result(
			government,
			"no_change",
			[],
			{
				"shares": shares,
				"government_spending": government_spending,
				"allocations": allocations,
				"total": allocation_total
			}
		)
		return

	government.set_state(
		"government_spending_allocation_shares",
		shares.duplicate(true)
	)

	government.set_state(
		"government_spending_allocation",
		allocations.duplicate(true)
	)

	government.set_state(
		"government_spending_allocation_total",
		allocation_total
	)

	_record_result(
		government,
		"applied",
		[],
		{
			"shares": shares,
			"government_spending": government_spending,
			"allocations": allocations,
			"total": allocation_total
		}
	)


func _dictionary_values_match(
	left_value,
	right_value
	) -> bool:

	if not left_value is Dictionary:
		return false

	for category in CATEGORIES:

		if not left_value.has(category):
			return false

		if not is_equal_approx(
			float(left_value.get(category, 0.0)),
			float(right_value.get(category, 0.0))
		):
			return false

	return true


func _record_result(
	government,
	action: String,
	errors: Array,
	changes: Dictionary
	) -> void:

	var previous_revision: int = int(
		government.get_state(
			"government_spending_allocation_revision",
			0
		)
	)

	var changed: bool = (
		action == "applied"
	)

	var revision: int = previous_revision

	if changed:
		revision += 1

	var result: Dictionary = {
		"action": action,
		"revision": revision,
		"errors": errors.duplicate(true),
		"allocation": changes.duplicate(true)
	}

	if changed:

		var ledger = government.get_state(
			"government_spending_allocation_ledger",
			{}
		)

		if not ledger is Dictionary:
			ledger = {}

		ledger[str(revision)] = result.duplicate(true)

		government.set_state(
			"government_spending_allocation_revision",
			revision
		)

		government.set_state(
			"government_spending_allocation_ledger",
			ledger
		)

	government.set_state(
		"government_spending_allocation_last_result",
		result
	)
