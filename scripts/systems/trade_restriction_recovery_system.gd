class_name TradeRestrictionRecoverySystem
extends SimulationSystem


# ============================================================
# TRADE — STEP 11.4 RESTRICTION REMOVAL / RECOVERY
# ============================================================
#
# Purpose:
#   Lift previously-applied trade restrictions without rebuilding,
#   resetting, or silently rewriting the underlying agreement / route.
#
# Ownership remains unchanged:
#   TradeAgreement -> embargo/interruption lifecycle
#   TradeRoute     -> route restriction state / base capacity
#   TradeSystem    -> future trade execution
#
# This system is an explicit recovery service. It does not automatically
# restore restrictions, restart paused agreements, rewrite old transactions,
# or modify historical quantities/payments.
# ============================================================

const SYSTEM_NAME := "trade_restriction_recovery_system"


func _init() -> void:
	super(SYSTEM_NAME)


func process_month(world: WorldState) -> void:
	# Recovery is explicit. There is intentionally no automatic monthly
	# recovery because removal of a restriction must be an explicit world
	# action and must not silently restart a paused contract.
	if world == null:
		push_error("TradeRestrictionRecoverySystem: World is null.")


func remove_embargo(
	world: WorldState,
	agreement_id: String
) -> bool:

	if world == null:
		return false

	var agreement: TradeAgreement = (
		world.get_trade_agreement(agreement_id)
		as TradeAgreement
	)

	if agreement == null:
		return false

	# Do not report a change when the agreement was never embargoed. This
	# keeps removal idempotent and avoids touching unrelated interruption state.
	if not agreement.is_embargoed():
		return false

	return agreement.set_embargoed(false)


func remove_route_restriction(
	world: WorldState,
	route_id: String
) -> bool:

	if world == null:
		return false

	var route: TradeRoute = (
		world.get_trade_route(route_id)
		as TradeRoute
	)

	if route == null:
		return false

	return route.clear_route_restriction()


func resume_interrupted_agreement(
	world: WorldState,
	agreement_id: String
) -> bool:

	if world == null:
		return false

	var agreement: TradeAgreement = (
		world.get_trade_agreement(agreement_id)
		as TradeAgreement
	)

	if agreement == null:
		return false

	# Step 11.4 only resumes embargo-caused interruption. Other lifecycle
	# interruptions remain owned by their original cause/system. Cancelled
	# agreements remain terminal and cannot be reopened here.
	if agreement.status != TradeAgreement.STATUS_INTERRUPTED:
		return false

	if agreement.lifecycle_reason != TradeAgreement.CAUSE_EMBARGO:
		return false

	return agreement.resume()


func recover_trade(
	world: WorldState,
	agreement_id: String,
	route_id: String,
	remove_embargo_flag: bool = true,
	remove_route_restriction_flag: bool = true,
	resume_interrupted: bool = true
) -> Dictionary:

	var result: Dictionary = {
		"embargo_removed": false,
		"route_restriction_removed": false,
		"agreement_resumed": false,
		"changed": false
	}

	if world == null:
		return result

	if remove_embargo_flag:
		var embargo_removed: bool = remove_embargo(
			world,
			agreement_id
		)
		result["embargo_removed"] = embargo_removed

		# TradeAgreement.set_embargoed(false) explicitly resumes an embargo
		# interruption. Record that transition as part of this recovery call.
		if embargo_removed:
			var recovered_agreement: TradeAgreement = (
				world.get_trade_agreement(agreement_id)
				as TradeAgreement
			)
			result["agreement_resumed"] = (
				recovered_agreement != null
				and recovered_agreement.status == TradeAgreement.STATUS_ACTIVE
			)

	if remove_route_restriction_flag:
		var route_removed: bool = remove_route_restriction(
			world,
			route_id
		)
		result["route_restriction_removed"] = route_removed

	if resume_interrupted and not bool(result["agreement_resumed"]):
		var resumed: bool = resume_interrupted_agreement(
			world,
			agreement_id
		)
		result["agreement_resumed"] = resumed

	result["changed"] = (
		bool(result["embargo_removed"])
		or bool(result["route_restriction_removed"])
		or bool(result["agreement_resumed"])
	)

	return result
