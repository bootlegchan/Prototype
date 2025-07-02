class_name TagComponent
extends BaseComponent

var tags: Dictionary = {}
var _initial_tags: Array = []
var _subscribed_to_day_started: bool = false

func _load_data(data: Dictionary) -> void:
	Debug.post("_load_data called with data: %s" % data, "TagComponent on '%s'" % _entity_name)
	tags.clear()
	_initial_tags.clear()

	var initial_tags_from_def = data.get("tags", [])
	Debug.post("Found %d initial tags in data." % initial_tags_from_def.size(), "TagComponent on '%s'" % _entity_name)
	if initial_tags_from_def is Array and not initial_tags_from_def.is_empty():
		_initial_tags = initial_tags_from_def.duplicate()
		for tag_id in _initial_tags:
			if tag_id is String:
				add_tag(tag_id)
			else:
				push_warning("TagComponent on '%s': Non-string tag_id '%s' in initial_tags_from_def." % [_entity_name, str(tag_id)])

	if data.has("saved_data"):
		var saved_tags = data.get("saved_data", {}).get("tags", [])
		Debug.post("Found %d saved tags in data." % saved_tags.size(), "TagComponent on '%s'" % _entity_name)
		if saved_tags is Array:
			for tag_id in saved_tags:
				if not has_tag(tag_id):
					add_tag(tag_id)
				else:
					Debug.post("Saved tag '%s' already exists." % tag_id, "TagComponent on '%s'" % _entity_name)

	Debug.post("_load_data finished. Current tags: %s" % str(tags.keys()), "TagComponent on '%s'" % _entity_name)

func _post_initialize() -> void:
	Debug.post("_post_initialize called.", "TagComponent on '%s'" % _entity_name)
	if not _subscribed_to_day_started:
		EventSystem.subscribe("day_started", Callable(self, "_on_day_started"))
		_subscribed_to_day_started = true
		Debug.post("Subscribed to day_started event.", "TagComponent on '%s'" % _entity_name)

func get_persistent_data() -> Dictionary:
	Debug.post("get_persistent_data called. Current tags: %s" % str(tags.keys()), "TagComponent on '%s'" % _entity_name)
	var dynamic_tags = []
	for tag_id in tags:
		if not tag_id in _initial_tags:
			dynamic_tags.append(tag_id)
			Debug.post("Saving dynamic tag '%s'." % tag_id, "TagComponent on '%s'" % _entity_name)
	Debug.post("get_persistent_data returning dynamic tags: %s" % str(dynamic_tags), "TagComponent on '%s'" % _entity_name)
	return { "tags": dynamic_tags } if not dynamic_tags.is_empty() else {}

func add_tag(tag_id: String) -> void:
	Debug.post("add_tag called for '%s'." % tag_id, "TagComponent on '%s'" % _entity_name)
	if has_tag(tag_id):
		Debug.post("Tag '%s' already exists. Skipping add." % tag_id, "TagComponent on '%s'" % _entity_name)
		return

	if TagRegistry.is_tag_defined(tag_id):
		tags[tag_id] = TagRegistry.get_tag_definition(tag_id)
		Debug.post("Tag '%s' found in registry, added to tags." % tag_id, "TagComponent on '%s'" % _entity_name)
	else:
		tags[tag_id] = {}
		Debug.post("Tag '%s' not found in registry, added as empty tag." % tag_id, "TagComponent on '%s'" % _entity_name)

	Debug.post("Tag '%s' added. Current tags: %s" % [tag_id, str(tags.keys())], "TagComponent on '%s'" % _entity_name)

func _on_day_started(_payload: Dictionary):
	Debug.post("_on_day_started called. Checking for daily tags to remove.", "TagComponent on '%s'" % _entity_name)
	var tags_to_remove = []
	for tag_id in tags:
		if tag_id.begins_with("event_triggered/"):
			tags_to_remove.append(tag_id)

	if not tags_to_remove.is_empty():
		Debug.post("New day. Removing daily tags: %s" % str(tags_to_remove), "TagComponent on '%s'" % _entity_name)
		for tag_id in tags_to_remove:
			if tags.has(tag_id):
				tags.erase(tag_id)
				Debug.post("Removed daily tag '%s'." % tag_id, "TagComponent on '%s'" % _entity_name)

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
