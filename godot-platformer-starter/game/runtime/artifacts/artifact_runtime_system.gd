class_name ArtifactRuntimeSystem
extends Node
signal artifact_triggered(event_data)
const Resolver=preload("res://game/core/artifacts/artifact_trigger_resolver.gd")
const Packet=preload("res://game/core/combat/damage_packet.gd")
const PIXELS_PER_UNIT:=32.0
var _resolver:=Resolver.new()
var _enemies:Callable
var _player:CharacterBody2D
func configure(bundle:Dictionary,enemies:Callable,player:CharacterBody2D)->void:_resolver.configure(bundle);_enemies=enemies;_player=player
func on_dash_target_crossed(target,action_id:int)->void:_execute({"type":"dash_passed_enemy","actionId":action_id,"targetKey":target.instance_key},target)
func on_movement_gameplay_event(event_data:Dictionary)->void:_execute(event_data)
func resolve_for_test(event_data:Dictionary):return _execute(event_data)
func _execute(event:Dictionary,direct_target=null):
	var resolution=_resolver.resolve(event)
	if not resolution.triggered:return resolution
	var targets:Array[Node]=[]
	if direct_target!=null:targets.append(direct_target)
	else:targets=_targets(_radius(resolution.effects))
	var values:=_values(resolution.effects)
	var affected:Array[String]=[]
	for target in targets:
		if not target.has_method("apply_damage") or target.is_dead():continue
		var direction:Vector2=values["direction"]
		if direction.is_zero_approx() and event["type"]=="dash_passed_enemy":direction=Vector2(_player.latest_snapshot().facing,0)
		var damage_result=target.apply_damage(Packet.create(resolution.artifact_id,values["tags"],direction,values["damage"],values["impulse"],values["stun"],resolution.action_id))
		if damage_result.accepted:affected.append(str(target.instance_key))
	var emitted:Dictionary=resolution.to_dictionary();emitted["affectedTargets"]=affected;artifact_triggered.emit(emitted)
	return resolution
func _targets(radius:float)->Array[Node]:
	var result:Array[Node]=[]
	if radius<=0 or not _enemies.is_valid():return result
	for enemy in _enemies.call():
		if enemy.global_position.distance_to(_player.global_position)<=radius*PIXELS_PER_UNIT:result.append(enemy)
	return result
func _radius(effects:Array[Dictionary])->float:
	var result:=0.0
	for effect in effects:
		if effect.has("radius"):result=maxf(result,float(effect["radius"]))
	return result
func _values(effects:Array[Dictionary])->Dictionary:
	var damage:=0;var impulse:=0.0;var stun:=0.0;var direction:=Vector2.ZERO;var tags:Array[String]=[]
	for effect in effects:
		damage+=int(effect.get("damage",0))
		for tag in effect.get("tags",[]):
			if str(tag) not in tags:tags.append(str(tag))
		if effect["type"]=="launch":impulse=maxf(impulse,float(effect.get("impulse",0)));stun=maxf(stun,float(effect.get("durationSeconds",0)));direction=Vector2.UP
		elif effect["type"]=="stun":stun=maxf(stun,float(effect.get("durationSeconds",0)))
	return {"damage":damage,"impulse":impulse,"stun":stun,"direction":direction,"tags":tags}
