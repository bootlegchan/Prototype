# script/components/TagComponent.gd
class_name TagComponent
extends BaseComponent

var tags: Dictionary = {}
var _initial_tags: Array = []
var _subscribed_to_day_started: bool = false # Flag to prevent duplicate subscriptions

func _load_data(data: Dictionary) -> void:
	# --- DEBUG PRINT ---
	print("TagComponent on '%s': _load_data called with data: %s" % [_entity_name, data])
	# --- END DEBUG PRINT ---
	tags.clear()
	_initial_tags.clear()

	# Load tags from the definition file first.
	var initial_tags_from_def = data.get("tags", [])
	# --- DEBUG PRINT ---
	print("TagComponent on '%s': Found %d initial tags in data." % [_entity_name, initial_tags_from_def.size() if initial_tags_from_def is Array else 0])
	# --- END DEBUG PRINT ---
	if initial_tags_from_def is Array and not initial_tags_from_def.is_empty():
		_initial_tags = initial_tags_from_def.duplicate()
		for tag_id in _initial_tags:
			if tag_id is String:
				add_tag(tag_id)
			else:
				# --- DEBUG PRINT ---
				push_warning("TagComponent on '%s': Non-string tag_id '%s' in initial_tags_from_def." % [_entity_name, str(tag_id)])
				# --- END DEBUG PRINT ---


	# Load any additional tags from saved data.
	if data.has("saved_data"):
		var saved_tags = data.get("saved_data", {}).get("tags", [])
		# --- DEBUG PRINT ---
		print("TagComponent on '%s': Found %d saved tags in data." % [_entity_name, saved_tags.size() if saved_tags is Array else 0])
		# --- END DEBUG PRINT ---
		if saved_tags is Array:
			for tag_id in saved_tags:
				if not has_tag(tag_id):
					add_tag(tag_id)
				else:
					# --- DEBUG PRINT ---
					print("TagComponent on '%s': Saved tag '%s' already exists." % [_entity_name, tag_id])
					# --- END DEBUG PRINT ---


	print("TagComponent on '%s' _load_data finished. Current tags: %s" % [_entity_name, str(tags.keys())])


# This function is called after all components are loaded.
func _post_initialize() -> void:
	# --- DEBUG PRINT ---
	print("TagComponent on '%s': _post_initialize called." % _entity_name)
	# --- END DEBUG PRINT ---
	# Subscribe to the day_started signal to handle daily tag removal.
	# We use the internal flag to ensure we only subscribe once.
	if not _subscribed_to_day_started:
		EventSystem.subscribe("day_started", Callable(self, "_on_day_started"))
		_subscribed_to_day_started = true
		# --- DEBUG PRINT ---
		print("TagComponent on '%s': Subscribed to day_started event." % _entity_name)
		# --- END DEBUG PRINT ---


func get_persistent_data() -> Dictionary:
	# --- DEBUG PRINT ---
	print("TagComponent on '%s': get_persistent_data called. Current tags: %s" % [_entity_name, str(tags.keys())])
	# --- END DEBUG PRINT ---
	var dynamic_tags = []
	for tag_id in tags:
		if not tag_id in _initial_tags:
			dynamic_tags.append(tag_id)
			# --- DEBUG PRINT ---
			print("TagComponent on '%s': Saving dynamic tag '%s'." % [_entity_name, tag_id])
			# --- END DEBUG PRINT ---
	# --- DEBUG PRINT ---
	print("TagComponent on '%s': get_persistent_data returning dynamic tags: %s" % [_entity_name, str(dynamic_tags)])
	# --- END DEBUG PRINT ---
	return { "tags": dynamic_tags } if not dynamic_tags.is_empty() else {}

func add_tag(tag_id: String) -> void:
	# --- DEBUG PRINT ---
	print("TagComponent on '%s': add_tag called for '%s'." % [_entity_name, tag_id])
	# --- END DEBUG PRINT ---
	if has_tag(tag_id):
		# --- DEBUG PRINT ---
		print("TagComponent on '%s': Tag '%s' already exists. Skipping add." % [_entity_name, tag_id])
		# --- END DEBUG PRINT ---
		return

	if TagRegistry.is_tag_defined(tag_id):
		tags[tag_id] = TagRegistry.get_tag_definition(tag_id)
		# --- DEBUG PRINT ---
		print("TagComponent on '%s': Tag '%s' found in registry, added to tags." % [_entity_name, tag_id])
		# --- END DEBUG PRINT ---
	else:
		tags[tag_id] = {}
		# --- DEBUG PRINT ---
		print("TagComponent on '%s': Tag '%s' not found in registry, added as empty tag." % [_entity_name, tag_id])
		# --- END DEBUG PRINT ---

	# --- DEBUG PRINT ---
	print("TagComponent on '%s': Tag '%s' added. Current tags: %s" % [_entity_name, tag_id, str(tags.keys())])
	# --- END DEBUG PRINT ---


func _on_day_started(_payload: Dictionary):
	# --- DEBUG PRINT ---
	print("TagComponent on '%s': _on_day_started called. Checking for daily tags to remove." % _entity_name)
	# --- END DEBUG PRINT ---
	var tags_to_remove = []
	for tag_id in tags:
		if tag_id.begins_with("event_triggered/"):
			tags_to_remove.append(tag_id)

	if not tags_to_remove.is_empty():
		print("New day. Removing daily tags: %s" % str(tags_to_remove))
		for tag_id in tags_to_remove:
			if tags.has(tag_id):
				tags.erase(tag_id)
				# --- DEBUG PRINT ---
				print("TagComponent on '%s': Removed daily tag '%s'." % [_entity_name, tag_id])
				# --- END DEBUG PRINT ---

func has_tag(tag_id: String) -> bool:
	# --- DEBUG PRINT ---
	# print("TagComponent on '%s': has_tag called for '%s'." % [_entity_name, tag_id]) # Very verbose
	# --- END DEBUG PRINT ---
	return tags.has(tag_id)

func get_tag_data(tag_id: String) -> Dictionary:
	# --- DEBUG PRINT ---
	# print("TagComponent on '%s': get_tag_data called for '%s'." % [_entity_name, tag_id]) # Very verbose
	# --- END DEBUG PRINT ---
	return tags.get(tag_id, {})

func find_first_effect(effect_type: String) -> Dictionary:
	# --- DEBUG PRINT ---
	# print("TagComponent on '%s': find_first_effect called for type '%s'." % [_entity_name, effect_type]) # Very verbose
	# --- END DEBUG PRINT ---
	for tag_id in tags:
		var tag_data = tags.get(tag_id, {})
		if tag_data.has("effects"):
			for effect in tag_data["effects"]:
				if effect.get("type") == effect_type:
					# --- DEBUG PRINT ---
					# print("TagComponent on '%s': Found effect of type '%s' from tag '%s'." % [_entity_name, effect_type, tag_id]) # Very verbose
					# --- END DEBUG PRINT ---
					return effect
	# --- DEBUG PRINT ---
	# print("TagComponent on '%s': No effect of type '%s' found." % [_entity_name, effect_type]) # Very verbose
	# --- END DEBUG PRINT ---
	return {}
