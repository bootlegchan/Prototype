# script/components/LocationComponent.gd
class_name LocationComponent
extends BaseComponent

# Defines the functional role of a location entity.
var location_type: String = "generic"
var location_name: String = "Unnamed Location"

# This function is called automatically by the parent BaseComponent's initialize method.
func _load_data(data: Dictionary) -> void:
	location_type = data.get("type", "generic")
	location_name = data.get("name", "Unnamed Location")
