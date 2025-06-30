# script/components/TagComponent.gd
class_name TagComponent
extends BaseComponent

var tags: Dictionary = {}
var _initial_tags: Array = []
var _subscribed_to_day_started: bool = false # Flag to prevent duplicate subscriptions

# This function is called automatically by the parent BaseComponent's initialize method.
func _load_data(data: Dictionary) -> void:
	tags.clear()
	_initial_tags.clear()
	
	# Load tags from the definition file first.
	var initial_tags_from_def = data.get("tags", [])
	if initial_tags_from_def is Array and not initial_tags_from_def.is_empty():
		_initial_tags = initial_tags_from_def.duplicate()
		for tag_id in _initial_tags:
			if tag_id is String:
				add_tag(tag_id)
	
	# Load any additional tags from saved data.
	if data.has("saved_data"):
		var saved_tags = data.get("saved_data", {}).get("tags", [])
		if saved_tags is Array:
			for tag_id in saved_tags:
				if not has_tag(tag_id):
					add_tag(tag_id)

	print("TagComponent on '%s' initialized with tags: %s" % [_entity_name, str(tags.keys())])
	
	# --- THIS IS THE FIX ---
	# Use the internal flag to ensure we only subscribe once.
	if not _subscribed_to_day_started:
		EventSystem.subscribe("day_started", Callable(self, "_on_day_started"))
		_subscribed_to_day_started = true
	# --- END OF FIX ---

# Replaces the parent's persistence function.
func get_persistent_data() -> Dictionary:
	var dynamic_tags = []
	for tag_id in tags:
		if not tag_id in _initial_tags:
			dynamic_tags.append(tag_id)
	return { "tags": dynamic_tags } if not dynamic_tags.is_empty() else {}

func add_tag(tag_id: String) -> void:
	if has_tag(tag_id):
		return

	if TagRegistry.is_tag_defined(tag_id):
		tags[tag_id] = TagRegistry.get_tag_definition(tag_id)
	else:
		tags[tag_id] = {}
	
	print("Added tag '%s' to entity '%s'." % [tag_id, _entity_name])

func _on_day_started(_payload: Dictionary):
	var tags_to_remove = []
	for tag_id in tags:
		if tag_id.begins_with("event_triggered/"):
			tags_to_remove.append(tag_id)
			
	if not tags_to_remove.is_empty():
		print("New day. Removing daily tags: %s" % str(tags_to_remove))
		for tag_id in tags_to_remove:
			if tags.has(tag_id):
				tags.erase(tag_id)

func has_tag(tag_id: String) -> bool:
	return tags.has(tag_id)

func get_tag_data(tag_id: String) -> Dictionary:
	return tags.get(tag_id, {})

func find_first_effect(effect_type: String) -> Dictionary:
	for tag_id in tags:
		var tag_data = tags.get(tag_id, {})
		if tag_data.has("effects"):
			for effect in tag_data["effects"]:
				if effect.get("type") == effect_type:
					return effect
	return {}
