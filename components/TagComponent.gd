class_name TagComponent
extends Node

var tags: Array[String] = []

# This function will be called by the EntityFactory to pass in data from the JSON file.
func initialize(data: Dictionary) -> void:
	if data.has("tags") and data["tags"] is Array:
		tags = data["tags"]

func has_tag(tag: String) -> bool:
	return tags.has(tag)
