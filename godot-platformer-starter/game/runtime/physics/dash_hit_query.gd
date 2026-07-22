class_name DashHitQuery
extends RefCounted
var _cast:ShapeCast2D
var _distance:=0.0
var _action_id:=-1
var _seen:Dictionary={}
func configure(shape_cast:ShapeCast2D)->void:_cast=shape_cast;_distance=absf(shape_cast.target_position.x)
func collect(direction:float,action_id:int)->Array[Object]:
	var targets:Array[Object]=[]
	if action_id<=0:return targets
	if action_id!=_action_id:_action_id=action_id;_seen.clear()
	var facing:=1.0 if is_zero_approx(direction) else signf(direction)
	_cast.target_position=Vector2(_distance*facing,0);_cast.force_shapecast_update()
	for index in _cast.get_collision_count():_append(_cast.get_collider(index),targets)
	for result in _swept(facing):_append(result["collider"],targets)
	return targets
func reset()->void:_action_id=-1;_seen.clear()
func _swept(direction:float)->Array[Dictionary]:
	if not _cast.shape is RectangleShape2D:return []
	var source:RectangleShape2D=_cast.shape
	var shape:=RectangleShape2D.new();shape.size=Vector2(source.size.x+_distance,source.size.y)
	var params:=PhysicsShapeQueryParameters2D.new();params.shape=shape;params.transform=Transform2D(_cast.global_rotation,_cast.global_position+Vector2(_distance*direction*0.5,0).rotated(_cast.global_rotation));params.collision_mask=_cast.collision_mask;params.collide_with_bodies=true;params.collide_with_areas=true
	return _cast.get_world_2d().direct_space_state.intersect_shape(params,32)
func _append(collider:Variant,targets:Array[Object])->void:
	if not collider is Object:return
	var id:int=collider.get_instance_id()
	if _seen.has(id):return
	_seen[id]=true;targets.append(collider)
