class_name MovementConfig
extends RefCounted

var schema_version: int
var id: String
var fixed_tick_hz: int
var max_run_speed: float
var ground_acceleration: float
var ground_deceleration: float
var air_acceleration: float
var air_deceleration: float
var jump_speed: float
var double_jump_speed: float
var gravity: float
var fast_fall_gravity: float
var dash_speed: float
var dash_duration_seconds: float
var dash_cooldown_seconds: float
var coyote_time_seconds: float
var jump_buffer_seconds: float
var wall_slide_max_speed: float
var wall_grace_seconds: float
var gesture_dead_zone_normalized: float
var flick_window_seconds: float
var flick_threshold_normalized: float
var direction_dominance_ratio: float

static func from_dictionary(data: Dictionary) -> MovementConfig:
	var config := MovementConfig.new()
	config.schema_version = int(data["schemaVersion"])
	config.id = str(data["id"])
	config.fixed_tick_hz = int(data["fixedTickHz"])
	config.max_run_speed = float(data["maxRunSpeed"])
	config.ground_acceleration = float(data["groundAcceleration"])
	config.ground_deceleration = float(data["groundDeceleration"])
	config.air_acceleration = float(data["airAcceleration"])
	config.air_deceleration = float(data["airDeceleration"])
	config.jump_speed = float(data["jumpSpeed"])
	config.double_jump_speed = float(data["doubleJumpSpeed"])
	config.gravity = float(data["gravity"])
	config.fast_fall_gravity = float(data["fastFallGravity"])
	config.dash_speed = float(data["dashSpeed"])
	config.dash_duration_seconds = float(data["dashDurationSeconds"])
	config.dash_cooldown_seconds = float(data["dashCooldownSeconds"])
	config.coyote_time_seconds = float(data["coyoteTimeSeconds"])
	config.jump_buffer_seconds = float(data["jumpBufferSeconds"])
	config.wall_slide_max_speed = float(data["wallSlideMaxSpeed"])
	config.wall_grace_seconds = float(data["wallGraceSeconds"])
	config.gesture_dead_zone_normalized = float(data["gestureDeadZoneNormalized"])
	config.flick_window_seconds = float(data["flickWindowSeconds"])
	config.flick_threshold_normalized = float(data["flickThresholdNormalized"])
	config.direction_dominance_ratio = float(data["directionDominanceRatio"])
	return config
