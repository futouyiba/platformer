class_name InputIntentClassifier
extends RefCounted

var _config: MovementConfig
var _active := false
var _committed := false
var _origin := Vector2.ZERO
var _started_at := 0.0

func configure(config: MovementConfig) -> void: _config = config; reset()
func reset() -> void:
	_active = false; _committed = false; _origin = Vector2.ZERO; _started_at = 0.0

func classify(sample: PointerSample, is_airborne: bool) -> InputIntent:
	if _config == null: return InputIntent.create(InputIntent.Kind.RELEASE, Vector2.ZERO, 0.0, "unconfigured", sample.time_seconds)
	match sample.phase:
		PointerSample.Phase.DOWN:
			_active = true; _committed = false; _origin = sample.position_normalized; _started_at = sample.time_seconds
			return InputIntent.create(InputIntent.Kind.MOVE, Vector2.ZERO, 1.0, "touch", sample.time_seconds)
		PointerSample.Phase.UP:
			_active = false; _committed = false
			return InputIntent.create(InputIntent.Kind.RELEASE, Vector2.ZERO, 1.0, "touch", sample.time_seconds)
		PointerSample.Phase.MOVE: return _classify_move(sample, is_airborne)
	return InputIntent.create(InputIntent.Kind.RELEASE, Vector2.ZERO, 0.0, "unknown", sample.time_seconds)

func _classify_move(sample: PointerSample, airborne: bool) -> InputIntent:
	if not _active: return InputIntent.create(InputIntent.Kind.RELEASE, Vector2.ZERO, 0.0, "orphan", sample.time_seconds)
	var displacement := sample.position_normalized - _origin
	var magnitude := displacement.length()
	if magnitude < _config.gesture_dead_zone_normalized: return InputIntent.create(InputIntent.Kind.MOVE, Vector2.ZERO, 1.0, "touch", sample.time_seconds)
	var horizontal := absf(displacement.x)
	var vertical := absf(displacement.y)
	var horizontal_dominant := horizontal >= vertical * _config.direction_dominance_ratio
	var vertical_dominant := vertical >= horizontal * _config.direction_dominance_ratio
	var flick := sample.time_seconds - _started_at <= _config.flick_window_seconds and magnitude >= _config.flick_threshold_normalized
	if not _committed and flick and horizontal_dominant:
		_committed = true
		return InputIntent.create(InputIntent.Kind.DASH_REQUEST, Vector2(signf(displacement.x),0), _confidence(horizontal,vertical), "touch_flick", sample.time_seconds)
	if not _committed and vertical_dominant and displacement.y < 0.0:
		_committed = true
		return InputIntent.create(InputIntent.Kind.JUMP_REQUEST, Vector2.UP, _confidence(vertical,horizontal), "touch", sample.time_seconds)
	if not _committed and vertical_dominant and displacement.y > 0.0 and airborne:
		_committed = true
		return InputIntent.create(InputIntent.Kind.FAST_FALL_REQUEST, Vector2.DOWN, _confidence(vertical,horizontal), "touch", sample.time_seconds)
	var axis := clampf(displacement.x / _config.flick_threshold_normalized, -1.0, 1.0)
	return InputIntent.create(InputIntent.Kind.MOVE, Vector2(axis,0), _confidence(horizontal,vertical), "touch", sample.time_seconds)

func _confidence(primary: float, secondary: float) -> float:
	return 0.0 if is_zero_approx(primary) else clampf(1.0 - secondary / primary, 0.0, 1.0)
