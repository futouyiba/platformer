class_name SandboxDirector
extends Node2D
@onready var player:CharacterBody2D=$Player
@onready var loader:Node=$Systems/ContentLoader
@onready var input_adapter:Node=$Systems/InputAdapter
@onready var artifacts:Node=$Systems/ArtifactSystem
@onready var status:Label=$DebugUI/Panel/Status
@onready var intent_label:Label=$DebugUI/Panel/Intent
@onready var movement_label:Label=$DebugUI/Panel/Movement
@onready var event_label:Label=$DebugUI/Panel/Event
@onready var trace:Control=$DebugUI/InputTrace
var _event_log:Array[Dictionary]=[]
func _ready()->void:
	var result:Dictionary=loader.load_and_validate_all()
	if not result["ok"]:push_error("Content invalid: %s"%result["errors"]);status.text="CONTENT INVALID";return
	var config=loader.movement_config();player.configure(config)
	_configure_enemies(result["content"]["enemies"])
	artifacts.configure(result["content"]["artifacts"],Callable(self,"_active_enemies"),player)
	input_adapter.intent_emitted.connect(player.queue_intent);input_adapter.intent_emitted.connect(_on_intent);input_adapter.sample_observed.connect(trace.observe_sample)
	player.movement_snapshot_updated.connect(_on_snapshot);player.dash_target_crossed.connect(_on_dash);player.dash_target_crossed.connect(artifacts.on_dash_target_crossed);player.movement_gameplay_event.connect(artifacts.on_movement_gameplay_event);artifacts.artifact_triggered.connect(_on_artifact)
	input_adapter.configure(config,Callable(player,"is_airborne"));status.text="GATE 1 M0-M5  |  %s"%config.id
func _configure_enemies(bundle:Dictionary)->void:
	var definitions:Dictionary={}
	for definition in bundle["enemies"]:definitions[definition["id"]]=definition
	for enemy in $World/Enemies.get_children():enemy.configure(definitions[enemy.content_id]);enemy.combat_event.connect(_on_combat)
func _on_intent(intent)->void:trace.observe_intent(intent);intent_label.text=trace.intent_text()
func _on_snapshot(snapshot)->void:movement_label.text="state: %s  velocity: (%.2f, %.2f)"%[snapshot.state_name(),snapshot.velocity.x,snapshot.velocity.y]
func _on_dash(target,action_id:int)->void:_record({"event":"dash_passed_enemy","target":target.instance_key,"actionId":action_id})
func _on_combat(event:Dictionary)->void:_record(event);event_label.text="event: %s  target: %s  health: %s"%[event["event"],event["enemy"],event["health"]]
func _on_artifact(event:Dictionary)->void:_record({"event":"artifact_triggered","artifactId":event["artifactId"],"actionId":event["actionId"],"affectedTargets":event["affectedTargets"]});event_label.text="artifact: %s"%event["artifactId"]
func _record(event:Dictionary)->void:
	var entry:=event.duplicate(true);entry["physicsFrame"]=Engine.get_physics_frames();_event_log.append(entry)
func event_log()->Array[Dictionary]:return _event_log.duplicate(true)
func _active_enemies()->Array[Node]:
	var result:Array[Node]=[]
	for enemy in $World/Enemies.get_children():result.append(enemy)
	return result
