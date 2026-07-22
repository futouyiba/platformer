class_name ContentValidator
extends RefCounted

const MOVEMENT_REQUIRED := ["schemaVersion", "id", "fixedTickHz", "maxRunSpeed", "groundAcceleration", "groundDeceleration", "airAcceleration", "airDeceleration", "jumpSpeed", "doubleJumpSpeed", "gravity", "fastFallGravity", "dashSpeed", "dashDurationSeconds", "dashCooldownSeconds", "coyoteTimeSeconds", "jumpBufferSeconds", "wallSlideMaxSpeed", "wallGraceSeconds", "gestureDeadZoneNormalized", "flickWindowSeconds", "flickThresholdNormalized", "directionDominanceRatio"]
const ARTIFACT_SLOTS := ["horizontal", "upward", "downward"]
const SLOT_TRIGGERS := {"horizontal":"dash_passed_enemy", "upward":"double_jump_started", "downward":"hard_landing"}
const EFFECT_TYPES := ["line_damage", "area_damage", "launch", "stun"]
const LAYER_NAMES := ["World", "Player", "Enemy", "Trigger", "Projectile"]

func validate_movement(data: Variant) -> Array[String]:
	var errors: Array[String] = []
	if not data is Dictionary: return ["$: expected object"]
	_require(data, MOVEMENT_REQUIRED, "$", errors)
	if not errors.is_empty(): return errors
	for field in MOVEMENT_REQUIRED.slice(2):
		if not data[field] is float and not data[field] is int: errors.append("$.%s: expected number" % field)
		elif float(data[field]) <= 0.0: errors.append("$.%s: must be greater than zero" % field)
	if float(data["gestureDeadZoneNormalized"]) >= 1.0: errors.append("$.gestureDeadZoneNormalized: must be less than 1")
	if float(data["flickThresholdNormalized"]) >= 1.0: errors.append("$.flickThresholdNormalized: must be less than 1")
	return errors

func validate_artifacts(data: Variant) -> Array[String]:
	var errors: Array[String] = []
	if not data is Dictionary: return ["$: expected object"]
	_require(data, ["schemaVersion", "contentVersion", "artifacts"], "$", errors)
	if not data.has("artifacts") or not data["artifacts"] is Array: return errors + ["$.artifacts: expected array"]
	var seen: Dictionary = {}
	for index in data["artifacts"].size():
		var path := "$.artifacts[%d]" % index
		var artifact: Variant = data["artifacts"][index]
		if not artifact is Dictionary: errors.append("%s: expected object" % path); continue
		_require(artifact, ["id", "slot", "trigger", "effects"], path, errors)
		if not artifact.has("slot"): continue
		if artifact["slot"] not in ARTIFACT_SLOTS: errors.append("%s.slot: unknown enum '%s'" % [path, artifact["slot"]])
		elif seen.has(artifact["slot"]): errors.append("%s.slot: duplicate main slot" % path)
		else: seen[artifact["slot"]] = true
		if artifact.get("trigger") is Dictionary:
			var trigger: Dictionary = artifact["trigger"]
			_require(trigger, ["event", "maxPerAction"], "%s.trigger" % path, errors)
			if trigger.get("maxPerAction", 0) != 1: errors.append("%s.trigger.maxPerAction: must equal 1" % path)
			if artifact["slot"] in SLOT_TRIGGERS and trigger.get("event") != SLOT_TRIGGERS[artifact["slot"]]: errors.append("%s.trigger.event: does not match slot" % path)
			for key in trigger.get("conditions", {}):
				if key not in ["minimumFallSpeed", "minimumAirTimeSeconds"]: errors.append("%s.trigger.conditions.%s: unknown condition" % [path, key])
		elif artifact.has("trigger"): errors.append("%s.trigger: expected object" % path)
		if artifact.get("effects") is Array and not artifact["effects"].is_empty():
			for effect_index in artifact["effects"].size():
				var effect: Variant = artifact["effects"][effect_index]
				var effect_path := "%s.effects[%d]" % [path, effect_index]
				if not effect is Dictionary: errors.append("%s: expected object" % effect_path); continue
				if effect.get("type") not in EFFECT_TYPES: errors.append("%s.type: unknown enum" % effect_path)
				if effect.has("damage") and float(effect["damage"]) < 0.0: errors.append("%s.damage: must be zero or greater" % effect_path)
		else: errors.append("%s.effects: expected non-empty array" % path)
	for slot in ARTIFACT_SLOTS:
		if not seen.has(slot): errors.append("$.artifacts: required main slot '%s' missing" % slot)
	return errors

func validate_enemy(data: Variant) -> Array[String]:
	var errors: Array[String] = []
	if not data is Dictionary: return ["$: expected object"]
	_require(data, ["schemaVersion", "contentVersion", "enemies"], "$", errors)
	if not data.has("enemies") or not data["enemies"] is Array: return errors + ["$.enemies: expected array"]
	for index in data["enemies"].size():
		var path := "$.enemies[%d]" % index
		var enemy: Variant = data["enemies"][index]
		if not enemy is Dictionary: errors.append("%s: expected object" % path); continue
		_require(enemy, ["id", "health", "mass", "canBeDashedThrough", "canBeLaunched", "stunResistance", "behavior"], path, errors)
		if enemy.has("health") and int(enemy["health"]) <= 0: errors.append("%s.health: must be greater than zero" % path)
		if enemy.has("mass") and float(enemy["mass"]) <= 0.0: errors.append("%s.mass: must be greater than zero" % path)
	return errors

func validate_collision_layers(data: Variant) -> Array[String]:
	var errors: Array[String] = []
	if not data is Dictionary: return ["$: expected object"]
	_require(data, ["schemaVersion", "layers"], "$", errors)
	if not data.has("layers") or not data["layers"] is Array: return errors + ["$.layers: expected array"]
	var seen: Dictionary = {}
	for index in data["layers"].size():
		var layer: Variant = data["layers"][index]
		var path := "$.layers[%d]" % index
		if not layer is Dictionary: errors.append("%s: expected object" % path); continue
		_require(layer, ["name", "bit", "collisionLayer", "collisionMask"], path, errors)
		if layer.get("name") not in LAYER_NAMES: errors.append("%s.name: unknown enum" % path)
		elif seen.has(layer["name"]): errors.append("%s.name: duplicate" % path)
		else: seen[layer["name"]] = true
		if int(layer.get("bit", 0)) < 1 or int(layer.get("bit", 0)) > 5: errors.append("%s.bit: must be between 1 and 5" % path)
	for name in LAYER_NAMES:
		if not seen.has(name): errors.append("$.layers: required layer '%s' missing" % name)
	return errors

func _require(data: Dictionary, keys: Array, path: String, errors: Array[String]) -> void:
	for key in keys:
		if not data.has(key): errors.append("%s.%s: required field missing" % [path, key])
