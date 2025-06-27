class_name LocationComponent
extends Node

# Defines the functional role of a location entity.
var location_type: String = "generic"
var location_name: String = "Unnamed Location"

func initialize(data: Dictionary) -> void:
	location_type = data.get("type", "generic")
	location_name = data.get("name", "Unnamed Location")
