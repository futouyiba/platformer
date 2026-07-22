class_name SandboxPlayerController
extends CharacterBody2D
signal movement_snapshot_updated(snapshot)
signal movement_event(event_name)
signal movement_gameplay_event(event_data)
signal dash_target_crossed(target,action_id)
const Intent=preload("res://game/core/input/input_intent.gd")
const Command=preload("res://game/core/movement/movement_command.gd")
const Machine=preload("res://game/core/movement/movement_state_machine.gd")
const ContactProbe=preload("res://game/runtime/physics/player_contact_probe.gd")
const DashQuery=preload("res://game/runtime/physics/dash_hit_query.gd")
const Respawn=preload("res://game/runtime/physics/safe_respawn_tracker.gd")
const PIXELS_PER_UNIT:=32.0
@onready var _shape:CollisionShape2D=$CollisionShape2D
@onready var _ground:ShapeCast2D=$GroundShapeCast
@onready var _wall:ShapeCast2D=$WallShapeCast
@onready var _ceiling:ShapeCast2D=$CeilingShapeCast
@onready var _dash_cast:ShapeCast2D=$DashHitShapeCast
var _config
var _machine:=Machine.new()
var _probe:=ContactProbe.new()
var _dash_query:=DashQuery.new()
var _respawn:=Respawn.new()
var _move:=0.0
var _jump:=false
var _dash:=false
var _dash_axis:=0.0
var _fast_fall:=false
var _latest
func _ready()->void:_probe.configure(_ground,_wall,_ceiling);_dash_query.configure(_dash_cast);_respawn.configure(_shape)
func configure(config)->void:_config=config;_machine.configure(config)
func queue_intent(intent)->void:
	match intent.kind:
		Intent.Kind.MOVE:_move=intent.direction.x
		Intent.Kind.JUMP_REQUEST:_jump=true
		Intent.Kind.DASH_REQUEST:_dash=true;_dash_axis=intent.direction.x
		Intent.Kind.FAST_FALL_REQUEST:_fast_fall=true
		Intent.Kind.RELEASE:_move=0
func is_airborne()->bool:return _machine.is_airborne()
func latest_snapshot():return _latest
func has_safe_respawn()->bool:return _respawn.has_safe_position()
func safe_respawn_position()->Vector2:return _respawn.safe_global_position()
func respawn_to_last_safe()->bool:
	var ok:=_respawn.respawn(self)
	if ok:_machine.respawn();_dash_query.reset()
	return ok
func _physics_process(delta:float)->void:
	if _config==null:return
	var facing: float = _move if not is_zero_approx(_move) else (1.0 if _latest==null else _latest.facing)
	var contacts=_probe.sample(facing)
	_latest=_machine.step(Command.create(_move,_jump,_dash,_dash_axis,_fast_fall),contacts,delta)
	velocity=_latest.velocity*PIXELS_PER_UNIT
	if _latest.state_name()=="dash":
		for target in _dash_query.collect(_latest.facing,_latest.action_id):dash_target_crossed.emit(target,_latest.action_id)
	move_and_slide();_respawn.observe(self,_probe.sample(_latest.facing))
	for event_name in _latest.events:movement_event.emit(event_name)
	for event_data in _latest.gameplay_events:movement_gameplay_event.emit(event_data)
	movement_snapshot_updated.emit(_latest)
	_jump=false;_dash=false;_dash_axis=0;_fast_fall=false
