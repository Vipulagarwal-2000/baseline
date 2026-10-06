class_name TradeEmbargoSystem
extends SimulationSystem


# ============================================================
# TRADE — STEP 11.1 EMBARGO
# ============================================================
#
# Implements the MVP embargo layer without creating a second trade model.
#
# Ownership:
#   TradeAgreement  -> durable embargo state
#   TradeEmbargoSystem -> applies/removes/enforces the restriction
#   TradeSystem     -> remains the authoritative trade executor
#
# An embargo uses the already-verified interruption lifecycle:
#
#   ACTIVE
#      ↓ apply embargo
#   INTERRUPTED / cause="embargo"
#      ↓ remove embargo explicitly
#   ACTIVE
#
# Remaining contract duration is preserved while embargoed. Because
# TradeSystem already ignores interrupted agreements, no trade transaction,
# physical stock movement, valuation, or payment is created for an embargoed
# month. This keeps Step 11.1 modular and avoids changing the ownership of
# the existing trade/resource/payment systems.
# ============================================================

const SYSTEM_NAME := "trade_embargo_system"
const EMBARGO_CAUSE := TradeAgreement.CAUSE_EMBARGO


func _init():
	super(SYSTEM_NAME)


func process_month(world: WorldState) -> void:

	if world == null:
		push_error("TradeEmbargoSystem: World is null.")
		return

	var agreement_ids: Array = world.trade_agreements.keys()
	agreement_ids.sort()

	for agreement_id in agreement_ids:

		var agreement: TradeAgreement = world.get_trade_agreement(
			agreement_id
		) as TradeAgreement

		if agreement == null:
			continue

		if not agreement is TradeAgreement:
			continue

		if not agreement.embargoed:
			continue

		# Re-assert the embargo if an external caller changed the lifecycle
		# state back to ACTIVE without explicitly removing the restriction.
		if agreement.status == TradeAgreement.STATUS_ACTIVE:
			agreement.interrupt(EMBARGO_CAUSE)


# ============================================================
# DIRECT AGREEMENT CONTROL
# ============================================================

func apply_embargo_to_agreement(
	world: WorldState,
	agreement_id: String
) -> bool:

	if world == null:
		return false

	var agreement: TradeAgreement = world.get_trade_agreement(
		agreement_id
	) as TradeAgreement

	if agreement == null:
		return false

	if not agreement is TradeAgreement:
		return false

	return agreement.set_embargoed(true)


func remove_embargo_from_agreement(
	world: WorldState,
	agreement_id: String
) -> bool:

	if world == null:
		return false

	var agreement: TradeAgreement = world.get_trade_agreement(
		agreement_id
	) as TradeAgreement

	if agreement == null:
		return false

	if not agreement is TradeAgreement:
		return false

	return agreement.set_embargoed(false)


# ============================================================
# ACTOR / RESOURCE TARGETING
# ============================================================
#
# Exact exporter/importer matching is required. resource_id may be empty to
# target every resource agreement between the specified pair.
#
# Returns the number of agreements whose embargo state was changed by the
# operation. Existing already-embargoed agreements are still considered
# matched but are not counted as newly changed.
# ============================================================

func apply_embargo_to_trade(
	world: WorldState,
	exporter_id: String,
	importer_id: String,
	resource_id: String = ""
) -> int:

	return _set_trade_embargo(
		world,
		exporter_id,
		importer_id,
		resource_id,
		true
	)


func remove_embargo_from_trade(
	world: WorldState,
	exporter_id: String,
	importer_id: String,
	resource_id: String = ""
) -> int:

	return _set_trade_embargo(
		world,
		exporter_id,
		importer_id,
		resource_id,
		false
	)


func _set_trade_embargo(
	world: WorldState,
	exporter_id: String,
	importer_id: String,
	resource_id: String,
	enabled: bool
) -> int:

	if world == null:
		return 0

	if exporter_id.is_empty() or importer_id.is_empty():
		return 0

	if exporter_id == importer_id:
		return 0

	var changed_count := 0

	var agreement_ids: Array = world.trade_agreements.keys()
	agreement_ids.sort()

	for agreement_id in agreement_ids:

		var agreement: TradeAgreement = world.get_trade_agreement(
			agreement_id
		) as TradeAgreement

		if agreement == null:
			continue

		if not agreement is TradeAgreement:
			continue

		if agreement.exporter_id != exporter_id:
			continue

		if agreement.importer_id != importer_id:
			continue

		if (
			not resource_id.is_empty()
			and agreement.resource_id != resource_id
		):
			continue

		var old_state: bool = agreement.embargoed
		var changed: bool = agreement.set_embargoed(enabled)

		if changed and old_state != agreement.embargoed:
			changed_count += 1

	return changed_count


func is_agreement_embargoed(
	world: WorldState,
	agreement_id: String
) -> bool:

	if world == null:
		return false

	var agreement: TradeAgreement = world.get_trade_agreement(
		agreement_id
	) as TradeAgreement

	if agreement == null:
		return false

	if not agreement is TradeAgreement:
		return false

	return agreement.embargoed
