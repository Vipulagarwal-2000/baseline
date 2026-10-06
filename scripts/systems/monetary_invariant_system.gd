class_name MonetaryInvariantSystem
extends SimulationSystem


const STATUS_PASS := "pass"
const STATUS_FAIL := "fail"
const STATUS_SKIPPED := "skipped"

const EPSILON := 0.0000001


func _init() -> void:
	super("monetary_invariant_system")


func process_month(world: WorldState) -> void:
	if world == null:
		push_error("MonetaryInvariantSystem: World is null.")
		return

	var transaction_ids: Array = world.trade_transactions.keys()
	transaction_ids.sort()

	for transaction_id in transaction_ids:
		var transaction = world.get_trade_transaction(transaction_id)

		if transaction == null:
			continue

		if not transaction is TradeTransaction:
			continue

		if not _is_current_month_transaction(world, transaction):
			continue

		if transaction.monetary_invariants_checked:
			continue

		_evaluate_transaction(world, transaction)


func _evaluate_transaction(
	world: WorldState,
	transaction: TradeTransaction
) -> void:
	# Invariants apply to completed settlements. Unsettled transactions are
	# handled by affordability / FX failure logic and are intentionally
	# skipped here.
	if not transaction.payment_settled:
		_mark_skipped(
			transaction,
			"settlement_not_completed"
		)
		return

	var exporter = world.get_entity(transaction.exporter_id)
	var importer = world.get_entity(transaction.importer_id)

	if exporter == null or importer == null:
		_mark_fail(
			transaction,
			"missing_counterparty"
		)
		return

	var importer_economy = importer.get_component("economy")
	var exporter_economy = exporter.get_component("economy")

	if importer_economy == null or exporter_economy == null:
		_mark_fail(
			transaction,
			"missing_economy_component"
		)
		return

	var ledger: Dictionary = transaction.settlement_ledger

	if ledger.is_empty():
		_mark_fail(
			transaction,
			"missing_settlement_ledger"
		)
		return

	var errors: Array = []

	var importer_before := float(
		ledger.get("importer_treasury_before", NAN)
	)
	var importer_after := float(
		ledger.get("importer_treasury_after", NAN)
	)
	var exporter_before := float(
		ledger.get("exporter_treasury_before", NAN)
	)
	var exporter_after := float(
		ledger.get("exporter_treasury_after", NAN)
	)

	if is_nan(importer_before) or is_nan(importer_after):
		errors.append("invalid_importer_treasury_ledger")

	if is_nan(exporter_before) or is_nan(exporter_after):
		errors.append("invalid_exporter_treasury_ledger")

	if not errors.is_empty():
		_mark_fail(
			transaction,
			"invalid_treasury_ledger",
			errors
		)
		return

	var current_importer_treasury := float(
		importer_economy.get_state("treasury", 0.0)
	)
	var current_exporter_treasury := float(
		exporter_economy.get_state("treasury", 0.0)
	)

	# Settlement is authoritative for the exact transaction mutation; the
	# invariant layer verifies that live state still matches that record.
	if not is_equal_approx(
		current_importer_treasury,
		importer_after
	):
		errors.append(
			"importer_treasury_does_not_match_settlement_ledger"
		)

	if not is_equal_approx(
		current_exporter_treasury,
		exporter_after
	):
		errors.append(
			"exporter_treasury_does_not_match_settlement_ledger"
		)

	var payer_delta := importer_before - importer_after
	var receiver_delta := exporter_after - exporter_before

	# The legacy 5.11/6.3 direct-test path intentionally has no FX state.
	if transaction.conversion_status == "pending":
		_mark_skipped(
			transaction,
			"legacy_nominal_settlement_path"
		)
		return

	var expected_payer_payment := maxf(
		float(transaction.payer_payment_amount),
		0.0
	)
	var expected_receiver_payment := maxf(
		float(transaction.receiver_payment_amount),
		0.0
	)

	if transaction.valuation_status == "zero_delivery":
		if absf(payer_delta) > EPSILON:
			errors.append("zero_delivery_created_payer_delta")

		if absf(receiver_delta) > EPSILON:
			errors.append("zero_delivery_created_receiver_delta")

		if absf(expected_payer_payment) > EPSILON:
			errors.append("zero_delivery_has_payer_payment")

		if absf(expected_receiver_payment) > EPSILON:
			errors.append("zero_delivery_has_receiver_payment")
	else:
		if not is_equal_approx(
			payer_delta,
			expected_payer_payment
		):
			errors.append(
				"payer_debit_does_not_equal_payment_amount"
			)

		if not is_equal_approx(
			receiver_delta,
			expected_receiver_payment
		):
			errors.append(
				"receiver_credit_does_not_equal_payment_amount"
			)

		if not is_equal_approx(
			transaction.trade_payment,
			expected_receiver_payment
		):
			errors.append(
				"trade_payment_does_not_match_receiver_payment"
			)

		if not is_equal_approx(
			transaction.transaction_cost,
			expected_payer_payment
		):
			errors.append(
				"transaction_cost_does_not_match_payer_payment"
			)

		if transaction.conversion_status == "converted":
			var fx_rate := float(transaction.fx_rate)

			if fx_rate <= 0.0:
				errors.append(
					"converted_transaction_has_non_positive_fx_rate"
				)
			else:
				# fx_rate is target/payer-currency units per one
				# source/receiver-currency unit. Therefore:
				# payer amount = receiver amount × fx_rate.
				if not is_equal_approx(
					expected_receiver_payment * fx_rate,
					expected_payer_payment
				):
					errors.append(
						"fx_conversion_value_mismatch"
					)

				var conversion_ledger: Dictionary = (
					transaction.conversion_ledger
				)
				var source_rate_to_base := float(
					conversion_ledger.get(
						"source_rate_to_base",
						0.0
					)
				)
				var target_rate_to_base := float(
					conversion_ledger.get(
						"target_rate_to_base",
						0.0
					)
				)

				if source_rate_to_base <= 0.0:
					errors.append("missing_source_base_rate")

				if target_rate_to_base <= 0.0:
					errors.append("missing_target_base_rate")

				if (
					source_rate_to_base > 0.0
					and target_rate_to_base > 0.0
				):
					var payer_base_value := (
						expected_payer_payment
						/ target_rate_to_base
					)
					var receiver_base_value := (
						expected_receiver_payment
						/ source_rate_to_base
					)

					if not is_equal_approx(
						payer_base_value,
						receiver_base_value
					):
						errors.append(
							"base_equivalent_value_not_conserved"
						)

		elif transaction.conversion_status == "same_currency":
			if not is_equal_approx(
				expected_payer_payment,
				expected_receiver_payment
			):
				errors.append(
					"same_currency_payment_mismatch"
				)

			if transaction.fx_applied:
				errors.append(
					"same_currency_transaction_applied_fx"
				)

			if not is_equal_approx(
				transaction.fx_rate,
				1.0
			):
				errors.append(
					"same_currency_fx_rate_not_one"
				)

		else:
			errors.append(
				"settled_transaction_has_invalid_conversion_status"
			)

		if (
			transaction.settlement_currency_id
			!= transaction.valuation_currency_id
		):
			errors.append(
				"settlement_currency_does_not_match_valuation_currency"
			)

		if (
			transaction.payer_currency_id
			!= str(
				importer_economy.get_state(
					"currency_id",
					""
				)
			)
		):
			errors.append(
				"payer_currency_identity_mismatch"
			)

		if (
			transaction.receiver_currency_id
			!= str(
				exporter_economy.get_state(
					"currency_id",
					""
				)
			)
		):
			errors.append(
				"receiver_currency_identity_mismatch"
			)

	if errors.is_empty():
		_mark_pass(
			transaction,
			{
				"settled": true,
				"settlement_currency_id": (
					transaction.settlement_currency_id
				),
				"payer_currency_id": (
					transaction.payer_currency_id
				),
				"receiver_currency_id": (
					transaction.receiver_currency_id
				),
				"payer_debit": payer_delta,
				"receiver_credit": receiver_delta,
				"payer_payment_amount": (
					expected_payer_payment
				),
				"receiver_payment_amount": (
					expected_receiver_payment
				),
				"conversion_status": (
					transaction.conversion_status
				),
				"fx_applied": transaction.fx_applied,
				"fx_rate": transaction.fx_rate
			}
		)
	else:
		_mark_fail(
			transaction,
			"monetary_invariant_violation",
			errors
		)


