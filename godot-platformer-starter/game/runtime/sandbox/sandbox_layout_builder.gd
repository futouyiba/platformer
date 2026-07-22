class_name SandboxLayoutBuilder
extends RefCounted

const EnemyScript = preload("res://game/runtime/combat/training_enemy.gd")
const WORLD_LAYER := 1
const ENEMY_LAYER := 1 << 2
const TRIGGER_LAYER := 1 << 3
const PLAYER_LAYER := 1 << 1

func build(layout: Dictionary, roots: Dictionary) -> void:
	for root in roots.values(): _clear(root)
	for zone in layout["zones"]:
		_add_backdrop(roots["backdrops"], zone)
		_add_anchor(roots["anchors"], zone)
		_add_trigger(roots["triggers"], zone)
		for platform in zone["platforms"]: _add_platform(roots["platforms"], platform, zone["color"])
		for enemy in zone["enemies"]: _add_enemy(roots["enemies"], enemy)

func _clear(root: Node) -> void:
	for child in root.get_children():
		root.remove_child(child)
		child.queue_free()

func _add_backdrop(root: Node2D, zone: Dictionary) -> void:
	var bounds := _rect(zone["bounds"])
	var panel := Polygon2D.new()
	panel.name = "Zone%sBackdrop" % zone["id"]
	panel.position = bounds.position
	panel.polygon = PackedVector2Array([Vector2.ZERO, Vector2(bounds.size.x, 0), bounds.size, Vector2(0, bounds.size.y)])
	panel.color = Color.from_string(str(zone["color"]), Color("182330"))
	panel.z_index = -10
	root.add_child(panel)
	var heading := Label.new()
	heading.name = "Zone%sHeading" % zone["id"]
	heading.position = Vector2(bounds.position.x + 20, 170)
	heading.text = "%s  /  %s" % [zone["id"], str(zone["name"]).to_upper()]
	heading.add_theme_font_size_override("font_size", 22)
	heading.modulate = Color(1, 1, 1, 0.34)
	heading.z_index = -5
	root.add_child(heading)

func _add_platform(root: Node2D, spec: Dictionary, color_value: String) -> void:
	var size := _vector(spec["size"])
	var body := StaticBody2D.new()
	body.name = str(spec["id"])
	body.position = _vector(spec["position"])
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = shape
	body.add_child(collision)
	var surface := Polygon2D.new()
	surface.name = "Surface"
	var half := size * 0.5
	surface.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)])
	surface.color = Color.from_string(color_value, Color("263746")).lightened(0.28)
	body.add_child(surface)
	root.add_child(body)

func _add_enemy(root: Node2D, spec: Dictionary) -> void:
	var body := CharacterBody2D.new()
	body.name = str(spec["id"])
	body.position = _vector(spec["position"])
	body.collision_layer = ENEMY_LAYER
	body.collision_mask = WORLD_LAYER
	body.set_script(EnemyScript)
	body.set("content_id", str(spec["contentId"]))
	body.set("instance_key", str(spec["instanceKey"]))
	var shape := CapsuleShape2D.new()
	shape.radius = 10.0
	shape.height = 30.0
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = shape
	body.add_child(collision)
	var visual := Polygon2D.new()
	visual.name = "Body"
	visual.polygon = PackedVector2Array([Vector2(0, -15), Vector2(10, -7), Vector2(9, 15), Vector2(-9, 15), Vector2(-10, -7)])
	visual.color = Color("ad2f24")
	body.add_child(visual)
	root.add_child(body)

func _add_anchor(root: Node2D, zone: Dictionary) -> void:
	var anchor := Marker2D.new()
	anchor.name = "Spawn%s" % zone["id"]
	anchor.position = _vector(zone["respawn"])
	anchor.set_meta("zone_id", zone["id"])
	root.add_child(anchor)

func _add_trigger(root: Node2D, zone: Dictionary) -> void:
	var bounds := _rect(zone["bounds"])
	var area := Area2D.new()
	area.name = "Zone%s" % zone["id"]
	area.position = bounds.get_center()
	area.collision_layer = TRIGGER_LAYER
	area.collision_mask = PLAYER_LAYER
	area.monitoring = true
	area.set_meta("zone_id", zone["id"])
	area.set_meta("primary_action", zone["primaryAction"])
	var shape := RectangleShape2D.new()
	shape.size = bounds.size
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = shape
	area.add_child(collision)
	root.add_child(area)

func _vector(value: Array) -> Vector2: return Vector2(float(value[0]), float(value[1]))
func _rect(value: Dictionary) -> Rect2: return Rect2(float(value["x"]), float(value["y"]), float(value["width"]), float(value["height"]))
