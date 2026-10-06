class_name EventRepeatabilityPolicy
extends RefCounted


# ============================================================
# E11 — COOLDOWNS / REPEATABILITY POLICY
# ============================================================
#
# The policy is intentionally separate from EventDefinition.
# E11's exact event-data schema was deliberately left open by
# the framework specification.
#
# Modes:
#   one_time
#   repeatable
#   cooldown
#   minimum_interval
#
# Semantics:
#   one_time:
#       eligible once for an event/target key.
#
#   repeatable:
#       no repeatability restriction.
#
#   cooldown:
#       after firing at tick T, the next `cooldown_ticks`
#       subsequent ticks are blocked. Example:
#       T=0, cooldown=3 -> blocked at 1/2/3, eligible at 4.
#
#   minimum_interval:
#       consecutive firings must be separated by at least
#       `minimum_interval_ticks`. Example:
#       T=0, interval=3 -> blocked at 1/2, eligible at 3.
# ============================================================


const MODE_ONE_TIME: String = "one_time"
const MODE_REPEATABLE: String = "repeatable"
const MODE_COOLDOWN: String = "cooldown"
const MODE_MINIMUM_INTERVAL: String = "minimum_interval"

const SUPPORTED_MODES: Array[String] = [
	MODE_ONE_TIME,
	MODE_REPEATABLE,
	MODE_COOLDOWN,
	MODE_MINIMUM_INTERVAL,
]


var mode: String = MODE_REPEATABLE
var cooldown_ticks: int = 0
var minimum_interval_ticks: int = 0


func _init(
	policy_mode: String = MODE_REPEATABLE,
	policy_cooldown_ticks: int = 0,
	policy_minimum_interval_ticks: int = 0
) -> void:
	mode = policy_mode.strip_edges()
	cooldown_ticks = policy_cooldown_ticks
	minimum_interval_ticks = policy_minimum_interval_ticks


# ============================================================
# FACTORIES
# ============================================================

static func one_time() -> EventRepeatabilityPolicy:
	return EventRepeatabilityPolicy.new(
		MODE_ONE_TIME,
		0,
		0
	)


static func repeatable() -> EventRepeatabilityPolicy:
	return EventRepeatabilityPolicy.new(
		MODE_REPEATABLE,
		0,
		0
	)


static func cooldown(
	ticks: int
) -> EventRepeatabilityPolicy:
	return EventRepeatabilityPolicy.new(
		MODE_COOLDOWN,
		ticks,
		0
	)


static func minimum_interval(
	ticks: int
) -> EventRepeatabilityPolicy:
	return EventRepeatabilityPolicy.new(
		MODE_MINIMUM_INTERVAL,
		0,
		ticks
	)


# ============================================================
# VALIDATION
# ============================================================

static func is_supported_mode(
	policy_mode: String
) -> bool:
	return policy_mode in SUPPORTED_MODES


func is_valid() -> bool:
	if not EventRepeatabilityPolicy.is_supported_mode(mode):
		return false

	if cooldown_ticks < 0:
		return false

	if minimum_interval_ticks < 0:
		return false

	if mode == MODE_COOLDOWN:
		return cooldown_ticks > 0

	if mode == MODE_MINIMUM_INTERVAL:
		return minimum_interval_ticks > 0

	return true


func get_supported_modes() -> Array[String]:
	return [
		MODE_ONE_TIME,
		MODE_REPEATABLE,
		MODE_COOLDOWN,
		MODE_MINIMUM_INTERVAL,
	]
