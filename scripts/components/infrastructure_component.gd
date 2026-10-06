class_name InfrastructureComponent
extends SimComponent


const INFRASTRUCTURE_TYPES := [
	"transport",
	"railways",
	"roads",
	"ports",
	"power",
	"industrial",
	"storage"
]


func _init(owner: String = ""):
	super("infrastructure", owner)

	state = {
		"transport": 0.0,
		"railways": 0.0,
		"roads": 0.0,
		"ports": 0.0,
		"power": 0.0,
		"industrial": 0.0,
		"storage": 0.0,
		"total_capacity": 0.0,
		# Named process-specific infrastructure capacity. This is distinct from
		# the seven normalized country infrastructure dimensions above. It is
		# the authoritative capacity store for process infrastructure usage
		# keys such as "modern_steelworks". A missing key remains unresolved
		# and may fall back to the legacy ResourceComponent bridge.
		"process_infrastructure_capacity": {},
		# Step 14.1 — authoritative damage ledger. Damage is recorded
		# separately from raw infrastructure capacity. Step 14.2 will
		# translate this ledger into effective-capacity reduction.
		"infrastructure_damage": {
			"transport": 0.0,
			"railways": 0.0,
			"roads": 0.0,
			"ports": 0.0,
			"power": 0.0,
			"industrial": 0.0,
			"storage": 0.0
		},
		"infrastructure_damage_total": 0.0,
		"infrastructure_damage_records": [],
		"last_damage_source": {},
		# Step 14.2 — derived effective capacity after maintenance condition
		# and infrastructure damage are applied. Raw infrastructure values
		# remain authoritative and are never overwritten by damage.
		"effective_infrastructure_capacity": {
			"transport": 0.0,
			"railways": 0.0,
			"roads": 0.0,
			"ports": 0.0,
			"power": 0.0,
			"industrial": 0.0,
			"storage": 0.0
		}
	}
