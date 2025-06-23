class_name TagComponent
extends Node

var tags: Dictionary = {}

func initialize(data: Dictionary) -> void:
	tags.clear()
	
	if data.has("saved_data"):
		# Re-hydrating from a saved state.
		var saved_data = data["saved_data"]
		tags = saved_data.get("tags", {})
		print("TagComponent re-hydrated with tags: %s" % str(tags.keys()))
	elif data.has("tags"):
		# Initializing fresh from a list of tag IDs (dynamic add).
		var tags_to_resolve = data.get("tags", [])
		for tag_id in tags_to_resolve:
			if TagRegistry.is_tag_defined(tag_id):
				tags[tag_id] = TagRegistry.get_tag_definition(tag_id)
			else:
				push_warning("Undefined tag '%s' in dynamic TagComponent." % tag_id)
		print("TagComponent initialized dynamically with tags: %s" % str(tags.keys()))
	else:
		# Initializing fresh from a resolved dictionary (factory creation).
		tags = data
		print("TagComponent initialized fresh with tags: %s" % str(tags.keys()))


func get_persistent_data() -> Dictionary:
	return { "tags": tags }


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
