extends SceneTree
const Intent=preload("res://game/core/input/input_intent.gd")
const Packet=preload("res://game/core/combat/damage_packet.gd")
var _hits:Array[String]=[]
func _init()->void:call_deferred("_run")
func _run()->void:
	var failures:Array[String]=[];var packed:PackedScene=load("res://game/scenes/movement_sandbox.tscn")
	if packed==null:failures.append("scene load failed")
	else:
		var sandbox=packed.instantiate();root.add_child(sandbox);await process_frame;var player=sandbox.get_node("Player")
		for tick in 30:await physics_frame;await process_frame
		if not player.has_safe_respawn():failures.append("M3 safe respawn not recorded")
		else:
			var safe:Vector2=player.safe_respawn_position();player.global_position+=Vector2(0,100)
			if not player.respawn_to_last_safe() or not player.global_position.is_equal_approx(safe):failures.append("M3 safe respawn restore")
		player.dash_target_crossed.connect(_on_hit);player.queue_intent(Intent.create(Intent.Kind.DASH_REQUEST,Vector2.RIGHT,1,"test",0));await physics_frame;await process_frame
		for tick in 2:await physics_frame;await process_frame
		if _hits.size()!=2:failures.append("M3 dash targets expected 2 got %d"%_hits.size())
		var one=sandbox.get_node("World/Enemies/TrainingEnemy01");var two=sandbox.get_node("World/Enemies/TrainingEnemy02")
		if one.current_health()!=2 or two.current_health()!=2:failures.append("M5 blade damage")
		var tags:Array[String]=["test"];var packet=Packet.create("harness",tags,Vector2.RIGHT,1,2,.5,99);var first=one.apply_damage(packet);var duplicate=one.apply_damage(packet)
		if not first.accepted or duplicate.accepted or one.current_health()!=1:failures.append("M4 damage duplicate")
		var system=sandbox.get_node("Systems/ArtifactSystem");var wind=system.resolve_for_test({"type":"double_jump_started","actionId":200})
		if not wind.triggered or two.current_health()!=1 or two.last_damage_result().knockback_velocity.y>=0:failures.append("M5 wind")
		var ordinary=system.resolve_for_test({"type":"hard_landing","actionId":201,"fallSpeed":8,"airTimeSeconds":.4})
		if ordinary.triggered:failures.append("M5 ordinary landing")
		var star=system.resolve_for_test({"type":"hard_landing","actionId":202,"fallSpeed":14,"airTimeSeconds":.4})
		if not star.triggered or not two.is_dead():failures.append("M5 starfall")
		sandbox.queue_free()
	print(JSON.stringify({"suite":"integration","ok":failures.is_empty(),"failures":failures}));quit(0 if failures.is_empty() else 1)
func _on_hit(target,action_id:int)->void:_hits.append("%s:%d"%[target.instance_key,action_id])
