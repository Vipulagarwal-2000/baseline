class_name Country
extends SimEntity


# ============================================================
# COUNTRY IDENTITY
# ============================================================

var country_code: String = ""


# ============================================================
# INITIALIZATION
# ============================================================

func _init(
	entity_id: String,
	country_name: String,
	code: String
):
	super(
		entity_id,
		country_name,
		"country"
	)

	country_code = code
