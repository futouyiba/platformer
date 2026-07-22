class_name MovementSnapshot
extends RefCounted
enum State { GROUNDED, RUN, RISING, DOUBLE_JUMP, FALLING, FAST_FALL, DASH, WALL_SLIDE, WALL_RELEASE, HURT, RESPAWN }
var state: State = State.GROUNDED
var velocity := Vector2.ZERO
var facing := 1.0
var jumps_used := 0
var air_time_seconds := 0.0
var invulnerable := false
var action_id := 0
var events: Array[String] = []
var gameplay_events: Array[Dictionary] = []
func state_name() -> String: return State.keys()[state].to_lower()
func to_dictionary() -> Dictionary:
	return {"state":state_name(),"velocity":{"x":velocity.x,"y":velocity.y},"facing":facing,"jumpsUsed":jumps_used,"airTimeSeconds":air_time_seconds,"invulnerable":invulnerable,"actionId":action_id,"events":events.duplicate(),"gameplayEvents":gameplay_events.duplicate(true)}
