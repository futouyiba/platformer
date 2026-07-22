class_name MovementCommand
extends RefCounted
var move_axis := 0.0
var jump_requested := false
var dash_requested := false
var dash_axis := 0.0
var fast_fall_requested := false

static func create(axis := 0.0, jump := false, dash := false, requested_dash_axis := 0.0, fast_fall := false) -> MovementCommand:
	var command := MovementCommand.new()
	command.move_axis=clampf(axis,-1,1); command.jump_requested=jump; command.dash_requested=dash; command.dash_axis=clampf(requested_dash_axis,-1,1); command.fast_fall_requested=fast_fall
	return command
