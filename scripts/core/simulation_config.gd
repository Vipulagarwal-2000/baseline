class_name SimulationConfig
extends RefCounted


# ============================================================
# TIME
# ============================================================

var start_year: int = 1950

var start_month: int = 1

var start_day: int = 1

var maximum_year: int = 2100


# ============================================================
# SIMULATION
# ============================================================

var months_per_tick: int = 1


# ============================================================
# STEP 16.1 — CONCURRENT ACTION CAPACITY
# ============================================================
#
# Maximum number of queued/active actions that one actor may have
# concurrently admitted into the authoritative ActionManager.
#
# This is execution capacity, not a domain-resource capacity.
# Domain resources, budget, capability, and physical capacity remain
# owned by their existing authoritative systems.
var max_concurrent_actions_per_actor: int = 3


# ============================================================
# HISTORY
# ============================================================

# Historical baseline is used as the starting world state.
var historical_mode: bool = true


# ============================================================
# DEBUG
# ============================================================

var debug_mode: bool = true


# ============================================================
# FACTORY
# ============================================================

static func create_default() -> SimulationConfig:

	var config = SimulationConfig.new()

	return config
