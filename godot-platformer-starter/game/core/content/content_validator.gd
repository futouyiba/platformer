class_name ContentValidator
extends RefCounted

const MOVEMENT_REQUIRED := ["schemaVersion", "id", "fixedTickHz", "maxRunSpeed", "groundAcceleration", "groundDeceleration", "airAcceleration", "airDeceleration", "jumpSpeed", "doubleJumpSpeed", "gravity", "fastFallGravity", "dashSpeed", "dashDurationSeconds", "dashCooldownSeconds", "coyoteTimeSeconds", "jumpBufferSeconds", "wallSlideMaxSpeed", "wallGraceSeconds", "gestureDeadZoneNormalized", "flickWindowSeconds", "flickThresholdNormalized", "directionDominanceRatio"]
const ARTIFACT_SLOTS := ["horizontal", "upward", "downward"]
const SLOT_TRIGGERS := {"horizontal":"dash_passed_enemy", "upward":"double_jump_started", "downward":"hard_landing"}
const EFFECT_TYPES := ["line_damage", "area_damage", "launch", "stun"]
const LAYER_NAMES := ["World", "Player", "Enemy", "Trigger", "Projectile"]
const ZONE_ACTIONS := {
	"A":"dash_traversal",
	"B":"jump_double_jump",
	"C":"wind_ring",
	"D":"fast_fall",
	"E":"wall_slide",
	"F":"review_reset"
}

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

func validate_layout(data: Variant, enemy_bundle: Variant = {}) -> Array[String]:
	var errors: Array[String] = []
	if not data is Dictionary: return ["$: expected object"]
	_require(data, ["schemaVersion", "contentVersion", "worldBounds", "playerSpawn", "zones"], "$", errors)
	if not data.get("worldBounds") is Dictionary: errors.append("$.worldBounds: expected object")
	else: _validate_rect(data["worldBounds"], "$.worldBounds", errors)
	_validate_point(data.get("playerSpawn"), "$.playerSpawn", errors)
	if not data.get("zones") is Array: return errors + ["$.zones: expected array"]
	var zones: Array = data["zones"]
	if zones.size() != ZONE_ACTIONS.size(): errors.append("$.zones: expected exactly six zones")
	var known_enemy_ids: Dictionary = {}
	if enemy_bundle is Dictionary and enemy_bundle.get("enemies") is Array:
		for definition in enemy_bundle["enemies"]:
			if definition is Dictionary and definition.has("id"): known_enemy_ids[str(definition["id"])] = true
	var seen_zones: Dictionary = {}
	var expected_x := float(data.get("worldBounds", {}).get("x", 0.0))
	for index in zones.size():
		var path := "$.zones[%d]" % index
		var zone: Variant = zones[index]
		if not zone is Dictionary: errors.append("%s: expected object" % path); continue
		_require(zone, ["id", "name", "prompt", "primaryAction", "color", "bounds", "respawn", "platforms", "enemies"], path, errors)
		var zone_id := str(zone.get("id", ""))
		if zone_id not in ZONE_ACTIONS: errors.append("%s.id: expected one of A-F" % path)
		elif seen_zones.has(zone_id): errors.append("%s.id: duplicate zone '%s'" % [path, zone_id])
		else:
			seen_zones[zone_id] = true
			if zone.get("primaryAction") != ZONE_ACTIONS[zone_id]: errors.append("%s.primaryAction: does not match zone contract" % path)
		if str(zone.get("prompt", "")).is_empty(): errors.append("%s.prompt: must not be empty" % path)
		if not str(zone.get("color", "")).begins_with("#"): errors.append("%s.color: expected hex color" % path)
		if zone.get("bounds") is Dictionary:
			_validate_rect(zone["bounds"], "%s.bounds" % path, errors)
			if not is_equal_approx(float(zone["bounds"].get("x", 0.0)), expected_x): errors.append("%s.bounds.x: zones must be contiguous and ordered A-F" % path)
			expected_x = float(zone["bounds"].get("x", 0.0)) + float(zone["bounds"].get("width", 0.0))
		else: errors.append("%s.bounds: expected object" % path)
		_validate_point(zone.get("respawn"), "%s.respawn" % path, errors)
		_validate_platforms(zone.get("platforms"), "%s.platforms" % path, errors)
		_validate_layout_enemies(zone.get("enemies"), "%s.enemies" % path, known_enemy_ids, errors)
	for zone_id in ZONE_ACTIONS:
		if not seen_zones.has(zone_id): errors.append("$.zones: required zone '%s' missing" % zone_id)
	if data.get("worldBounds") is Dictionary:
		var world_end := float(data["worldBounds"].get("x", 0.0)) + float(data["worldBounds"].get("width", 0.0))
		if not is_equal_approx(expected_x, world_end): errors.append("$.zones: zone coverage must match world width")
	return errors

