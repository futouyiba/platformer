class_name MovementStateMachine
extends RefCounted

const RulesScript=preload("res://game/core/movement/movement_rules.gd")
const SnapshotScript=preload("res://game/core/movement/movement_snapshot.gd")
var _config: MovementConfig
var _rules:=RulesScript.new()
var _state=SnapshotScript.State.GROUNDED
var _velocity:=Vector2.ZERO
var _facing:=1.0
var _jumps:=0
var _air_time:=0.0
var _coyote:=0.0
var _buffer:=0.0
var _dash_remaining:=0.0
var _dash_cooldown:=0.0
var _dash_direction:=1.0
var _wall_grace:=0.0
var _was_grounded:=false
var _action_id:=0

func configure(config: MovementConfig)->void: _config=config; reset()
func reset()->void:
	_state=SnapshotScript.State.GROUNDED; _velocity=Vector2.ZERO; _facing=1.0; _jumps=0; _air_time=0.0; _coyote=0.0; _buffer=0.0; _dash_remaining=0.0; _dash_cooldown=0.0; _wall_grace=0.0; _was_grounded=false; _action_id=0

func step(command: MovementCommand, contacts: MovementContacts, delta: float)->MovementSnapshot:
	var events:Array[String]=[]
	var gameplay:Array[Dictionary]=[]
	if _config==null: return _snapshot(events,gameplay)
	_coyote=maxf(0,_coyote-delta); _buffer=maxf(0,_buffer-delta); _dash_cooldown=maxf(0,_dash_cooldown-delta); _wall_grace=maxf(0,_wall_grace-delta)
	if command.jump_requested: _buffer=_config.jump_buffer_seconds
	if not is_zero_approx(command.move_axis): _facing=signf(command.move_axis)
	var landed:=contacts.grounded and not _was_grounded
	if contacts.grounded:
		if landed:
			var fall_speed:=_velocity.y
			var prior_air_time:=_air_time
			events.append("landed")
			if _state==SnapshotScript.State.FAST_FALL:
				events.append("hard_landing")
				gameplay.append({"type":"hard_landing","actionId":_action_id,"fallSpeed":fall_speed,"airTimeSeconds":prior_air_time})
		_coyote=_config.coyote_time_seconds; _air_time=0; _jumps=0
		if _velocity.y>0: _velocity.y=0
	else: _air_time+=delta
	var action_started:=false
	if _dash_remaining>0:
		_velocity=Vector2(_dash_direction*_config.dash_speed,0); _state=SnapshotScript.State.DASH; _dash_remaining=maxf(0,_dash_remaining-delta); action_started=true
		if is_zero_approx(_dash_remaining): events.append("dash_ended")
	elif command.dash_requested and _dash_cooldown<=0:
		var direction:=command.dash_axis if not is_zero_approx(command.dash_axis) else command.move_axis
		if is_zero_approx(direction): direction=_facing
		_dash_direction=signf(direction); _facing=_dash_direction; _action_id+=1; _dash_remaining=_config.dash_duration_seconds; _dash_cooldown=_config.dash_duration_seconds+_config.dash_cooldown_seconds; _velocity=Vector2(_dash_direction*_config.dash_speed,0); _state=SnapshotScript.State.DASH; events.append("dash_started"); action_started=true
	if not action_started and _buffer>0:
		if contacts.grounded or _coyote>0:
			_velocity.y=-_config.jump_speed; _jumps=1; _state=SnapshotScript.State.RISING; _buffer=0; _coyote=0; _action_id+=1; events.append("jump_started"); action_started=true
		elif _jumps<2:
			_velocity.y=-_config.double_jump_speed; _jumps=2; _state=SnapshotScript.State.DOUBLE_JUMP; _buffer=0; _action_id+=1; events.append("double_jump_started"); gameplay.append({"type":"double_jump_started","actionId":_action_id}); action_started=true
	if not action_started: _step_regular(command,contacts,delta,events)
	_was_grounded=contacts.grounded
	return _snapshot(events,gameplay)

func _step_regular(command:MovementCommand, contacts:MovementContacts, delta:float, events:Array[String])->void:
	_velocity.x=_rules.step_horizontal(_velocity.x,command.move_axis,delta,_config,contacts.grounded)
	if contacts.grounded:
		_state=SnapshotScript.State.RUN if not is_zero_approx(command.move_axis) else SnapshotScript.State.GROUNDED
		return
	if command.fast_fall_requested:
		_action_id+=1; _state=SnapshotScript.State.FAST_FALL; events.append("fast_fall_started")
	if contacts.ceiling_contact and _velocity.y<0: _velocity.y=0; events.append("ceiling_contact")
	var pushing:=contacts.wall_contact and command.move_axis*contacts.wall_normal.x<0
	if pushing: _wall_grace=_config.wall_grace_seconds
	if (pushing or _wall_grace>0) and _velocity.y>=0 and _state!=SnapshotScript.State.FAST_FALL:
		_velocity.y=minf(_velocity.y+_config.gravity*delta,_config.wall_slide_max_speed); _state=SnapshotScript.State.WALL_SLIDE; return
	var released:=_state==SnapshotScript.State.WALL_SLIDE and _wall_grace<=0
	_velocity.y+=(_config.fast_fall_gravity if _state==SnapshotScript.State.FAST_FALL else _config.gravity)*delta
	if released: _state=SnapshotScript.State.WALL_RELEASE
	elif _state!=SnapshotScript.State.FAST_FALL: _state=SnapshotScript.State.RISING if _velocity.y<0 else SnapshotScript.State.FALLING

func current_state_name()->String: return SnapshotScript.State.keys()[_state].to_lower()
func is_airborne()->bool: return _state not in [SnapshotScript.State.GROUNDED,SnapshotScript.State.RUN,SnapshotScript.State.RESPAWN]
func respawn()->MovementSnapshot: reset(); _state=SnapshotScript.State.RESPAWN; return _snapshot(["respawned"],[])

func _snapshot(events:Array[String], gameplay:Array[Dictionary])->MovementSnapshot:
	var result:=SnapshotScript.new()
	result.state=_state; result.velocity=_velocity; result.facing=_facing; result.jumps_used=_jumps; result.air_time_seconds=_air_time; result.invulnerable=_state==SnapshotScript.State.DASH; result.action_id=_action_id; result.events=events.duplicate(); result.gameplay_events=gameplay.duplicate(true)
	return result
