class_name InputTraceDebug
extends Control
var _origin:=Vector2.ZERO
var _current:=Vector2.ZERO
var _dead_zone:=0.0
var _active:=false
var _text:="intent: waiting"
func observe_sample(sample,dead_zone:float)->void:
	_current=Vector2(sample.position_normalized.x*size.x,sample.position_normalized.y*size.y);_dead_zone=dead_zone*minf(size.x,size.y)
	if sample.phase==0:_origin=_current;_active=true
	elif sample.phase==2:_active=false
	queue_redraw()
func observe_intent(intent)->void:_text="intent: %s  confidence: %.2f"%[intent.kind_name(),intent.confidence];queue_redraw()
func intent_text()->String:return _text
func _draw()->void:
	if not _active:return
	draw_arc(_origin,_dead_zone,0,TAU,48,Color(0.9,0.86,0.74,0.55),1.5);draw_line(_origin,_current,Color(0.9,0.86,0.74,0.9),3);draw_circle(_current,7,Color(0.78,0.18,0.12,0.95))
