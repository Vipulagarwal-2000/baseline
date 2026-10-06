class_name SimAction
extends RefCounted


# ============================================================
# COMMON EXECUTABLE ACTION CONTRACT — STEP 15.1
# ============================================================
#
# One action representation is shared by player and AI.
#
# Legacy fields are retained as the storage authority because the
# existing ActionManager / ActionSystem already consume them.
# The canonical Step 15 vocabulary is exposed through compatibility
# properties so later stages can use actor / kind / target / duration
# without creating a second action object.
#
# Step 15.1 intentionally defines the data contract only.
# Validation, reservation, execution, progress resolution, and
# world-state effects belong to later Step 15 substeps.
# ============================================================


# ------------------------------------------------------------
# State constants
# ------------------------------------------------------------

const STATE_QUEUED: String = "queued"
const STATE_ACTIVE: String = "active"
const STATE_COMPLETED: String = "completed"
const STATE_FAILED: String = "failed"
const STATE_CANCELLED: String = "cancelled"
const STATE_INTERRUPTED: String = "interrupted"


# ------------------------------------------------------------
# Existing execution fields — retained for compatibility
# ------------------------------------------------------------

var action_type: String = ""
var actor_id: String = ""
var target_id: String = ""
var value: float = 0.0
var duration_months: int = 1

# Original action duration used as the denominator for monthly progress.
# duration_months remains the legacy remaining-duration field used by the
# existing execution path.
var total_duration_months: int = 1

# Step 16.4 deterministic resolution priority. Higher values are
# processed before lower values. Equal-priority actions retain the
# deterministic admission order assigned by ActionManager.
var priority: int = 0


# ------------------------------------------------------------
# Step 15.1 executable-action contract fields
# ------------------------------------------------------------

# Resource / financial / capability / capacity requirements are
# deliberately represented as dictionaries. Their domain meaning
# remains owned by the authoritative domain systems introduced in
# later Step 15 validation work.
var cost: float = 0.0
var resource_requirements: Dictionary = {}
var financial_requirements: Dictionary = {}
var capability_requirements: Dictionary = {}
var capacity_requirements: Dictionary = {}

# Lifecycle state begins at queued because an action object is an
# executable action candidate before it becomes active.
var state: String = STATE_QUEUED

# The action contract stores a stable textual start date. Later
# execution stages may populate this from WorldState date data.
var start_date: String = ""

# Normalized progress representation: 0.0 = not started,
# 1.0 = complete. Step 15.1 defines the storage contract; later
# progress logic is responsible for changing the value.
var progress: float = 0.0

# Effect payload and terminal outcome are intentionally open
# dictionaries so later domain systems can consume authoritative
# effect/outcome data without creating a second action type.
var effects: Dictionary = {}
var failure_reason: String = ""
var completion_result: Dictionary = {}


# ------------------------------------------------------------
# Canonical Step 15 vocabulary — compatibility properties
# ------------------------------------------------------------

var actor: String:
	get:
		return actor_id
	set(value):
		actor_id = value


var kind: String:
	get:
		return action_type
	set(value):
		action_type = value


var target: String:
	get:
		return target_id
	set(value):
		target_id = value


var duration: int:
	get:
		return duration_months
	set(value):
		duration_months = value
		if state == STATE_QUEUED and progress <= 0.0:
			total_duration_months = value


# ------------------------------------------------------------
# Construction
# ------------------------------------------------------------

func _init(
	type: String = "",
	actor_value: String = "",
	target_value: String = "",
	action_value: float = 0.0,
	duration_value: int = 1
):
	# Preserve the original constructor contract used throughout the
	# current project.
	action_type = type
	actor_id = actor_value
	target_id = target_value
	value = action_value
	duration_months = duration_value
	total_duration_months = duration_value

	# Initialize fresh mutable containers for every action instance.
	resource_requirements = {}
	financial_requirements = {}
	capability_requirements = {}
	capacity_requirements = {}
	effects = {}
	completion_result = {}

	state = STATE_QUEUED
	start_date = ""
	progress = 0.0
	cost = 0.0
	failure_reason = ""
