class_name TagComponent
extends Node

# We store the full tag definition dictionary, keyed by the tag's ID string.
var tags: Dictionary = {}

# The factory now passes the fully-resolved tag data directly to this function.
func initialize(resolved_tags_data: Dictionary) -> void:
	tags = resolved_tags_data

func has_tag(tag_id: String) -> bool:
	return tags.has(tag_id)

func get_tag_data(tag_id: String) -> Dictionary:
	return tags.get(tag_id, {}) # Return an empty Dictionary for safety.

func find_first_effect(effect_type: String) -> Dictionary:
	for tag_id in tags:
		var tag_data = tags[tag_id]
		if tag_data.has("effects"):
			for effect in tag_data["effects"]:
				if effect.get("type") == effect_type:
					return effect
	return {} # Return an empty Dictionary for safety.
