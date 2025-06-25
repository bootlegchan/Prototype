class_name TagComponent
extends Node

var tags: Dictionary = {}

func initialize(data: Dictionary) -> void:
	tags.clear()
	if data.has("saved_data"):
		tags = data["saved_data"].get("tags", {})
		print("TagComponent re-hydrated with tags: %s" % str(tags.keys()))
	else:
		tags = data
		print("TagComponent initialized fresh with tags: %s" % str(tags.keys()))

func get_persistent_data() -> Dictionary:
	return { "tags": tags }

# --- NEW FUNCTION ---
func add_tag(tag_id: String) -> void:
	if not has_tag(tag_id) and TagRegistry.is_tag_defined(tag_id):
		tags[tag_id] = TagRegistry.get_tag_definition(tag_id)
		print("Dynamically added tag '%s'." % tag_id)

func has_tag(tag_id: String) -> bool:
	return tags.has(tag_id)

func get_tag_data(tag_id: String) -> Dictionary:
	return tags.get(tag_id, {})

func find_first_effect(effect_type: String) -> Dictionary:
	for tag_id in tags:
		var tag_data = tags[tag_id]
		if tag_data.has("effects"):
			for effect in tag_data["effects"]:
				if effect.get("type") == effect_type:
					return effect
	return {}
