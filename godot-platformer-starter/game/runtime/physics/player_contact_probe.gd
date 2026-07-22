class_name PlayerContactProbe
extends RefCounted
const Contacts=preload("res://game/core/movement/movement_contacts.gd")
var _ground:ShapeCast2D
var _wall:ShapeCast2D
var _ceiling:ShapeCast2D
var _wall_distance:=0.0
func configure(ground:ShapeCast2D,wall:ShapeCast2D,ceiling:ShapeCast2D)->void:_ground=ground;_wall=wall;_ceiling=ceiling;_wall_distance=absf(wall.target_position.x)
func sample(facing:float):
	var direction:=1.0 if is_zero_approx(facing) else signf(facing)
	_wall.target_position=Vector2(_wall_distance*direction,0)
	_ground.force_shapecast_update();_wall.force_shapecast_update();_ceiling.force_shapecast_update()
	var grounded:=_ground.is_colliding();var wall:=_wall.is_colliding();var ceiling:=_ceiling.is_colliding()
	return Contacts.create(grounded,wall,_wall.get_collision_normal(0) if wall else Vector2.ZERO,ceiling,_ground.get_collision_normal(0) if grounded else Vector2.UP,_ceiling.get_collision_normal(0) if ceiling else Vector2.DOWN)
