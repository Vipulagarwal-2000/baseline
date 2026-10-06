class_name TradeAgreement
extends RefCounted


# ============================================================
# TRADE AGREEMENT — STEPS 4.1 + 4.6 + 4.7
# ============================================================
#
# Durable bilateral trade-contract state.
#
# 4.7 adds a deliberately small lifecycle-control layer:
#   - interruption: temporary stop; duration is preserved
#   - cancellation: terminal stop; agreement cannot resume/reactivate
#   - lifecycle reason: records why the current lifecycle state changed
#
# The implementation does NOT create a full diplomacy/conflict system.
# It supports the concrete MVP controls needed for trade disruption and
# cancellation while leaving broader causes to later systems.
# ============================================================

const STATUS_DRAFT := "draft"
const STATUS_ACTIVE := "active"
const STATUS_INACTIVE := "inactive"
const STATUS_EXPIRED := "expired"
const STATUS_CANCELLED := "cancelled"
const STATUS_INTERRUPTED := "interrupted"

# Step 4.7 lifecycle causes implemented at this layer.
const CAUSE_MANUAL := "manual"
const CAUSE_ROUTE_DISRUPTION := "route_disruption"
const CAUSE_COUNTRY_DECISION := "country_decision"

# Step 11.1 — explicit trade embargo lifecycle cause.
# An embargo is temporary: it blocks execution while preserving the
# agreement and its remaining duration so the contract can resume when
# the embargo is explicitly removed.
const CAUSE_EMBARGO := "embargo"


# ============================================================
# IDENTITY
# ============================================================

var id: String = ""

var exporter_id: String = ""
var importer_id: String = ""
var resource_id: String = ""


# ============================================================
# AGREED FLOW
# ============================================================

var quantity: float = 0.0


# ============================================================
# CONTRACT DURATION / STATE
# ============================================================

var duration_months: int = 0
var remaining_duration_months: int = 0

var start_date: Dictionary = {}

var status: String = STATUS_DRAFT

# Step 11.1 — durable embargo state.
# The agreement remains the authoritative owner of whether this contract
# is currently embargoed. No parallel restriction registry is required.
var embargoed: bool = false

# Last lifecycle reason recorded by Step 4.7 / 11.1.
# It is intentionally descriptive state, not a diplomacy/conflict model.
var lifecycle_reason: String = ""


func _init(
	agreement_id: String = "",
	exporter: String = "",
	importer: String = "",
	resource: String = "",
	contracted_quantity: float = 0.0,
	contract_duration_months: int = 0
):

	id = agreement_id
	exporter_id = exporter
	importer_id = importer
	resource_id = resource
	quantity = contracted_quantity
	duration_months = max(
		contract_duration_months,
		0
	)
	remaining_duration_months = duration_months


# ============================================================
# VALIDATION
# ============================================================

func is_valid() -> bool:

	if id.is_empty():
		return false

	if exporter_id.is_empty():
		return false

	if importer_id.is_empty():
		return false

	if exporter_id == importer_id:
		return false

	if resource_id.is_empty():
		return false

	if quantity < 0.0:
		return false

	if duration_months < 0:
		return false

	if remaining_duration_months < 0:
		return false

	if not _is_valid_status(status):
		return false

	return true


func _is_valid_status(value: String) -> bool:

	return value in [
		STATUS_DRAFT,
		STATUS_ACTIVE,
		STATUS_INACTIVE,
		STATUS_EXPIRED,
		STATUS_CANCELLED,
		STATUS_INTERRUPTED
	]


# ============================================================
# LIFECYCLE STATE
# ============================================================

func activate(
	agreement_start_date: Dictionary = {}
) -> bool:

	if not is_valid():
		return false

	if status in [
		STATUS_EXPIRED,
		STATUS_CANCELLED
	]:
		return false

	status = STATUS_ACTIVE

	if not agreement_start_date.is_empty():
		start_date = agreement_start_date.duplicate(true)

	lifecycle_reason = ""
	return true


func set_inactive() -> void:

	if status == STATUS_EXPIRED:
		return

	if status == STATUS_CANCELLED:
		return

	status = STATUS_INACTIVE
	lifecycle_reason = CAUSE_MANUAL


