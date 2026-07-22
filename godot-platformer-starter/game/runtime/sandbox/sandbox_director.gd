class_name SandboxDirector
extends Node2D

const LayoutBuilder = preload("res://game/runtime/sandbox/sandbox_layout_builder.gd")

@onready var player: CharacterBody2D = $Player
@onready var loader: Node = $Systems/ContentLoader
@onready var input_adapter: Node = $Systems/InputAdapter
@onready var artifacts: Node = $Systems/ArtifactSystem
@onready var zone_tracker: Node = $Systems/ZoneTracker
@onready var camera_rig: Node2D = $CameraRig
@onready var status: Label = $DebugUI/Panel/Status
@onready var intent_label: Label = $DebugUI/Panel/Intent
@onready var movement_label: Label = $DebugUI/Panel/Movement
@onready var event_label: Label = $DebugUI/Panel/Event
@onready var zone_prompt: Label = $DebugUI/ZonePrompt
@onready var review_panel: Control = $DebugUI/ReviewPanel
@onready var review_summary: Label = $DebugUI/ReviewPanel/Summary
@onready var reset_button: Button = $DebugUI/ReviewPanel/ResetButton
@onready var trace: Control = $DebugUI/InputTrace

var _builder := LayoutBuilder.new()
var _content: Dictionary = {}
var _layout: Dictionary = {}
var _enemy_definitions: Dictionary = {}
var _event_log: Array[Dictionary] = []
var _visited: Dictionary = {}
var _actions: Dictionary = {}
var _current_zone := ""
var _spawn := Vector2.ZERO

func _ready() -> void:
	var result: Dictionary = loader.load_and_validate_all()
	if not result["ok"]:
		push_error("Content invalid: %s" % result["errors"])
		status.text = "CONTENT INVALID"
		return
	_content = result["content"]
	_layout = _content["layout"]
	_spawn = _vector(_layout["playerSpawn"])
	_build_layout()
	var config = loader.movement_config()
	player.global_position = _spawn
	player.configure(config)
	_configure_enemies()
	artifacts.configure(_content["artifacts"], Callable(self, "_active_enemies"), player)
	_connect_runtime(config)
	camera_rig.configure(player, _layout)
	zone_tracker.configure(player, _layout["zones"])
	reset_button.pressed.connect(reset_sandbox)
	status.text = "GATE 1 M6  ·  SIX-ZONE GRAYBOX  ·  %s" % config.id

func _build_layout() -> void:
	_builder.build(_layout, {
		"backdrops": $World/ZoneBackdrops,
		"platforms": $World/Platforms,
		"enemies": $World/Enemies,
		"anchors": $World/RespawnAnchors,
		"triggers": $World/RoomTriggers
	})

func _configure_enemies() -> void:
	_enemy_definitions.clear()
	for definition in _content["enemies"]["enemies"]: _enemy_definitions[str(definition["id"])] = definition
	for enemy in $World/Enemies.get_children():
		enemy.configure(_enemy_definitions[enemy.content_id])
		if not enemy.combat_event.is_connected(_on_combat): enemy.combat_event.connect(_on_combat)

func _connect_runtime(config) -> void:
	input_adapter.intent_emitted.connect(player.queue_intent)
	input_adapter.intent_emitted.connect(_on_intent)
	input_adapter.sample_observed.connect(trace.observe_sample)
	player.movement_snapshot_updated.connect(_on_snapshot)
	player.movement_event.connect(_on_movement_event)
	player.dash_target_crossed.connect(_on_dash)
	player.dash_target_crossed.connect(artifacts.on_dash_target_crossed)
	player.movement_gameplay_event.connect(artifacts.on_movement_gameplay_event)
	artifacts.artifact_triggered.connect(_on_artifact)
	zone_tracker.zone_changed.connect(_on_zone_changed)
	input_adapter.configure(config, Callable(player, "is_airborne"))