func _validate_rect(value: Variant, path: String, errors: Array[String]) -> void:
	if not value is Dictionary: errors.append("%s: expected object" % path); return
	_require(value, ["x", "y", "width", "height"], path, errors)
	for field in ["x", "y", "width", "height"]:
		if value.has(field) and not value[field] is float and not value[field] is int: errors.append("%s.%s: expected number" % [path, field])
	if float(value.get("width", 0.0)) <= 0.0: errors.append("%s.width: must be greater than zero" % path)
	if float(value.get("height", 0.0)) <= 0.0: errors.append("%s.height: must be greater than zero" % path)

func _validate_point(value: Variant, path: String, errors: Array[String]) -> void:
	if not value is Array or value.size() != 2: errors.append("%s: expected [x, y]" % path); return
	for coordinate in value:
		if not coordinate is float and not coordinate is int: errors.append("%s: coordinates must be numbers" % path); return

func _validate_platforms(value: Variant, path: String, errors: Array[String]) -> void:
	if not value is Array or value.is_empty(): errors.append("%s: expected non-empty array" % path); return
	var seen: Dictionary = {}
	for index in value.size():
		var platform: Variant = value[index]
		var item_path := "%s[%d]" % [path, index]
		if not platform is Dictionary: errors.append("%s: expected object" % item_path); continue
		_require(platform, ["id", "position", "size"], item_path, errors)
		var item_id := str(platform.get("id", ""))
		if item_id.is_empty() or seen.has(item_id): errors.append("%s.id: must be unique and non-empty" % item_path)
		else: seen[item_id] = true
		_validate_point(platform.get("position"), "%s.position" % item_path, errors)
		_validate_point(platform.get("size"), "%s.size" % item_path, errors)
		if platform.get("size") is Array and platform["size"].size() == 2:
			if float(platform["size"][0]) <= 0.0 or float(platform["size"][1]) <= 0.0: errors.append("%s.size: dimensions must be greater than zero" % item_path)

func _validate_layout_enemies(value: Variant, path: String, known_ids: Dictionary, errors: Array[String]) -> void:
	if not value is Array: errors.append("%s: expected array" % path); return
	var seen: Dictionary = {}
	for index in value.size():
		var enemy: Variant = value[index]
		var item_path := "%s[%d]" % [path, index]
		if not enemy is Dictionary: errors.append("%s: expected object" % item_path); continue
		_require(enemy, ["id", "instanceKey", "contentId", "position"], item_path, errors)
		var item_id := str(enemy.get("id", ""))
		if item_id.is_empty() or seen.has(item_id): errors.append("%s.id: must be unique and non-empty" % item_path)
		else: seen[item_id] = true
		if not known_ids.is_empty() and not known_ids.has(str(enemy.get("contentId", ""))): errors.append("%s.contentId: unknown enemy definition" % item_path)
		_validate_point(enemy.get("position"), "%s.position" % item_path, errors)

func _require(data: Dictionary, keys: Array, path: String, errors: Array[String]) -> void:
	for key in keys:
		if not data.has(key): errors.append("%s.%s: required field missing" % [path, key])
