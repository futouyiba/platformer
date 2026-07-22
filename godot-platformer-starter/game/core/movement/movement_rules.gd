class_name MovementRules
extends RefCounted

func step_horizontal(current_velocity: float, input_axis: float, delta: float, config: MovementConfig, grounded := true) -> float:
	var axis := clampf(input_axis, -1.0, 1.0)
	var acceleration := config.ground_acceleration if grounded else config.air_acceleration
	var deceleration := config.ground_deceleration if grounded else config.air_deceleration
	var rate := acceleration if not is_zero_approx(axis) else deceleration
	return move_toward(current_velocity, axis * config.max_run_speed, rate * delta)
