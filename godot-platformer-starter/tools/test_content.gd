extends SceneTree

const Loader = preload("res://game/runtime/content/content_loader.gd")
const Validator = preload("res://game/core/content/content_validator.gd")

func _init() -> void:
	var failures: Array[String] = []
	var loader := Loader.new()
	var result: Dictionary = loader.load_and_validate_all()
	if not result["ok"]: failures.append_array(result["errors"])
	else: _validate_layout_rejections(result["content"], failures)
	loader.free()
	print(JSON.stringify({"suite":"content", "ok":failures.is_empty(), "failures":failures}))
	quit(0 if failures.is_empty() else 1)

func _validate_layout_rejections(content: Dictionary, failures: Array[String]) -> void:
	var validator := Validator.new()
	var missing_zone: Dictionary = content["layout"].duplicate(true)
	missing_zone["zones"].pop_back()
	_assert_contains(
		validator.validate_layout(missing_zone, content["enemies"]),
		"expected exactly six zones",
		"M6 missing-zone layout rejection",
		failures
	)

	var duplicate_zone: Dictionary = content["layout"].duplicate(true)
	duplicate_zone["zones"][1]["id"] = "A"
	_assert_contains(
		validator.validate_layout(duplicate_zone, content["enemies"]),
		"duplicate zone",
		"M6 duplicate-zone layout rejection",
		failures
	)

	var unknown_enemy: Dictionary = content["layout"].duplicate(true)
	unknown_enemy["zones"][0]["enemies"][0]["contentId"] = "unknown_enemy"
	_assert_contains(
		validator.validate_layout(unknown_enemy, content["enemies"]),
		"unknown enemy definition",
		"M6 unknown-enemy layout rejection",
		failures
	)

func _assert_contains(errors: Array[String], expected: String, message: String, failures: Array[String]) -> void:
	for error in errors:
		if expected in error: return
	failures.append(message)
