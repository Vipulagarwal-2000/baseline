class_name ReferentialIntegrityAuditTest
extends RefCounted


static func run() -> bool:
	var auditor := ReferentialIntegrityAuditor.new()

	if not auditor.is_ready():
		TestLogger.write_line(
			"Referential integrity auditor ready: FAIL"
		)
		return false

	TestLogger.write_line(
		"Referential integrity auditor ready: PASS"
	)

	var passed := auditor.run()

	var errors := auditor.get_errors()

	if errors.is_empty():
		TestLogger.write_line(
			"All declared cross-domain references resolve: PASS | checked="
			+ str(
				auditor.get_checked_reference_count()
			)
		)
	else:
		TestLogger.write_line(
			"All declared cross-domain references resolve: FAIL | "
			+ ", ".join(errors)
		)

	TestLogger.write_line(
		"ReferentialIntegrityAuditTest: "
		+ (
			"PASS"
			if passed
			else "FAIL"
		)
	)

	return passed