# ============================================================
# STEP 4.7 — INTERRUPTION / CANCELLATION
# ============================================================

# Temporary interruption. It preserves remaining contract duration and
# can later be resumed explicitly.
func interrupt(
	reason: String = CAUSE_MANUAL
) -> bool:

	if status in [
		STATUS_EXPIRED,
		STATUS_CANCELLED
	]:
		return false

	if remaining_duration_months <= 0:
		expire()
		return false

	status = STATUS_INTERRUPTED
	lifecycle_reason = (
		reason
		if not reason.is_empty()
		else CAUSE_MANUAL
	)
	return true


# Resume a previously interrupted agreement. This does not reset its
# remaining duration or rewrite the original contract start date.
func resume() -> bool:

	if status != STATUS_INTERRUPTED:
		return false

	if remaining_duration_months <= 0:
		expire()
		return false

	status = STATUS_ACTIVE
	return true


# Terminal cancellation. A cancelled agreement cannot be resumed.
func cancel(
	reason: String = CAUSE_MANUAL
) -> bool:

	if status == STATUS_EXPIRED:
		return false

	if status == STATUS_CANCELLED:
		return false

	status = STATUS_CANCELLED
	lifecycle_reason = (
		reason
		if not reason.is_empty()
		else CAUSE_MANUAL
	)
	return true


func expire() -> void:

	remaining_duration_months = 0
	status = STATUS_EXPIRED
	lifecycle_reason = "contract_expiry"


# ============================================================
# STEP 11.1 — EMBARGO STATE
# ============================================================

# Apply or remove a temporary trade embargo on this agreement.
#
# The operation intentionally reuses the existing interruption lifecycle:
#   embargo ON  -> INTERRUPTED / embargo cause
#   embargo OFF -> explicit resume when the interruption was caused by embargo
#
# Contract duration is never reset or decremented by the embargo itself.
func set_embargoed(enabled: bool) -> bool:

	if enabled:

		if status in [
			STATUS_EXPIRED,
			STATUS_CANCELLED
		]:
			return false

		if embargoed:
			if status == STATUS_ACTIVE:
				return interrupt(CAUSE_EMBARGO)
			return true

		# Only an active contract may be newly embargoed. This prevents an
		# embargo action from overwriting an unrelated inactive/interrupted
		# lifecycle state.
		if status != STATUS_ACTIVE:
			return false

		if remaining_duration_months <= 0:
			return false

		embargoed = true

		var interrupted := interrupt(CAUSE_EMBARGO)

		if not interrupted:
			embargoed = false

		return interrupted

	# Explicit removal is the only path that resumes an embargoed contract.
	if not embargoed:
		return true

	embargoed = false

	if (
		status == STATUS_INTERRUPTED
		and lifecycle_reason == CAUSE_EMBARGO
	):
		var resumed := resume()

		if resumed:
			lifecycle_reason = ""

		return resumed

	return true


func is_embargoed() -> bool:

	return embargoed


# ============================================================
# DURATION STATE
# ============================================================

func set_remaining_duration(
	months: int
) -> void:

	remaining_duration_months = clamp(
		months,
		0,
		duration_months
	)

	if remaining_duration_months == 0 and status == STATUS_ACTIVE:
		expire()


func get_remaining_duration() -> int:

	return remaining_duration_months


func has_remaining_duration() -> bool:

	return remaining_duration_months > 0


func advance_one_month() -> bool:

	if status != STATUS_ACTIVE:
		return false

	if remaining_duration_months <= 0:
		expire()
		return true

	remaining_duration_months -= 1

	if remaining_duration_months <= 0:
		expire()
		return true

	return false


# ============================================================
# SNAPSHOT REPRESENTATION
# ============================================================

func to_snapshot_dict() -> Dictionary:

	return {
		"id": id,
		"exporter_id": exporter_id,
		"importer_id": importer_id,
		"resource_id": resource_id,
		"quantity": quantity,
		"duration_months": duration_months,
		"remaining_duration_months": remaining_duration_months,
		"start_date": start_date.duplicate(true),
		"status": status,
		"lifecycle_reason": lifecycle_reason,
		"embargoed": embargoed
	}
