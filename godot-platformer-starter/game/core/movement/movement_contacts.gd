class_name MovementContacts
extends RefCounted
var grounded := false
var ground_normal := Vector2.UP
var wall_contact := false
var wall_normal := Vector2.ZERO
var ceiling_contact := false
var ceiling_normal := Vector2.DOWN

static func create(is_grounded := false, has_wall := false, contact_wall_normal := Vector2.ZERO, has_ceiling := false, contact_ground_normal := Vector2.UP, contact_ceiling_normal := Vector2.DOWN) -> MovementContacts:
	var contacts := MovementContacts.new()
	contacts.grounded=is_grounded; contacts.wall_contact=has_wall; contacts.wall_normal=contact_wall_normal; contacts.ceiling_contact=has_ceiling; contacts.ground_normal=contact_ground_normal; contacts.ceiling_normal=contact_ceiling_normal
	return contacts
