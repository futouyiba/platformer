class_name SandboxCameraController
extends Node2D

var _target: Node2D
var _world_bounds := Rect2()
var _viewport_size := Vector2(390, 844)

func configure(target: Node2D, layout: Dictionary) -> void:
	_target = target
	var bounds: Dictionary = layout["worldBounds"]
	_world_bounds = Rect2(float(bounds["x"]), float(bounds["y"]), float(bounds["width"]), float(bounds["height"]))
	_viewport_size = Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", 390)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", 844))
	)
	reset_to_target()

func _physics_process(_delta: float) -> void: snap_to_target()

func snap_to_target() -> void:
	if _target == null or _world_bounds.size == Vector2.ZERO: return
	var half := _viewport_size * 0.5
	var minimum := _world_bounds.position + half
	var maximum := _world_bounds.end - half
	global_position = Vector2(
		clampf(_target.global_position.x, minimum.x, maximum.x),
		clampf(_target.global_position.y, minimum.y, maximum.y)
	)

func reset_to_target() -> void:
	snap_to_target()
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera != null: camera.reset_smoothing()

func world_bounds() -> Rect2: return _world_bounds
