extends SceneTree
const REQUIRED:=["World/Platforms","World/Enemies/TrainingEnemy01","World/Enemies/TrainingEnemy02","World/RespawnAnchors","World/RoomTriggers","Player/CollisionShape2D","Player/GroundShapeCast","Player/WallShapeCast","Player/CeilingShapeCast","Player/DashHitShapeCast","CameraRig/Camera2D","Systems/ContentLoader","Systems/InputAdapter","Systems/ArtifactSystem","Systems/ReplayRecorder","Systems/ReplayRunner","DebugUI/InputTrace"]
func _init()->void:call_deferred("_run")
func _run()->void:
	var failures:Array[String]=[];var packed:PackedScene=load("res://game/scenes/movement_sandbox.tscn")
	if packed==null:failures.append("scene load failed")
	else:
		var sandbox=packed.instantiate();root.add_child(sandbox);await process_frame
		for path in REQUIRED:
			if sandbox.get_node_or_null(path)==null:failures.append("%s missing"%path)
		if Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"),ProjectSettings.get_setting("display/window/size/viewport_height"))!=Vector2(390,844):failures.append("viewport not 390x844")
		sandbox.queue_free()
	print(JSON.stringify({"suite":"scene_smoke","ok":failures.is_empty(),"failures":failures}));quit(0 if failures.is_empty() else 1)
