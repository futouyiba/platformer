class_name SandboxZoneTracker
extends Node

signal zone_changed(zone_data)
var _player: Node2D
var _zones: Array[Dictionary] = []
var _current_id := ""

func configure(player: Node2D, zones: Array) -> void:
	_player = player
	_zones.assign(zones.duplicate(true))
	_current_id = ""
	force_position_check()

func _physics_process(_delta: float) -> void: force_position_check()

func force_position_check() -> void:
	if _player == null: return
	var zone := zone_at(_player.global_position)
	if zone.is_empty() or str(zone["id"]) == _current_id: return
	_current_id = str(zone["id"])
	zone_changed.emit(zone.duplicate(true))

func zone_at(position: Vector2) -> Dictionary:
	for zone in _zones:
		var bounds: Dictionary = zone["bounds"]
		var rect := Rect2(float(bounds["x"]), float(bounds["y"]), float(bounds["width"]), float(bounds["height"]))
		if rect.has_point(position): return zone
	return {}

func reset() -> void:
	_current_id = ""
	force_position_check()

func current_zone_id() -> String: return _current_id

func current_zone() -> Dictionary:
	for zone in _zones:
		if str(zone["id"]) == _current_id: return zone.duplicate(true)
	return {}
