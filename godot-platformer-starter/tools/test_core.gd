extends SceneTree
const Config=preload("res://game/core/movement/movement_config.gd")
const Validator=preload("res://game/core/content/content_validator.gd")
const InputTests=preload("res://tests/unit/input_intent_classifier_tests.gd")
const MovementTests=preload("res://tests/unit/movement_state_machine_tests.gd")
const CombatTests=preload("res://tests/unit/enemy_combat_state_tests.gd")
const ArtifactTests=preload("res://tests/unit/artifact_trigger_resolver_tests.gd")
func _init()->void:
	var failures:Array[String]=[]
	var movement:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://game/content/sandbox/movement.default.json"))
	var config=Config.from_dictionary(movement)
	failures.append_array(InputTests.new().run(config));failures.append_array(MovementTests.new().run(config));failures.append_array(CombatTests.new().run());failures.append_array(ArtifactTests.new().run())
	var validator:=Validator.new();var bad:Array[String]=validator.validate_artifacts({"schemaVersion":1,"contentVersion":"test","artifacts":[{"id":"bad","slot":"sideways","effects":[{"type":"line_damage","damage":-1}]}]})
	if not _contains(bad,"slot") or not _contains(bad,"trigger") or not _contains(bad,"damage"):failures.append("M0 content paths")
	_scan("res://game/core",failures);_finish("core",failures)
func _contains(errors:Array[String],needle:String)->bool:
	for error in errors:
		if needle in error:return true
	return false
func _scan(path:String,failures:Array[String])->void:
	var directory:=DirAccess.open(path)
	for file in directory.get_files():
		if not file.ends_with(".gd"):continue
		var file_path:="%s/%s"%[path,file];var source:=FileAccess.get_file_as_string(file_path)
		for forbidden in ["extends Node","extends SceneTree","Input.","FileAccess","DirAccess","PhysicsDirectSpaceState2D","res://game/runtime","res://game/presentation"]:
			if forbidden in source:failures.append("%s: forbidden '%s'"%[file_path,forbidden])
	for child in directory.get_directories():_scan("%s/%s"%[path,child],failures)
func _finish(suite:String,failures:Array[String])->void:print(JSON.stringify({"suite":suite,"ok":failures.is_empty(),"failures":failures}));quit(0 if failures.is_empty() else 1)
