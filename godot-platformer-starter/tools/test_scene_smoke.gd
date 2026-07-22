extends SceneTree

const REQUIRED := [
	"World/ZoneBackdrops", "World/Platforms", "World/Enemies", "World/RespawnAnchors", "World/RoomTriggers",
	"Player/CollisionShape2D", "Player/GroundShapeCast", "Player/WallShapeCast", "Player/CeilingShapeCast", "Player/DashHitShapeCast",
	"CameraRig/Camera2D", "Systems/ContentLoader", "Systems/InputAdapter", "Systems/ArtifactSystem", "Systems/ZoneTracker",
	"Systems/ReplayRecorder", "Systems/ReplayRunner", "DebugUI/InputTrace", "DebugUI/ZonePrompt", "DebugUI/ReviewPanel/ResetButton"
]

func _init() -> void: call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var packed: PackedScene = load("res://game/scenes/movement_sandbox.tscn")
	if packed == null: failures.append("scene load failed")
	else:
		var sandbox = packed.instantiate()
		root.add_child(sandbox)
		await process_frame
		for path in REQUIRED:
			if sandbox.get_node_or_null(path) == null: failures.append("%s missing" % path)
		var layout: Dictionary = sandbox.layout_content()
		if layout.get("zones", []).size() != 6: failures.append("M6 expected six layout zones")
		if sandbox.get_node("World/RoomTriggers").get_child_count() != 6: failures.append("M6 expected six room triggers")
		if sandbox.get_node("World/RespawnAnchors").get_child_count() != 6: failures.append("M6 expected six respawn anchors")
		if sandbox.get_node("World/ZoneBackdrops").get_child_count() != 12: failures.append("M6 expected six backdrops and six headings")
		var expected_platforms := 0
		var expected_enemies := 0
		for zone in layout.get("zones", []):
			expected_platforms += zone["platforms"].size()
			expected_enemies += zone["enemies"].size()
			var trigger = sandbox.get_node_or_null("World/RoomTriggers/Zone%s" % zone["id"])
			if trigger == null: failures.append("M6 zone %s trigger binding" % zone["id"])
			elif trigger.get_meta("primary_action", "") != zone["primaryAction"]: failures.append("M6 zone %s primary-action binding" % zone["id"])
		if sandbox.get_node("World/Platforms").get_child_count() != expected_platforms: failures.append("M6 platform binding count")
		if sandbox.get_node("World/Enemies").get_child_count() != expected_enemies: failures.append("M6 enemy binding count")
		if sandbox.get_node("DebugUI/ZonePrompt").text != layout["zones"][0]["prompt"]: failures.append("M6 initial zone prompt")
		if sandbox.get_node("DebugUI/ReviewPanel").visible: failures.append("M6 review panel should start hidden")
		var camera_bounds: Rect2 = sandbox.get_node("CameraRig").world_bounds()
		if camera_bounds.size != Vector2(2340, 844): failures.append("M6 camera world bounds")
		if Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height")) != Vector2(390, 844): failures.append("viewport not 390x844")
		sandbox.queue_free()
	print(JSON.stringify({"suite":"scene_smoke", "ok":failures.is_empty(), "failures":failures}))
	quit(0 if failures.is_empty() else 1)
