class_name TagComponent
extends Node

var tags: Array[String] = []

# This function will be called by the EntityFactory to pass in data from the JSON file.
func initialize(data: Dictionary) -> void:
	if data.has("tags") and data["tags"] is Array:
		# Clear any existing tags before initializing.
		tags.clear()
		# Loop through the generic array from the JSON data.
		for item in data["tags"]:
			# Ensure the item is a string before adding it. This prevents crashes if the JSON is malformed.
			if item is String:
				tags.append(item)
			else:
				push_warning("Non-string value found in 'tags' for entity. Value: %s" % str(item))

func has_tag(tag: String) -> bool:
	return tags.has(tag)
