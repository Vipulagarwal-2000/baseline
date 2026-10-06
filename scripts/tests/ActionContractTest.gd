class_name ActionContractTest
extends RefCounted


static func run() -> bool:
	TestLogger.section(
		"STEP 15.1 — COMMON EXECUTABLE ACTION CONTRACT TEST"
	)

	var passed: bool = true

	# ----------------------------------------------------------
	# Legacy constructor compatibility
	# ----------------------------------------------------------

	var action = SimAction.new(
		"diplomatic_outreach",
		"india",
		"china",
		8.0,
		3
	)

	passed = _check(
		"Legacy action type preserved",
		action.action_type == "diplomatic_outreach"
	) and passed

	passed = _check(
		"Legacy actor id preserved",
		action.actor_id == "india"
	) and passed

	passed = _check(
		"Legacy target id preserved",
		action.target_id == "china"
	) and passed

	passed = _check(
		"Legacy value preserved",
		is_equal_approx(action.value, 8.0)
	) and passed

	passed = _check(
		"Legacy duration preserved",
		action.duration_months == 3
	) and passed

	# ----------------------------------------------------------
	# Canonical Step 15 aliases
	# ----------------------------------------------------------

	passed = _check(
		"Canonical actor alias matches storage",
		action.actor == "india"
	) and passed

	passed = _check(
		"Canonical kind alias matches storage",
		action.kind == "diplomatic_outreach"
	) and passed

	passed = _check(
		"Canonical target alias matches storage",
		action.target == "china"
	) and passed

	passed = _check(
		"Canonical duration alias matches storage",
		action.duration == 3
	) and passed

	# ----------------------------------------------------------
	# Required default contract
	# ----------------------------------------------------------

	passed = _check(
		"Default state is queued",
		action.state == SimAction.STATE_QUEUED
	) and passed

	passed = _check(
		"Default start date is empty",
		action.start_date == ""
	) and passed

	passed = _check(
		"Default progress is zero",
		is_equal_approx(action.progress, 0.0)
	) and passed

	passed = _check(
		"Default cost is zero",
		is_equal_approx(action.cost, 0.0)
	) and passed

	passed = _check(
		"Default failure reason is empty",
		action.failure_reason == ""
	) and passed

	# ----------------------------------------------------------
	# Required requirement / outcome containers
	# ----------------------------------------------------------

	passed = _check(
		"Resource requirements container exists",
		action.resource_requirements is Dictionary
	) and passed

	passed = _check(
		"Financial requirements container exists",
		action.financial_requirements is Dictionary
	) and passed

	passed = _check(
		"Capability requirements container exists",
		action.capability_requirements is Dictionary
	) and passed

	passed = _check(
		"Capacity requirements container exists",
		action.capacity_requirements is Dictionary
	) and passed

	passed = _check(
		"Effects container exists",
		action.effects is Dictionary
	) and passed

	passed = _check(
		"Completion result container exists",
		action.completion_result is Dictionary
	) and passed

	# ----------------------------------------------------------
	# Contract mutation through canonical vocabulary
	# ----------------------------------------------------------

	action.actor = "usa"
	action.kind = "economic_policy"
	action.target = "india"
	action.duration = 5

	passed = _check(
		"Actor alias writes through to actor_id",
		action.actor_id == "usa"
	) and passed

	passed = _check(
		"Kind alias writes through to action_type",
		action.action_type == "economic_policy"
	) and passed

	passed = _check(
		"Target alias writes through to target_id",
		action.target_id == "india"
	) and passed

	passed = _check(
		"Duration alias writes through to duration_months",
		action.duration_months == 5
	) and passed

	# ----------------------------------------------------------
	# Mutable container isolation
	# ----------------------------------------------------------

	action.resource_requirements["iron"] = 10.0
	action.effects["relationship_delta"] = 2.5

	var second_action = SimAction.new(
		"diplomatic_outreach",
		"china",
		"india",
		2.0,
		1
	)

	passed = _check(
		"Resource requirements are instance-isolated",
		second_action.resource_requirements.is_empty()
	) and passed

	passed = _check(
		"Effects are instance-isolated",
		second_action.effects.is_empty()
	) and passed

	# ----------------------------------------------------------
	# Explicit contract payloads
	# ----------------------------------------------------------

	action.cost = 25.0
	action.resource_requirements = {
		"iron": 10.0,
		"coal": 5.0
	}
	action.financial_requirements = {
		"budget": 25.0
	}
	action.capability_requirements = {
		"diplomatic_capacity": 0.20
	}
	action.capacity_requirements = {
		"administrative_capacity": 0.10
	}
	action.state = SimAction.STATE_ACTIVE
	action.start_date = "1950-01-01"
	action.progress = 0.40
	action.effects = {
		"relationship_delta": 4.0
	}
	action.failure_reason = ""
	action.completion_result = {
		"success": true,
		"applied": true
	}

	passed = _check(
		"Cost payload stored",
		is_equal_approx(action.cost, 25.0)
	) and passed

	passed = _check(
		"Resource requirement payload stored",
		action.resource_requirements["iron"] == 10.0
	) and passed

	passed = _check(
		"Financial requirement payload stored",
		action.financial_requirements["budget"] == 25.0
	) and passed

	passed = _check(
		"Capability requirement payload stored",
		action.capability_requirements["diplomatic_capacity"] == 0.20
	) and passed

	passed = _check(
		"Capacity requirement payload stored",
		action.capacity_requirements["administrative_capacity"] == 0.10
	) and passed

	passed = _check(
		"State payload stored",
		action.state == SimAction.STATE_ACTIVE
	) and passed

	passed = _check(
		"Start date payload stored",
		action.start_date == "1950-01-01"
	) and passed

	passed = _check(
		"Progress payload stored",
		is_equal_approx(action.progress, 0.40)
	) and passed

	passed = _check(
		"Effects payload stored",
		action.effects["relationship_delta"] == 4.0
	) and passed

	passed = _check(
		"Completion result payload stored",
		action.completion_result["success"] == true
	) and passed

	TestLogger.write_line(
		"Step 15.1 Common Executable Action Contract test: "
		+ ("PASS" if passed else "FAIL")
	)

	return passed


static func _check(
	label: String,
	condition: bool
) -> bool:
	TestLogger.write_line(
		label
		+ ": "
		+ ("PASS" if condition else "FAIL")
	)

	return condition
