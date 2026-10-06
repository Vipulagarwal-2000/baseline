class_name EventRandomness
extends RefCounted


# ============================================================
# E10 — DETERMINISTIC RANDOMNESS
# ============================================================
#
# Two bounded deterministic interfaces:
#
# 1. Seeded sequence:
#       same seed -> same sequence
#
# 2. Event-scoped roll:
#       same seed
#       + same event id
#       + same world signature
#       -> same result
#
# The world signature is supplied by the caller. E10 does not
# inspect or serialize WorldState and therefore does not become
# a second world-state authority.
#
# E10 intentionally does NOT:
# - change WorldState
# - execute effects
# - select choices
# - start cooldowns
# - integrate with monthly simulation
# ============================================================


const DEFAULT_SEED: int = 0

var seed: int = DEFAULT_SEED
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(
	initial_seed: int = DEFAULT_SEED
) -> void:
	set_seed(initial_seed)


# ============================================================
# SEEDED SEQUENCE
# ============================================================

func set_seed(
	new_seed: int
) -> void:
	seed = new_seed
	_rng.seed = new_seed


func reset() -> void:
	_rng.seed = seed


func next_float() -> float:
	return _rng.randf()


func next_int(
	minimum_value: int,
	maximum_value: int
) -> int:
	if maximum_value < minimum_value:
		return minimum_value

	return _rng.randi_range(
		minimum_value,
		maximum_value
	)


func sequence(
	count: int
) -> Array[float]:
	var values: Array[float] = []

	if count <= 0:
		return values

	for _index in range(count):
		values.append(next_float())

	return values


# ============================================================
# EVENT-SCOPED DETERMINISTIC ROLL
# ============================================================

func roll_for_event(
	event_id: String,
	world_signature: String
) -> float:
	return EventRandomness.roll_from_context(
		seed,
		event_id,
		world_signature
	)


static func roll_from_context(
	base_seed: int,
	event_id: String,
	world_signature: String
) -> float:

	var normalized_event_id: String = (
		event_id.strip_edges()
	)

	var normalized_world_signature: String = (
		world_signature.strip_edges()
	)

	var context: String = (
		str(base_seed)
		+ "|"
		+ normalized_event_id
		+ "|"
		+ normalized_world_signature
	)

	var derived_seed: int = _stable_hash(context)

	# Avoid an unnecessary zero seed while preserving determinism.
	if derived_seed == 0:
		derived_seed = 1

	var context_rng: RandomNumberGenerator = (
		RandomNumberGenerator.new()
	)

	context_rng.seed = derived_seed

	return context_rng.randf()


# ============================================================
# STABLE HASH
# ============================================================

static func _stable_hash(
	value: String
) -> int:

	# FNV-1a style 32-bit deterministic hash.
	# This avoids relying on an engine/runtime-specific hash
	# implementation for the event-scoped seed derivation.
	var hash_value: int = 2166136261

	for byte_value in value.to_utf8_buffer():
		hash_value = hash_value ^ int(byte_value)
		hash_value = (
			hash_value * 16777619
		) & 0x7fffffff

	return hash_value
