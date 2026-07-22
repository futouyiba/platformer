class_name ArtifactTriggerResolver
extends RefCounted
const Resolution=preload("res://game/core/artifacts/artifact_resolution.gd")
var _by_trigger:Dictionary={}
var _selected:Dictionary={}
var _resolved:Dictionary={}
func configure(bundle:Dictionary)->void:
	reset()
	for artifact in bundle["artifacts"]:
		var event:String=artifact["trigger"]["event"]
		if not _by_trigger.has(event):_by_trigger[event]=[]
		_by_trigger[event].append(artifact.duplicate(true))
func reset()->void:_by_trigger.clear();_selected.clear();_resolved.clear()
func resolve(event_data:Dictionary):
	var result:=Resolution.new();result.event_type=str(event_data.get("type",""));result.action_id=int(event_data.get("actionId",0))
	if result.action_id<=0:result.reason="invalid_action_id";return result
	if not _by_trigger.has(result.event_type):result.reason="no_artifact_for_event";return result
	for artifact in _by_trigger[result.event_type]:
		if not _conditions(artifact["trigger"].get("conditions",{}),event_data):continue
		var id:String=artifact["id"]
		if _selected.has(result.action_id) and _selected[result.action_id]!=id:result.reason="main_artifact_already_selected";return result
		var target:=str(event_data.get("targetKey","__action__"))
		var key:="%s:%d:%s"%[id,result.action_id,target]
		if _resolved.has(key):result.reason="duplicate_target_for_action";return result
		_selected[result.action_id]=id;_resolved[key]=true;result.triggered=true;result.artifact_id=id;result.slot=artifact["slot"];result.effects.assign(artifact["effects"].duplicate(true));result.reason="triggered";return result
	result.reason="conditions_not_met";return result
func _conditions(conditions:Dictionary,event:Dictionary)->bool:
	if conditions.has("minimumFallSpeed") and float(event.get("fallSpeed",0))<float(conditions["minimumFallSpeed"]):return false
	if conditions.has("minimumAirTimeSeconds") and float(event.get("airTimeSeconds",0))<float(conditions["minimumAirTimeSeconds"]):return false
	return true
