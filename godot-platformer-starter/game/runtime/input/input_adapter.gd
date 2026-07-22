class_name SandboxInputAdapter
extends Node
signal intent_emitted(intent)
signal sample_observed(sample,dead_zone)
const Sample=preload("res://game/core/input/pointer_sample.gd")
const Intent=preload("res://game/core/input/input_intent.gd")
const Classifier=preload("res://game/core/input/input_intent_classifier.gd")
var _classifier:=Classifier.new()
var _config
var _airborne:Callable
func configure(config,airborne_provider:Callable)->void: _config=config; _airborne=airborne_provider; _classifier.configure(config)
func _unhandled_input(event:InputEvent)->void:
	if _config==null:return
	var size:=get_viewport().get_visible_rect().size
	if event is InputEventScreenTouch: _pointer(event.position,Sample.Phase.DOWN if event.pressed else Sample.Phase.UP,size)
	elif event is InputEventScreenDrag: _pointer(event.position,Sample.Phase.MOVE,size)
func _physics_process(_delta:float)->void:
	if _config==null:return
	var time:=Time.get_ticks_usec()/1000000.0
	var axis:=Input.get_axis("move_left","move_right")
	intent_emitted.emit(Intent.create(Intent.Kind.MOVE,Vector2(axis,0),1,"keyboard",time))
	if Input.is_action_just_pressed("jump_request") or Input.is_action_just_pressed("move_up"): intent_emitted.emit(Intent.create(Intent.Kind.JUMP_REQUEST,Vector2.UP,1,"keyboard",time))
	elif Input.is_action_just_pressed("dash_request"): intent_emitted.emit(Intent.create(Intent.Kind.DASH_REQUEST,Vector2(1 if is_zero_approx(axis) else signf(axis),0),1,"keyboard",time))
	elif Input.is_action_just_pressed("fast_fall_request") and _is_airborne(): intent_emitted.emit(Intent.create(Intent.Kind.FAST_FALL_REQUEST,Vector2.DOWN,1,"keyboard",time))
func _pointer(position:Vector2,phase,viewport_size:Vector2)->void:
	var sample=Sample.create(Time.get_ticks_usec()/1000000.0,Vector2(position.x/viewport_size.x,position.y/viewport_size.y),phase)
	sample_observed.emit(sample,_config.gesture_dead_zone_normalized); intent_emitted.emit(_classifier.classify(sample,_is_airborne()))
func _is_airborne()->bool:return _airborne.is_valid() and bool(_airborne.call())
