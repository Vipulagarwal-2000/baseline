class_name ProductionProcessRequirementEvaluatorTest
extends RefCounted


static func run() -> bool:

	print("")
	print("================================")
	print("PRODUCTION PROCESS REQUIREMENT EVALUATOR TEST")
	print("================================")

	var all_passed := true


	# --------------------------------------------------
	# 1. Empty requirements
	# --------------------------------------------------

	var empty_requirements := ProductionProcessRequirementEvaluator.requirements_met(
		{},
		{}
	)

	var empty_pass := empty_requirements == true

	print(
		"Empty requirements: ",
		"PASS" if empty_pass else "FAIL"
	)

	all_passed = all_passed and empty_pass


	# --------------------------------------------------
	# 2. Numeric requirement satisfied
	# --------------------------------------------------

	var numeric_pass := ProductionProcessRequirementEvaluator.requirements_met(
		{
			"advanced_metallurgy": 0.5
		},
		{
			"advanced_metallurgy": 0.7
		}
	)

	print(
		"Numeric requirement satisfied: ",
		"PASS" if numeric_pass else "FAIL"
	)

	all_passed = all_passed and numeric_pass


	# --------------------------------------------------
	# 3. Numeric requirement exactly satisfied
	# --------------------------------------------------

	var numeric_exact := ProductionProcessRequirementEvaluator.requirements_met(
		{
			"advanced_metallurgy": 0.5
		},
		{
			"advanced_metallurgy": 0.5
		}
	)

	print(
		"Numeric requirement exact threshold: ",
		"PASS" if numeric_exact else "FAIL"
	)

	all_passed = all_passed and numeric_exact


	# --------------------------------------------------
	# 4. Numeric requirement insufficient
	# --------------------------------------------------

	var numeric_fail := ProductionProcessRequirementEvaluator.requirements_met(
		{
			"advanced_metallurgy": 0.5
		},
		{
			"advanced_metallurgy": 0.4
		}
	)

	var numeric_fail_result := numeric_fail == false

	print(
		"Numeric requirement insufficient: ",
		"PASS" if numeric_fail_result else "FAIL"
	)

	all_passed = all_passed and numeric_fail_result


	# --------------------------------------------------
	# 5. Missing requirement
	# --------------------------------------------------

	var missing_requirement := ProductionProcessRequirementEvaluator.requirements_met(
		{
			"advanced_metallurgy": 0.5
		},
		{}
	)

	var missing_pass := missing_requirement == false

	print(
		"Missing requirement fails safely: ",
		"PASS" if missing_pass else "FAIL"
	)

	all_passed = all_passed and missing_pass


	# --------------------------------------------------
	# 6. Boolean requirement satisfied
	# --------------------------------------------------

	var boolean_pass := ProductionProcessRequirementEvaluator.requirements_met(
		{
			"modern_steelworks": true
		},
		{
			"modern_steelworks": true
		}
	)

	print(
		"Boolean requirement satisfied: ",
		"PASS" if boolean_pass else "FAIL"
	)

	all_passed = all_passed and boolean_pass


	# --------------------------------------------------
	# 7. Boolean requirement failed
	# --------------------------------------------------

	var boolean_fail := ProductionProcessRequirementEvaluator.requirements_met(
		{
			"modern_steelworks": true
		},
		{
			"modern_steelworks": false
		}
	)

	var boolean_fail_result := boolean_fail == false

	print(
		"Boolean requirement failed: ",
		"PASS" if boolean_fail_result else "FAIL"
	)

	all_passed = all_passed and boolean_fail_result


	# --------------------------------------------------
	# 8. String requirement
	# --------------------------------------------------

	var string_pass := ProductionProcessRequirementEvaluator.requirements_met(
		{
			"industrial_system": "modern"
		},
		{
			"industrial_system": "modern"
		}
	)

	print(
		"String requirement satisfied: ",
		"PASS" if string_pass else "FAIL"
	)

	all_passed = all_passed and string_pass


	# --------------------------------------------------
	# 9. String requirement mismatch
	# --------------------------------------------------

	var string_fail := ProductionProcessRequirementEvaluator.requirements_met(
		{
			"industrial_system": "modern"
		},
		{
			"industrial_system": "basic"
		}
	)

	var string_fail_result := string_fail == false

	print(
		"String requirement mismatch: ",
		"PASS" if string_fail_result else "FAIL"
	)

	all_passed = all_passed and string_fail_result


	# --------------------------------------------------
	# 10. Multiple requirements
	# --------------------------------------------------

	var multiple_pass := ProductionProcessRequirementEvaluator.requirements_met(
		{
			"advanced_metallurgy": 0.5,
			"modern_steelworks": true
		},
		{
			"advanced_metallurgy": 0.8,
			"modern_steelworks": true
		}
	)

	print(
		"Multiple requirements satisfied: ",
		"PASS" if multiple_pass else "FAIL"
	)

	all_passed = all_passed and multiple_pass


	# --------------------------------------------------
	# 11. Multiple requirements with one failure
	# --------------------------------------------------

	var multiple_fail := ProductionProcessRequirementEvaluator.requirements_met(
		{
			"advanced_metallurgy": 0.5,
			"modern_steelworks": true
		},
		{
			"advanced_metallurgy": 0.8,
			"modern_steelworks": false
		}
	)

	var multiple_fail_result := multiple_fail == false

	print(
		"Multiple requirements with one failure: ",
		"PASS" if multiple_fail_result else "FAIL"
	)

	all_passed = all_passed and multiple_fail_result


	# --------------------------------------------------
	# 12. Failed requirement reporting
	# --------------------------------------------------

	var failed_requirements := (
		ProductionProcessRequirementEvaluator.get_failed_requirements(
			{
				"advanced_metallurgy": 0.5,
				"modern_steelworks": true
			},
			{
				"advanced_metallurgy": 0.3,
				"modern_steelworks": false
			}
		)
	)

	var failed_reporting_pass := (
		failed_requirements.size() == 2
		and failed_requirements.has(
			"advanced_metallurgy"
		)
		and failed_requirements.has(
			"modern_steelworks"
		)
	)

	print(
		"Failed requirement reporting: ",
		"PASS" if failed_reporting_pass else "FAIL"
	)

	all_passed = all_passed and failed_reporting_pass


	# --------------------------------------------------
	# Final result
	# --------------------------------------------------

	print("")
	print(
		"ProductionProcessRequirementEvaluatorTest: ",
		"PASS" if all_passed else "FAIL"
	)

	print("================================")
	print("")

	return all_passed
