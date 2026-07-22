class_name PointerSample
extends RefCounted

enum Phase { DOWN, MOVE, UP }
var time_seconds: float
var position_normalized: Vector2
var phase: Phase

static func create(sample_time: float, position: Vector2, sample_phase: Phase) -> PointerSample:
	var sample := PointerSample.new()
	sample.time_seconds = sample_time
	sample.position_normalized = position
	sample.phase = sample_phase
	return sample

func to_dictionary() -> Dictionary:
	return {"timeSeconds":time_seconds, "x":position_normalized.x, "y":position_normalized.y, "phase":Phase.keys()[phase].to_lower()}
