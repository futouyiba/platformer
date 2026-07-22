class_name SafeRespawnTracker
extends RefCounted
const ENEMY_MASK:=1<<2
var _shape:CollisionShape2D
var _position:=Vector2.ZERO
var _has:=false
func configure(shape:CollisionShape2D)->void:_shape=shape
func observe(body:CharacterBody2D,contacts)->bool:
	if not contacts.grounded or contacts.wall_contact or contacts.ceiling_contact or _overlaps_enemy(body):return false
	_position=body.global_position;_has=true;return true
func respawn(body:CharacterBody2D)->bool:
	if not _has:return false
	body.global_position=_position;body.velocity=Vector2.ZERO;return true
func has_safe_position()->bool:return _has
func safe_global_position()->Vector2:return _position
func _overlaps_enemy(body:CharacterBody2D)->bool:
	var params:=PhysicsShapeQueryParameters2D.new();params.shape=_shape.shape;params.transform=body.global_transform*_shape.transform;params.collision_mask=ENEMY_MASK;params.exclude=[body.get_rid()]
	return not body.get_world_2d().direct_space_state.intersect_shape(params,1).is_empty()
