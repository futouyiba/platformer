extends SceneTree

const Intent = preload("res://game/core/input/input_intent.gd")
const Packet = preload("res://game/core/combat/damage_packet.gd")
var _hits: Array[String] = []

func _init() -> void: call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var packed: PackedScene = load("res://game/scenes/movement_sandbox.tscn")
	if packed == null: failures.append("scene load failed")
	else:
		var sandbox = packed.instantiate()
		root.add_child(sandbox)
		await process_frame
		var player = sandbox.get_node("Player")
		for tick in 30:
			await physics_frame
			await process_frame
		if not player.has_safe_respawn(): failures.append("M3 safe respawn not recorded")
		else:
			var safe: Vector2 = player.safe_respawn_position()
			player.global_position += Vector2(0, 100)
			if not player.respawn_to_last_safe() or not player.global_position.is_equal_approx(safe): failures.append("M3 safe respawn restore")
		var one = sandbox.get_node("World/Enemies/TrainingEnemy01")
		var two = sandbox.get_node("World/Enemies/TrainingEnemy02")
		sandbox._on_dash(one, 900)
		if _zone_passed(sandbox.run_summary(), "A"): failures.append("M6 A single-target dash must remain pending")
		sandbox.reset_sandbox()
		await process_frame
		player.dash_target_crossed.connect(_on_hit)
		player.queue_intent(Intent.create(Intent.Kind.DASH_REQUEST, Vector2.RIGHT, 1, "test", 0))
		await physics_frame
		await process_frame
		for tick in 2:
			await physics_frame
			await process_frame
		if _hits.size() != 2: failures.append("M3 dash targets expected 2 got %d" % _hits.size())
		if not _zone_passed(sandbox.run_summary(), "A"): failures.append("M6 A requires both dash targets in one action")
		if one.current_health() != 2 or two.current_health() != 2: failures.append("M5 blade damage")
		var tags: Array[String] = ["test"]
		var packet = Packet.create("harness", tags, Vector2.RIGHT, 1, 2, .5, 99)
		var first = one.apply_damage(packet)
		var duplicate = one.apply_damage(packet)
		if not first.accepted or duplicate.accepted or one.current_health() != 1: failures.append("M4 damage duplicate")
		var system = sandbox.get_node("Systems/ArtifactSystem")
		player.global_position = two.global_position + Vector2(-64, 0)
		var wind = system.resolve_for_test({"type":"double_jump_started", "actionId":200})
		if not wind.triggered or two.current_health() != 1 or two.last_damage_result().knockback_velocity.y >= 0: failures.append("M5 wind")
		var ordinary = system.resolve_for_test({"type":"hard_landing", "actionId":201, "fallSpeed":8, "airTimeSeconds":.4})
		if ordinary.triggered: failures.append("M5 ordinary landing")
		var star = system.resolve_for_test({"type":"hard_landing", "actionId":202, "fallSpeed":14, "airTimeSeconds":.4})
		if not star.triggered or not two.is_dead(): failures.append("M5 starfall triggered=%s health=%d distance=%.2f" % [star.triggered, two.current_health(), two.global_position.distance_to(player.global_position)])
		_validate_wind_zone_target_requirement(sandbox, player, system, failures)
		_validate_zone_navigation(sandbox, player, failures)
		var summary: Dictionary = sandbox.run_summary()
		if summary["currentZone"] != "F": failures.append("M6 F-zone tracking")
		if summary["zones"].size() != 6: failures.append("M6 six-zone review summary")
		if not sandbox.get_node("DebugUI/ReviewPanel").visible: failures.append("M6 F-zone review panel")
		for tick in 30:
			await physics_frame
			await process_frame
		if player.safe_respawn_position().x < 1950: failures.append("M6 F safe-respawn precondition")
		sandbox.reset_sandbox()
		await process_frame
		if sandbox.current_zone_id() != "A": failures.append("M6 deterministic reset zone")
		if not player.global_position.is_equal_approx(Vector2(195, 720)): failures.append("M6 deterministic reset position")
		if one.current_health() != 3 or two.current_health() != 3: failures.append("M6 deterministic enemy reset")
		if sandbox.get_node("DebugUI/ReviewPanel").visible: failures.append("M6 review panel reset")
		if not player.respawn_to_last_safe() or not player.global_position.is_equal_approx(Vector2(195, 720)): failures.append("M6 reset must reseed safe respawn at A")
		sandbox.queue_free()
	print(JSON.stringify({"suite":"integration", "ok":failures.is_empty(), "failures":failures}))
	quit(0 if failures.is_empty() else 1)

func _on_hit(target, action_id: int) -> void: _hits.append("%s:%d" % [target.instance_key, action_id])

func _zone_passed(summary: Dictionary, zone_id: String) -> bool:
	for zone in summary["zones"]:
		if zone["id"] == zone_id: return zone["passed"]
	return false

func _validate_wind_zone_target_requirement(sandbox: Node, player: CharacterBody2D, system: Node, failures: Array[String]) -> void:
	var tracker: Node = sandbox.get_node("Systems/ZoneTracker")
	var target = sandbox.get_node("World/Enemies/WindTargetC")
	var health_before: int = target.current_health()
	player.global_position = target.global_position + Vector2(-215, 0)
	tracker.force_position_check()
	var far_wind = system.resolve_for_test({"type":"double_jump_started", "actionId":300})
	var far_event: Dictionary = sandbox.event_log().back()
	if not far_wind.triggered: failures.append("M6 C far Wind Ring should resolve")
	if target.current_health() != health_before or not far_event.get("affectedTargets", []).is_empty(): failures.append("M6 C far Wind Ring precondition")
	if _zone_passed(sandbox.run_summary(), "C"): failures.append("M6 C no-target Wind Ring must remain pending")
	player.global_position = target.global_position + Vector2(-64, 0)
	tracker.force_position_check()
	var near_wind = system.resolve_for_test({"type":"double_jump_started", "actionId":301})
	if not near_wind.triggered or target.current_health() != health_before - 1: failures.append("M6 C near Wind Ring target effect")
	if not _zone_passed(sandbox.run_summary(), "C"): failures.append("M6 C affected target should complete Wind Ring")

func _validate_zone_navigation(sandbox: Node, player: CharacterBody2D, failures: Array[String]) -> void:
	var tracker: Node = sandbox.get_node("Systems/ZoneTracker")
	var camera: Node2D = sandbox.get_node("CameraRig")
	var prompt: Label = sandbox.get_node("DebugUI/ZonePrompt")
	var viewport_width := float(ProjectSettings.get_setting("display/window/size/viewport_width"))
	var layout: Dictionary = sandbox.layout_content()
	var world_width := float(layout["worldBounds"]["width"])
	for zone in layout["zones"]:
		var bounds: Dictionary = zone["bounds"]
		var center_x := float(bounds["x"]) + float(bounds["width"]) * 0.5
		player.global_position = Vector2(center_x, 720)
		tracker.force_position_check()
		camera.snap_to_target()
		if sandbox.current_zone_id() != zone["id"]: failures.append("M6 zone %s tracking" % zone["id"])
		if prompt.text != zone["prompt"]: failures.append("M6 zone %s prompt" % zone["id"])
		var expected_x := clampf(center_x, viewport_width * 0.5, world_width - viewport_width * 0.5)
		if not is_equal_approx(camera.global_position.x, expected_x): failures.append("M6 zone %s camera" % zone["id"])
