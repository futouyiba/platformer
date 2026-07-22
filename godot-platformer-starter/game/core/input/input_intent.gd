class_name InputIntent
extends RefCounted

enum Kind { MOVE, JUMP_REQUEST, DASH_REQUEST, FAST_FALL_REQUEST, RELEASE }
var kind: Kind
var direction := Vector2.ZERO
var confidence := 0.0
var source: String
var time_seconds := 0.0

static func create(intent_kind: Kind, intent_direction: Vector2, value: float, intent_source: String, sample_time: float) -> InputIntent:
	var intent := InputIntent.new()
	intent.kind = intent_kind
	intent.direction = intent_direction
	intent.confidence = clampf(value, 0.0, 1.0)
	intent.source = intent_source
	intent.time_seconds = sample_time
	return intent

func kind_name() -> String: return Kind.keys()[kind].to_lower()
func to_dictionary() -> Dictionary:
	return {"kind":kind_name(), "direction":{"x":direction.x,"y":direction.y}, "confidence":confidence, "source":source, "timeSeconds":time_seconds}
