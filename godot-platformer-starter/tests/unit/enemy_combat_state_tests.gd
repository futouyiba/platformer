extends RefCounted
const Packet=preload("res://game/core/combat/damage_packet.gd")
const Enemy=preload("res://game/core/combat/enemy_combat_state.gd")
func run()->Array[String]:
	var f:Array[String]=[];var e:=Enemy.new();e.configure({"id":"enemy_training_soldier","health":3,"mass":1.0,"stunResistance":0.0});var tags:Array[String]=["dash","through"];var p=Packet.create("blade",tags,Vector2.RIGHT,1,2,.5,17);var a=e.apply_damage(p);_assert(a.accepted and e.health==2 and a.knockback_velocity.x==2 and e.is_stunned(),"M4 damage/knockback/stun",f);var duplicate=e.apply_damage(p);_assert(not duplicate.accepted and e.health==2,"M4 duplicate rejection",f);var lethal_tags:Array[String]=["damage"];var lethal=e.apply_damage(Packet.create("test",lethal_tags,Vector2.LEFT,3,0,0,18));_assert(lethal.died and e.is_dead(),"M4 death",f);return f
func _assert(condition:bool,message:String,failures:Array[String])->void:if not condition:failures.append(message)
