class_name TradeRoute
extends RefCounted


# ============================================================
# TRADE ROUTE — STEPS 4.2 + 11.2
# ============================================================
#
# This class represents the durable connection between the two
# parties of an existing TradeAgreement.
#
# It intentionally does NOT:
# - calculate throughput
# - inspect ports / roads / railways
# - move resources
# - execute transactions
# - calculate import/export quantities
#
# Those concerns belong to later Trade substeps.
# ============================================================

const STATUS_DRAFT := "draft"
const STATUS_ACTIVE := "active"
const STATUS_INACTIVE := "inactive"
const STATUS_DISRUPTED := "disrupted"
const STATUS_CLOSED := "closed"

# A negative value means that the route has no explicit monthly
# throughput ceiling yet. Later infrastructure/port systems can
# impose the physical throughput limit without changing this route
# state model.
const UNLIMITED_THROUGHPUT := -1.0


# ============================================================
# IDENTITY
# ============================================================

var id: String = ""
var agreement_id: String = ""

var exporter_id: String = ""
var importer_id: String = ""

# Step 4.4 — configured route throughput ceiling.
# Negative means "not explicitly limited" and is treated as unlimited
# for the current quantity/availability layer.
var monthly_throughput_capacity: float = UNLIMITED_THROUGHPUT

# Step 11.2 — durable route-restriction state.
# The base route capacity remains untouched. A restriction is an overlay
# applied to the effective monthly throughput seen by TradeSystem.
var route_restriction_active: bool = false
var route_restriction_factor: float = 1.0
var route_restriction_reason: String = ""

var status: String = STATUS_DRAFT


func _init(
	route_id: String = "",
	linked_agreement_id: String = "",
	exporter: String = "",
	importer: String = "",
	throughput_capacity: float = UNLIMITED_THROUGHPUT
):

	id = route_id
	agreement_id = linked_agreement_id
	exporter_id = exporter
	importer_id = importer
	monthly_throughput_capacity = throughput_capacity


# ============================================================
# VALIDATION
# ============================================================

func is_valid() -> bool:

	if id.is_empty():
		return false

	if agreement_id.is_empty():
		return false

	if exporter_id.is_empty():
		return false

	if importer_id.is_empty():
		return false

	if exporter_id == importer_id:
		return false

	if monthly_throughput_capacity < UNLIMITED_THROUGHPUT:
		return false

	if not _is_valid_status(status):
		return false

	return true


func _is_valid_status(value: String) -> bool:

	return value in [
		STATUS_DRAFT,
		STATUS_ACTIVE,
		STATUS_INACTIVE,
		STATUS_DISRUPTED,
		STATUS_CLOSED
	]


# ============================================================
# LIFECYCLE
# ============================================================

func activate() -> bool:

	if not is_valid():
		return false

	if status == STATUS_CLOSED:
		return false

	status = STATUS_ACTIVE
	return true


func set_inactive() -> void:

	if status == STATUS_CLOSED:
		return

	status = STATUS_INACTIVE


func disrupt() -> void:

	if status == STATUS_CLOSED:
		return

	status = STATUS_DISRUPTED


func close() -> void:

	status = STATUS_CLOSED


# ============================================================
# THROUGHPUT / QUANTITY RULES — STEPS 4.4 + 11.2
# ============================================================

func has_throughput_limit() -> bool:

	return monthly_throughput_capacity >= 0.0


func get_available_throughput(
	requested_quantity: float
) -> float:

	var requested = max(0.0, requested_quantity)
	var base_available = requested

	if has_throughput_limit():
		base_available = min(
			requested,
			max(0.0, monthly_throughput_capacity)
		)

	if not route_restriction_active:
		return base_available

	return base_available * route_restriction_factor


# ============================================================
# STEP 11.2 — ROUTE RESTRICTION STATE
# ============================================================

func has_route_restriction() -> bool:

	return route_restriction_active


func apply_route_restriction(
	factor: float,
	reason: String = "blockade"
) -> bool:

	if status == STATUS_CLOSED:
		return false

	var normalized_factor: float = clampf(
		factor,
		0.0,
		1.0
	)
	var normalized_reason: String = reason.strip_edges()

	if (
		route_restriction_active
		and is_equal_approx(route_restriction_factor, normalized_factor)
		and route_restriction_reason == normalized_reason
	):
		return false

	route_restriction_active = true
	route_restriction_factor = normalized_factor
	route_restriction_reason = normalized_reason
	return true


func clear_route_restriction() -> bool:

	if not route_restriction_active:
		return false

	route_restriction_active = false
	route_restriction_factor = 1.0
	route_restriction_reason = ""
	return true


# ============================================================
# SNAPSHOT REPRESENTATION
# ============================================================

func to_snapshot_dict() -> Dictionary:

	return {
		"id": id,
		"agreement_id": agreement_id,
		"exporter_id": exporter_id,
		"importer_id": importer_id,
		"monthly_throughput_capacity": monthly_throughput_capacity,
		"status": status,
		"route_restriction_active": route_restriction_active,
		"route_restriction_factor": route_restriction_factor,
		"route_restriction_reason": route_restriction_reason
	}
