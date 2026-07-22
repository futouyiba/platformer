class_name TrainingEnemy
extends CharacterBody2D
signal combat_event(event_data)
const CombatState=preload("res://game/core/combat/enemy_combat_state.gd")
const PIXELS_PER_UNIT:=32.0
@export var content_id:="enemy_training_soldier"
@export var instance_key:="enemy_training_01"
@onready var _shape:CollisionShape2D=$CollisionShape2D
@onready var _visual:CanvasItem=$Body
var _state:=CombatState.new()
var _configured:=false
var _last_result
func configure(data:Dictionary)->void:_state.configure(data);_configured=true;_shape.disabled=false;_visual.visible=true
func apply_damage(packet):
	_last_result=_state.apply_damage(packet)
	for event_name in _last_result.events:combat_event.emit({"event":event_name,"enemy":instance_key,"source":packet.source_id,"tags":packet.tags.duplicate(),"actionId":packet.action_id,"health":_state.health})
	if _last_result.died:_shape.set_deferred("disabled",true);_visual.visible=false
	return _last_result
func current_health()->int:return _state.health
func is_stunned()->bool:return _state.is_stunned()
func is_dead()->bool:return _state.is_dead()
func last_damage_result():return _last_result
func _physics_process(delta:float)->void:
	if not _configured or _state.is_dead():return
	_state.step(delta);velocity=_state.knockback_velocity*PIXELS_PER_UNIT;move_and_slide()