func _on_zone_changed(zone: Dictionary) -> void:
	_current_zone = str(zone["id"])
	_visited[_current_zone] = true
	zone_prompt.text = str(zone["prompt"])
	review_panel.visible = _current_zone == "F"
	if _current_zone == "F": _mark_action("F", "review_reset")
	_update_review()

func _on_intent(intent) -> void:
	trace.observe_intent(intent)
	intent_label.text = trace.intent_text()

func _on_snapshot(snapshot) -> void:
	movement_label.text = "state: %s  velocity: (%.2f, %.2f)" % [snapshot.state_name(), snapshot.velocity.x, snapshot.velocity.y]
	if snapshot.state_name() == "wall_slide": _mark_action("E", "wall_slide")

func _on_movement_event(event_name: String) -> void:
	event_label.text = "movement: %s" % event_name
	if event_name == "double_jump_started": _mark_action("B", "jump_double_jump")
	elif event_name == "hard_landing": _mark_action("D", "fast_fall")

func _on_dash(target, action_id: int) -> void:
	_record({"event":"dash_passed_enemy", "target":target.instance_key, "actionId":action_id})
	_mark_action("A", "dash_traversal")

func _on_combat(event: Dictionary) -> void:
	_record(event)
	event_label.text = "event: %s  target: %s  health: %s" % [event["event"], event["enemy"], event["health"]]

func _on_artifact(event: Dictionary) -> void:
	_record({"event":"artifact_triggered", "artifactId":event["artifactId"], "actionId":event["actionId"], "affectedTargets":event["affectedTargets"]})
	event_label.text = "artifact: %s" % event["artifactId"]
	if event["artifactId"] == "artifact_wind_ring": _mark_action("C", "wind_ring")
	elif event["artifactId"] == "artifact_starfall_seal": _mark_action("D", "fast_fall")
	elif event["artifactId"] == "artifact_blade_talisman": _mark_action("A", "dash_traversal")

func _mark_action(zone_id: String, action: String) -> void:
	if _current_zone != zone_id: return
	_actions[zone_id] = action
	_update_review()

func _record(event: Dictionary) -> void:
	var entry := event.duplicate(true)
	entry["zone"] = _current_zone
	entry["physicsFrame"] = Engine.get_physics_frames()
	_event_log.append(entry)

func _update_review() -> void:
	if review_summary == null: return
	var lines: Array[String] = []
	for zone in _layout.get("zones", []):
		var zone_id := str(zone["id"])
		var visited := "visited" if _visited.has(zone_id) else "not visited"
		var action := "passed" if _actions.get(zone_id) == zone["primaryAction"] else "pending"
		lines.append("%s · %-11s · %s" % [zone_id, visited, action])
	review_summary.text = "\n".join(lines)

func reset_sandbox() -> void:
	_event_log.clear()
	_visited.clear()
	_actions.clear()
	_current_zone = ""
	_configure_enemies()
	artifacts.configure(_content["artifacts"], Callable(self, "_active_enemies"), player)
	player.reset_to(_spawn)
	camera_rig.snap_to_target()
	zone_tracker.reset()
	review_panel.visible = false
	_update_review()
	event_label.text = "event: sandbox reset"

func run_summary() -> Dictionary:
	var zone_results: Array[Dictionary] = []
	for zone in _layout.get("zones", []):
		var zone_id := str(zone["id"])
		zone_results.append({
			"id": zone_id,
			"visited": _visited.has(zone_id),
			"primaryAction": zone["primaryAction"],
			"passed": _actions.get(zone_id) == zone["primaryAction"]
		})
	return {"currentZone":_current_zone, "zones":zone_results, "events":_event_log.duplicate(true)}

func current_zone_id() -> String: return _current_zone
func layout_content() -> Dictionary: return _layout.duplicate(true)
func event_log() -> Array[Dictionary]: return _event_log.duplicate(true)

func _active_enemies() -> Array[Node]:
	var result: Array[Node] = []
	for enemy in $World/Enemies.get_children(): result.append(enemy)
	return result

func _vector(value: Array) -> Vector2: return Vector2(float(value[0]), float(value[1]))
