class_name ArtifactResolution
extends RefCounted
var triggered:=false
var artifact_id:String
var slot:String
var event_type:String
var action_id:=0
var effects:Array[Dictionary]=[]
var reason:String
func to_dictionary()->Dictionary:return {"triggered":triggered,"artifactId":artifact_id,"slot":slot,"eventType":event_type,"actionId":action_id,"effects":effects.duplicate(true),"reason":reason}
