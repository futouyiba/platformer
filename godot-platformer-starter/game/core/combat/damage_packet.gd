class_name DamagePacket
extends RefCounted
var source_id:String
var tags:Array[String]=[]
var direction:=Vector2.ZERO
var damage:=0
var impulse:=0.0
var stun_seconds:=0.0
var action_id:=0
static func create(source:String,packet_tags:Array[String],packet_direction:Vector2,amount:int,packet_impulse:float,stun:float,action:int)->DamagePacket:
	var packet:=DamagePacket.new();packet.source_id=source;packet.tags=packet_tags.duplicate();packet.direction=packet_direction.normalized() if not packet_direction.is_zero_approx() else Vector2.ZERO;packet.damage=maxi(0,amount);packet.impulse=maxf(0,packet_impulse);packet.stun_seconds=maxf(0,stun);packet.action_id=action;return packet
func deduplication_key()->String:return "%s:%d"%[source_id,action_id]
