class_name SandboxDirector
extends Node2D

const LayoutBuilder = preload("res://game/runtime/sandbox/sandbox_layout_builder.gd")
const MOVEMENT_STATE_ACTIONS := {"wall_slide":"wall_slide"}
const MOVEMENT_EVENT_ACTIONS := {"double_jump_started":"jump_double_jump", "hard_landing":"fast_fall"}
const ARTIFACT_ACTIONS := {
	"artifact_wind_ring":"wind_ring",
	"artifact_starfall_seal":"fast_fall"
}
const ZONE_ENTRY_ACTION := "review_reset"

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
var _dash_hits_by_action: Dictionary = {}
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
	review_panel.visible = str(zone["primaryAction"]) == ZONE_ENTRY_ACTION
	_try_complete_primary_action(ZONE_ENTRY_ACTION)
	_update_review()

func _on_intent(intent) -> void:
	trace.observe_intent(intent)
	intent_label.text = trace.intent_text()

func _on_snapshot(snapshot) -> void:
	movement_label.text = "state: %s  velocity: (%.2f, %.2f)" % [snapshot.state_name(), snapshot.velocity.x, snapshot.velocity.y]
	_try_complete_primary_action(str(MOVEMENT_STATE_ACTIONS.get(snapshot.state_name(), "")))

func _on_movement_event(event_name: String) -> void:
	event_label.text = "movement: %s" % event_name
	_try_complete_primary_action(str(MOVEMENT_EVENT_ACTIONS.get(event_name, "")))

func _on_dash(target, action_id: int) -> void:
	_record({"event":"dash_passed_enemy", "target":target.instance_key, "actionId":action_id})
	_record_dash_target(target, action_id)

func _on_combat(event: Dictionary) -> void:
	_record(event)
	event_label.text = "event: %s  target: %s  health: %s" % [event["event"], event["enemy"], event["health"]]

func _on_artifact(event: Dictionary) -> void:
	_record({"event":"artifact_triggered", "artifactId":event["artifactId"], "actionId":event["actionId"], "affectedTargets":event["affectedTargets"]})
	event_label.text = "artifact: %s" % event["artifactId"]
	_try_complete_artifact_action(event)

func _try_complete_artifact_action(event: Dictionary) -> void:
	var action := str(ARTIFACT_ACTIONS.get(event["artifactId"], ""))
	if action.is_empty(): return
	var zone: Dictionary = zone_tracker.current_zone()
	if zone.is_empty() or str(zone["primaryAction"]) != action: return
	var configured_targets := _zone_target_keys(zone)
	if configured_targets.is_empty():
		_try_complete_primary_action(action)
		return
	for target_key in event.get("affectedTargets", []):
		if configured_targets.has(str(target_key)):
			_try_complete_primary_action(action)
			return

func _try_complete_primary_action(action: String) -> void:
	if action.is_empty(): return
	var zone: Dictionary = zone_tracker.current_zone()
	if zone.is_empty() or str(zone["primaryAction"]) != action: return
	_actions[str(zone["id"])] = action
	_update_review()

func _record_dash_target(target: Node, action_id: int) -> void:
	if action_id <= 0: return
	var zone: Dictionary = zone_tracker.current_zone()
	if zone.is_empty() or str(zone["primaryAction"]) != "dash_traversal": return
	var required_targets := _zone_target_keys(zone)
	var target_key := str(target.instance_key)
	if required_targets.is_empty() or not required_targets.has(target_key): return
	var progress_key := "%s:%d" % [zone["id"], action_id]
	if not _dash_hits_by_action.has(progress_key): _dash_hits_by_action[progress_key] = {}
	_dash_hits_by_action[progress_key][target_key] = true
	if _dash_hits_by_action[progress_key].size() == required_targets.size(): _try_complete_primary_action("dash_traversal")

func _zone_target_keys(zone: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for enemy in zone.get("enemies", []): result[str(enemy["instanceKey"])] = true
	return result

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
	_dash_hits_by_action.clear()
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