func _mark_pass(
	transaction: TradeTransaction,
	metadata: Dictionary
) -> void:
	transaction.monetary_invariants_checked = true
	transaction.monetary_invariants_passed = true
	transaction.monetary_invariant_status = STATUS_PASS
	transaction.monetary_invariant_errors = []
	transaction.monetary_invariant_ledger = metadata.duplicate(true)


func _mark_skipped(
	transaction: TradeTransaction,
	reason: String
) -> void:
	transaction.monetary_invariants_checked = true
	transaction.monetary_invariants_passed = true
	transaction.monetary_invariant_status = STATUS_SKIPPED
	transaction.monetary_invariant_errors = []
	transaction.monetary_invariant_ledger = {
		"checked": false,
		"status": STATUS_SKIPPED,
		"reason": reason
	}


func _mark_fail(
	transaction: TradeTransaction,
	reason: String,
	errors: Array = []
) -> void:
	transaction.monetary_invariants_checked = true
	transaction.monetary_invariants_passed = false
	transaction.monetary_invariant_status = STATUS_FAIL

	var combined_errors: Array = []
	combined_errors.append(reason)

	for error_value in errors:
		if str(error_value) not in combined_errors:
			combined_errors.append(str(error_value))

	transaction.monetary_invariant_errors = combined_errors
	transaction.monetary_invariant_ledger = {
		"checked": true,
		"status": STATUS_FAIL,
		"reason": reason,
		"errors": combined_errors.duplicate(true)
	}


func _is_current_month_transaction(
	world: WorldState,
	transaction: TradeTransaction
) -> bool:
	return (
		int(world.current_date.get("year", 0))
		== int(transaction.execution_date.get("year", -1))
		and
		int(world.current_date.get("month", 0))
		== int(transaction.execution_date.get("month", -1))
	)
