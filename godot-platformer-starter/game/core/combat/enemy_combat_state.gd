class_name EnemyCombatState
extends RefCounted
const Result=preload("res://game/core/combat/damage_result.gd")
var content_id:String
var max_health:=1
var health:=1
var mass:=1.0
var stun_resistance:=0.0
var knockback_velocity:=Vector2.ZERO
var stun_remaining_seconds:=0.0
var _resolved:Dictionary={}
func configure(data:Dictionary)->void:content_id=str(data["id"]);max_health=int(data["health"]);health=max_health;mass=float(data["mass"]);stun_resistance=float(data["stunResistance"]);knockback_velocity=Vector2.ZERO;stun_remaining_seconds=0;_resolved.clear()
func apply_damage(packet:DamagePacket):
	var result:=Result.new();result.health_before=health;result.health_after=health
	if is_dead():result.events.append("damage_ignored_dead");return result
	var key:=packet.deduplication_key()
	if packet.action_id>0 and _resolved.has(key):result.events.append("damage_ignored_duplicate");return result
	if packet.action_id>0:_resolved[key]=true
	result.accepted=true;result.applied_damage=mini(packet.damage,health);health-=result.applied_damage;result.health_after=health;result.stun_seconds=packet.stun_seconds*(1-stun_resistance);stun_remaining_seconds=maxf(stun_remaining_seconds,result.stun_seconds);knockback_velocity=packet.direction*(packet.impulse/mass);result.knockback_velocity=knockback_velocity;result.events.append("damage_applied")
	if result.stun_seconds>0:result.events.append("stun_started")
	if health<=0:result.died=true;result.events.append("enemy_died")
	return result
func step(delta:float)->void:stun_remaining_seconds=maxf(0,stun_remaining_seconds-delta);knockback_velocity=Vector2.ZERO if is_zero_approx(stun_remaining_seconds) else knockback_velocity
func is_stunned()->bool:return stun_remaining_seconds>0
func is_dead()->bool:return health<=0
