class_name SandboxContentLoader
extends Node

const MovementConfigScript = preload("res://game/core/movement/movement_config.gd")
const ValidatorScript = preload("res://game/core/content/content_validator.gd")
const PATHS := {
	"movement":"res://game/content/sandbox/movement.default.json",
	"artifacts":"res://game/content/sandbox/artifacts.sandbox.json",
	"enemies":"res://game/content/sandbox/enemy.sandbox.json",
	"collisionLayers":"res://game/content/sandbox/collision_layers.json"
}
var loaded_content: Dictionary = {}

func load_and_validate_all() -> Dictionary:
	var errors: Array[String] = []
	for key in PATHS: loaded_content[key] = _read_json(PATHS[key], errors)
	if errors.is_empty():
		var validator := ValidatorScript.new()
		errors.append_array(validator.validate_movement(loaded_content["movement"]))
		errors.append_array(validator.validate_artifacts(loaded_content["artifacts"]))
		errors.append_array(validator.validate_enemy(loaded_content["enemies"]))
		errors.append_array(validator.validate_collision_layers(loaded_content["collisionLayers"]))
	return {"ok":errors.is_empty(), "errors":errors, "content":loaded_content}

func movement_config():
	if not loaded_content.has("movement"):
		var result: Dictionary = load_and_validate_all()
		if not result["ok"]: return null
	return MovementConfigScript.from_dictionary(loaded_content["movement"])

func _read_json(path: String, errors: Array[String]) -> Variant:
	if not FileAccess.file_exists(path): errors.append("%s: file not found" % path); return {}
	var json := JSON.new()
	var error := json.parse(FileAccess.get_file_as_string(path))
	if error != OK: errors.append("%s:%d: %s" % [path, json.get_error_line(), json.get_error_message()]); return {}
	return json.data
